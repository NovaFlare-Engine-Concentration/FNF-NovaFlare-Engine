import argparse
import csv
import json
import re
from bisect import bisect_right
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timedelta
from math import isfinite
from pathlib import Path


@dataclass(frozen=True, slots=True)
class Event:
    frame: int
    begin: int
    end: int
    value: int
    auxiliary: int
    detail: str
    batch: int
    phase: str


@dataclass(frozen=True, slots=True)
class GapWindow:
    start_qpc: int
    end_qpc: int
    frequency: int
    threshold_ms: float


SETTINGS = ("update_period_ns", "render_period_ns", "split_render", "swap_interval", "gpu_support",
            "window_size", "drawable_size", "display_dpi_milli")
DURATIONS = (
    "update", "render_update", "render_commands", "render_dispatch", "gl_sync", "update_gl_sync",
    "queue", "driver_batch", "sdl_gl_swap", "pool_wait", "submit_wait",
)
LIMITS_MS = (8.33, 16.67, 33.3, 50, 100)
PRESENTMON_TAIL_TOLERANCE_MS = 100


def load_events(path):
    phases = defaultdict(list)
    with path.open(newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream)
        fields = {"event", "frame", "begin_qpc", "end_qpc", "value", "auxiliary", "detail", "batch", "phase"}
        if not fields.issubset(reader.fieldnames or ()):
            raise ValueError(f"Frame timeline uses the wrong schema in {path}")
        for row in reader:
            if any(value is None for value in row.values()):
                # A killed process may leave one incomplete final row.
                continue
            phases[row["event"]].append(Event(
                int(row["frame"]), int(row["begin_qpc"]), int(row["end_qpc"]),
                int(row["value"]), int(row["auxiliary"]), row["detail"],
                int(row["batch"]), row["phase"],
            ))
    for events in phases.values():
        events.sort(key=lambda event: (event.begin, event.end))
    return phases


def load_gc(path, qpc_frequency):
    if not path.is_file():
        raise ValueError(f"Missing Immix pause timeline in {path}")
    intervals = []
    with path.open(newline="", encoding="utf-8-sig") as stream:
        for row in csv.DictReader(stream):
            if int(row["qpc_frequency"]) != qpc_frequency:
                raise ValueError(f"GC and frame QPC frequencies differ in {path.parent}")
            intervals.append((int(row["begin_qpc"]), int(row["end_qpc"])))
    return sorted(intervals)


def percentiles(values):
    values = sorted(values)
    if not values:
        return {"count": 0}
    summary = {"count": len(values)}
    for label, proportion in (("p50", .5), ("p95", .95), ("p99", .99)):
        position = (len(values) - 1) * proportion
        lower = int(position)
        upper = min(lower + 1, len(values) - 1)
        summary[label] = round(values[lower] + (values[upper] - values[lower]) * (position - lower), 4)
    summary["max"] = round(values[-1], 4)
    return summary


class IntervalIndex:
    def __init__(self, intervals):
        self.intervals = sorted(intervals)
        self.maximum_ends = []
        maximum = 0
        for _, end in self.intervals:
            maximum = max(maximum, end)
            self.maximum_ends.append(maximum)

    def clipped_time(self, begin, end):
        first = bisect_right(self.maximum_ends, begin)
        total = 0
        included_until = begin
        for index in range(first, len(self.intervals)):
            start, stop = self.intervals[index]
            if start >= end:
                break
            left = max(start, included_until)
            right = min(stop, end)
            if right > left:
                total += right - left
                included_until = right
        return total


def phase_overlaps(scans, begin, end, ticks_ms):
    # Phases can run concurrently, so their overlaps must not be added together.
    overlaps = {}
    for name, index in scans.items():
        overlap = index.clipped_time(begin, end)
        if overlap:
            overlaps[name] = round(overlap / ticks_ms, 4)
    return overlaps


def long_update_gaps(updates, scans, window):
    ticks_ms = window.frequency / 1000
    in_window = [event for event in updates if window.start_qpc <= event.begin <= window.end_qpc]
    gaps = []
    for previous, current in zip(in_window, in_window[1:]):
        duration = (current.begin - previous.begin) / ticks_ms
        if duration <= window.threshold_ms:
            continue
        overlaps = phase_overlaps(scans, previous.begin, current.begin, ticks_ms)
        gaps.append({
            "from_frame": previous.frame, "to_frame": current.frame,
            "begin_qpc": previous.begin, "end_qpc": current.begin,
            "seconds_since_song_start": round((current.begin - window.start_qpc) / window.frequency, 4),
            "update_start_gap_ms": round(duration, 4),
            "overlaps_recorded_gc": "immix_pause" in overlaps,
            "phase_overlap_ms": overlaps,
        })
    return gaps


def focus_in_window(events, start, end):
    initial = next((bool(event.value) for event in reversed(events) if event.begin <= start), None)
    losses = [event.begin for event in events if start < event.begin <= end and not event.value]
    return {"focused_at_start": initial, "focus_losses_qpc": losses}


def cadence(events, timestamp, start, end, ticks_ms):
    timestamps = sorted(timestamp(event) for event in events if start <= timestamp(event) <= end)
    gaps = [(later - earlier) / ticks_ms for earlier, later in zip(timestamps, timestamps[1:])]
    return {
        "events": len(timestamps),
        "interval_ms": percentiles(gaps),
        "above_ms": {str(limit): sum(gap > limit for gap in gaps) for limit in LIMITS_MS},
        "first_qpc": timestamps[0] if timestamps else None,
        "last_qpc": timestamps[-1] if timestamps else None,
    }


def worker_batches(phases, start, end, ticks_ms):
    queue = {event.batch: event for event in phases["queue"] if event.batch}
    drivers = {event.batch: event for event in phases["driver_batch"] if event.batch}
    synchronous = {event.batch: event for name in ("update_gl_sync", "gl_sync")
                   for event in phases[name] if event.batch}
    metrics = defaultdict(lambda: defaultdict(list))
    for batch, submitted in queue.items():
        if not start <= submitted.begin <= end:
            continue
        phase = metrics[submitted.phase]
        phase["queue_ms"].append((submitted.end - submitted.begin) / ticks_ms)
        phase["depth"].append(submitted.value)
        if driver := drivers.get(batch):
            phase["driver_ms"].append((driver.end - driver.begin) / ticks_ms)
        if sync := synchronous.get(batch):
            phase["sync_wait_ms"].append((sync.end - sync.begin) / ticks_ms)
    return {name: {metric: percentiles(values) for metric, values in phase.items()}
            for name, phase in metrics.items()}


def frame_id_coverage(frames):
    return {
        "ids": len(frames),
        "internal_missing_ids": max(frames) - min(frames) + 1 - len(frames) if frames else 0,
    }


def frame_pairing(source, in_window, all_records):
    return {
        "matched_in_window": len(source & in_window),
        "matched_outside_window": len((source & all_records) - in_window),
        "missing_from_trace": len(source - all_records),
    }


def frame_coverage(phases, swapped, start, end):
    updates = {event.frame for event in phases["update"] if start <= event.begin <= end}
    draws = {event.frame for event in phases["render_dispatch"] if start <= event.begin <= end}
    gpu = {event.frame for event in phases["gpu_elapsed"] if start <= event.begin <= end}
    return {
        "update": frame_id_coverage(updates),
        "draw_dispatch": frame_id_coverage(draws),
        "swap_return": frame_id_coverage(swapped),
        "draw_to_swap": frame_pairing(draws, swapped, {event.frame for event in phases["sdl_gl_swap"]}),
        "swap_to_draw": frame_pairing(swapped, draws, {event.frame for event in phases["render_dispatch"]}),
        "swap_to_gpu": frame_pairing(swapped, gpu, {event.frame for event in phases["gpu_elapsed"]}),
        "gpu_query_backlog": sum(start <= event.begin <= end for event in phases["gpu_query_backlog"]),
    }


def presentmon_number(text):
    try:
        value = float(text)
    except ValueError:
        return None
    return value if isfinite(value) and value >= 0 else None


def presentmon_mode():
    return {
        "present_submissions_in_window": 0,
        "dropped_submissions": 0,
        "unknown_drop_flag": 0,
        "missing_display_timestamp": 0,
        "zero_display_latency": 0,
        "display_after_window": 0,
        "display_changes_in_window": 0,
        "first_display_qpc": None,
        "last_display_qpc": None,
        "missing_display_interval": 0,
        "interval_crosses_window_start": 0,
        "display_intervals_ms": [],
    }


def count_presentmon_row(row, modes, present_qpc, start, end, ticks_ms):
    submitted = start <= present_qpc <= end
    displayed = presentmon_number(row["msUntilDisplayed"]) if row["Dropped"] == "0" else None
    # V1 uses zero when it has not resolved a display timestamp.
    display_qpc = present_qpc + round(displayed * ticks_ms) if displayed else None
    in_window = display_qpc is not None and start <= display_qpc <= end
    if not submitted and not in_window:
        return

    mode = modes[row["SwapChainAddress"]][row["PresentMode"] or "unknown"]
    if submitted:
        mode["present_submissions_in_window"] += 1
        if row["Dropped"] == "1":
            mode["dropped_submissions"] += 1
        elif row["Dropped"] != "0":
            mode["unknown_drop_flag"] += 1
        elif display_qpc is None:
            mode["missing_display_timestamp"] += 1
            if displayed == 0:
                mode["zero_display_latency"] += 1
        elif display_qpc > end:
            mode["display_after_window"] += 1
    if not in_window:
        return

    mode["display_changes_in_window"] += 1
    mode["first_display_qpc"] = min(display_qpc, mode["first_display_qpc"] or display_qpc)
    mode["last_display_qpc"] = max(display_qpc, mode["last_display_qpc"] or display_qpc)
    interval = presentmon_number(row["msBetweenDisplayChange"])
    if not interval:
        mode["missing_display_interval"] += 1
    elif display_qpc - round(interval * ticks_ms) < start:
        mode["interval_crosses_window_start"] += 1
    else:
        mode["display_intervals_ms"].append(interval)


def presentmon_reported_losses(path):
    text = path.read_text(encoding="utf-8-sig", errors="replace") if path.is_file() else ""
    return {
        field: max(map(int, re.findall(pattern, text)), default=None)
        for field, pattern in {
            "etw_lost_events": r"warning: (\d+) ETW events were lost\.",
            "etw_lost_buffers": r"warning: (\d+) ETW buffers were lost\.",
            "overflowed_present_events": r"warning: (\d+) overflowed present events detected\.",
        }.items()
    }


def validate_presentmon_coverage(result, displayed_count, start, end, ticks_ms, reported_losses):
    if not displayed_count:
        result["reason"] = "no complete display intervals in the requested window"
        return

    first, last = result["first_target_qpc"], result["last_target_qpc"]
    tail_boundary = end - round(PRESENTMON_TAIL_TOLERANCE_MS * ticks_ms)
    problems = []
    if first > start:
        problems.append("first target present follows the capture start")
    if last < tail_boundary:
        problems.append("last target present precedes the capture end by over 100 ms")
    if result["malformed_rows"] > result["malformed_tail_rows"]:
        problems.append("malformed PresentMon rows within the trace")
    if result["malformed_tail_rows"] and last < end:
        problems.append("malformed tail without a target present at or beyond the capture end")
    if any(count for count in reported_losses.values()):
        problems.append("PresentMon reported ETW loss or present overflow")
    result["status"] = "incomplete" if problems else "captured"
    if problems:
        result["coverage_issues"] = problems


def summarize_presentmon(path, pid, start, end, ticks_ms):
    reported_losses = presentmon_reported_losses(path.with_name("presentmon.stderr.log"))
    result = {
        "status": "unavailable", "source": "Windows ETW via PresentMon v1 metrics", "process_id": pid,
        **reported_losses,
        "malformed_rows": 0, "malformed_tail_rows": 0, "tail_tolerance_ms": PRESENTMON_TAIL_TOLERANCE_MS,
        "other_pid_rows": 0, "target_pid_rows": 0,
        "first_target_qpc": None, "last_target_qpc": None, "swapchains": {},
    }
    if not path.is_file():
        return dict(result, reason="missing presentmon.csv")

    required = {"ProcessID", "QPCTime", "SwapChainAddress", "PresentMode", "Dropped",
                "msUntilDisplayed", "msBetweenDisplayChange"}
    modes = defaultdict(lambda: defaultdict(presentmon_mode))
    with path.open(newline="", encoding="utf-8-sig") as stream:
        columns = next(csv.reader(stream), [])
        if not required.issubset(columns):
            return dict(result, reason="missing PresentMon v1 QPC columns")
        for line in stream:
            try:
                fields = next(csv.reader([line], strict=True))
                if len(fields) != len(columns) or not line.endswith("\n"):
                    raise ValueError("incomplete PresentMon row")
                row = dict(zip(columns, fields))
                process_id, present_qpc = int(row["ProcessID"]), int(row["QPCTime"])
                if process_id <= 0 or present_qpc <= 0 or not row["SwapChainAddress"]:
                    raise ValueError("missing PresentMon event identity")
            except (ValueError, csv.Error):
                result["malformed_rows"] += 1
                result["malformed_tail_rows"] += 1
                continue
            result["malformed_tail_rows"] = 0
            if process_id != pid:
                result["other_pid_rows"] += 1
                continue
            result["target_pid_rows"] += 1
            result["first_target_qpc"] = min(present_qpc, result["first_target_qpc"] or present_qpc)
            result["last_target_qpc"] = max(present_qpc, result["last_target_qpc"] or present_qpc)
            count_presentmon_row(row, modes, present_qpc, start, end, ticks_ms)

    count = 0
    for chain, present_modes in modes.items():
        result["swapchains"][chain] = dict(present_modes)
        for mode in present_modes.values():
            intervals = mode["display_intervals_ms"]
            count += len(intervals)
            mode["display_intervals_ms"] = dict(percentiles(intervals), above_33_3=sum(value > 33.3 for value in intervals))
    validate_presentmon_coverage(result, count, start, end, ticks_ms, reported_losses)
    return result


def validate_window(capture, phases, gc):
    start = capture["song_start_qpc"]
    finish = capture["song_finish_qpc"]
    end = capture["capture_end_qpc"]
    if not finish or not start < finish <= end:
        raise ValueError("Capture did not include the full song")
    if not capture["close_requested_qpc"] or capture["close_requested_qpc"] < end:
        raise ValueError("Process closed before the exact capture boundary")
    if not any(capture["launch_qpc"] <= left <= start for left, _ in gc):
        raise ValueError("Immix pause timeline has no startup pauses")
    updates = phases["update"]
    if not updates or updates[0].begin > start or max(event.end for event in updates) < finish:
        raise ValueError("The update timeline does not span the song")
    if not any(start <= event.end <= finish for event in phases["sdl_gl_swap"]):
        raise ValueError("No SDL swap completed during the song")
    if capture.get("require_sdl_geometry"):
        for name in ("window_size", "drawable_size"):
            if not any(event.begin <= start and event.value > 0 and event.auxiliary > 0
                       for event in phases[name]):
                raise ValueError(f"Missing initial SDL {name} record")


def parse_utc(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def resource_peak_values(path, fields, begin, end):
    peaks = dict.fromkeys(fields)
    if not path.is_file():
        return peaks
    with path.open(newline="", encoding="utf-8-sig") as stream:
        for row in csv.DictReader(stream):
            if not row.get("utc") or not begin <= parse_utc(row["utc"]) <= end:
                continue
            for field, quality in fields.items():
                if not row.get(field) or (quality and not int(row.get(quality) or 0)):
                    continue
                value = float(row[field])
                peaks[field] = value if peaks[field] is None else max(peaks[field], value)
    return peaks


def resource_peaks(run, capture, start, end):
    if not capture.get("launch_utc"):
        return None
    launch = parse_utc(capture["launch_utc"])
    tick_rate = capture["qpc_frequency"]
    begin = launch + timedelta(seconds=(start - capture["launch_qpc"]) / tick_rate)
    finish = launch + timedelta(seconds=(end - capture["launch_qpc"]) / tick_rate)
    groups = {
        "process": dict.fromkeys(("cpu_percent", "private_mb", "working_set_mb", "threads")),
        "hardware": {
            "cpu_frequency_mhz": None,
            "gpu_total_percent": "gpu_engine_counter_samples",
            "gpu_3d_percent": "gpu_engine_counter_samples",
            "gpu_dedicated_mb": "gpu_memory_counter_samples",
        },
    }
    return {group: resource_peak_values(run / f"{group}-samples.csv", fields, begin, finish)
            for group, fields in groups.items()}


def summarize(run, song_only, long_gap_ms):
    capture = json.loads((run / "capture.json").read_text(encoding="utf-8-sig"))
    if capture["status"] not in ("captured", "validation_pending") or not capture["song_start_qpc"]:
        raise ValueError(f"Incomplete capture in {run}")
    start = capture["song_start_qpc"]
    end = capture["capture_end_qpc"]
    if song_only:
        if not capture["song_finish_qpc"]:
            raise ValueError(f"Missing song finish in {run}")
        end = min(end, capture["song_finish_qpc"])

    phases = load_events(run / "frame-timeline.csv")
    if len(phases["clock"]) != 1:
        raise ValueError(f"Missing or repeated clock record in {run}")
    if phases["trace_writer"] or phases["trace_end"]:
        end_events = phases["trace_end"]
        if len(phases["trace_writer"]) != 1 or len(end_events) != 1:
            raise ValueError(f"Missing or repeated asynchronous trace status in {run}")
        if end_events[0].end < capture["capture_end_qpc"]:
            raise ValueError(f"Asynchronous frame trace ended before the capture boundary in {run}")
        if end_events[0].value or end_events[0].auxiliary:
            raise ValueError(f"Lost frame trace chunks or disk writes failed in {run}")
    frequency = phases["clock"][0].value
    if frequency != capture["qpc_frequency"]:
        raise ValueError(f"Runner and frame QPC frequencies differ in {run}")
    ticks_ms = frequency / 1000
    gc = load_gc(run / "gc-pauses-qpc.csv", frequency)
    validate_window(capture, phases, gc)

    swaps = sorted((event for event in phases["sdl_gl_swap"] if start <= event.end <= end), key=lambda event: event.end)
    swapped_frames = {event.frame for event in swaps}
    if not swaps:
        raise ValueError(f"No SDL swap detail in {run}")

    scans = {name: IntervalIndex((event.begin, event.end) for event in phases[name]) for name in DURATIONS}
    scans["immix_pause"] = IntervalIndex(gc)

    slow_frames = []
    for previous, current in zip(swaps, swaps[1:]):
        duration = (current.end - previous.end) / ticks_ms
        if duration <= long_gap_ms:
            continue
        slow_frames.append({
            "from_frame": previous.frame, "to_frame": current.frame, "end_qpc": current.end,
            "seconds_since_song_start": round((current.end - start) / frequency, 4),
            "swap_completion_gap_ms": round(duration, 4),
            "phase_overlap_ms": phase_overlaps(scans, previous.end, current.end, ticks_ms),
        })

    report = {
        "capture": str(run),
        "start_qpc": start,
        "end_qpc": end,
        "capture_end_qpc": capture["capture_end_qpc"],
        "qpc_frequency": frequency,
        "focus": focus_in_window(phases["window_focus"], start, end),
        "coverage": frame_coverage(phases, swapped_frames, start, end),
        "settings": {name: [{"qpc": event.begin, "value": event.value,
                               "auxiliary": event.auxiliary, "detail": event.detail}
                              for event in phases[name] if event.begin <= end] for name in SETTINGS},
        "update_cadence": cadence(phases["update"], lambda event: event.begin, start, end, ticks_ms),
        "draw_dispatch_cadence": cadence(phases["render_dispatch"], lambda event: event.begin, start, end, ticks_ms),
        "sdl_swap_call_cadence": cadence(phases["sdl_gl_swap"], lambda event: event.begin, start, end, ticks_ms),
        "sdl_swap_return_cadence": cadence(swaps, lambda event: event.end, start, end, ticks_ms),
        "post_song_tail": {
            "updates": cadence(phases["update"], lambda event: event.begin, capture["song_finish_qpc"],
                               capture["capture_end_qpc"], ticks_ms),
            "sdl_swap_returns": cadence(phases["sdl_gl_swap"], lambda event: event.end, capture["song_finish_qpc"],
                                        capture["capture_end_qpc"], ticks_ms),
        },
        "phase_ms": {name: percentiles((event.end - event.begin) / ticks_ms for event in phases[name]
                                      if event.begin >= start and event.end <= end) for name in DURATIONS},
        "queue_depth": percentiles(event.value for event in phases["queue"] if start <= event.begin <= end),
        "worker_batches": worker_batches(phases, start, end, ticks_ms),
        "queue_full_ticks": sum(start <= event.begin <= end for event in phases["queue_full"]),
        "gpu_ms": percentiles(event.value / 1_000_000 for event in phases["gpu_elapsed"] if event.frame in swapped_frames),
        "immix_pause_ms": percentiles((stop - begin) / ticks_ms for begin, stop in gc
                                     if begin >= start and stop <= end),
        "long_swap_gaps": slow_frames,
        "long_update_gaps": long_update_gaps(phases["update"], scans, GapWindow(start, end, frequency, long_gap_ms)),
        "win32_window_at_song_start": capture.get("win32_window_at_song_start"),
        "resource_peaks": resource_peaks(run, capture, start, end),
    }
    if capture.get("presentmon"):
        report["presentmon"] = summarize_presentmon(run / "presentmon.csv", capture["process_id"], start, end, ticks_ms)
    return report


def main():
    parser = argparse.ArgumentParser(description="Summarize the Windows gameplay frame timeline and Immix pauses.")
    parser.add_argument("run_directory", type=Path)
    parser.add_argument("--song-only", action="store_true")
    parser.add_argument("--long-gap-ms", type=float, default=50)
    args = parser.parse_args()
    try:
        report = summarize(args.run_directory, args.song_only, args.long_gap_ms)
    except (OSError, ValueError, KeyError) as error:
        parser.exit(1, f"{error}\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
