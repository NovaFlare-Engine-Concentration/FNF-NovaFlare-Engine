import struct
import sys
from pathlib import Path, PurePosixPath
from zipfile import ZIP_STORED, ZipFile


PAGE_SIZE = 16 * 1024
ELF64_ABIS = {"arm64-v8a": 183, "x86_64": 62}
PT_LOAD = 1
PT_GNU_RELRO = 0x6474E552
PF_W = 2


def check_load_segments(entry, expected_machine):
    header = entry.read(64)
    if not header.startswith(b"\x7fELF\x02\x01"):
        raise ValueError("expected a little-endian 64-bit ELF")
    machine, = struct.unpack_from("<H", header, 18)
    if machine != expected_machine:
        raise ValueError(f"ELF machine {machine} does not match the APK ABI")
    table_offset, = struct.unpack_from("<Q", header, 32)
    entry_size, entry_count = struct.unpack_from("<HH", header, 54)
    if entry_size != 56:
        raise ValueError("unexpected ELF program header size")
    entry.seek(table_offset)
    load_segments = 0
    writable_ranges = []
    relro_ends = []
    for index in range(entry_count):
        segment_type, flags, offset, address, _, _, size, alignment = struct.unpack("<II6Q", entry.read(entry_size))
        if segment_type == PT_LOAD:
            load_segments += 1
            if alignment < PAGE_SIZE or (offset - address) % PAGE_SIZE:
                raise ValueError(f"PT_LOAD #{index} has offset {offset:#x}, address {address:#x}, alignment {alignment:#x}")
            if flags & PF_W and size:
                writable_ranges.append((address, address + size))
        if segment_type == PT_GNU_RELRO:
            relro_ends.append(address + size)
    if not load_segments:
        raise ValueError("ELF has no PT_LOAD segments")
    for end in relro_ends:
        trailing_bytes = -end % PAGE_SIZE
        if trailing_bytes and any(start < end + trailing_bytes and stop > end for start, stop in writable_ranges):
            raise ValueError(f"GNU_RELRO ends at {end:#x} and shares its trailing 16 KB page with writable data")


def check_apk(path):
    errors = []
    checked = 0
    with path.open("rb") as raw, ZipFile(raw) as apk:
        for member in apk.infolist():
            parts = PurePosixPath(member.filename).parts
            if len(parts) != 3 or parts[0] != "lib" or not parts[2].endswith(".so"):
                continue
            machine = ELF64_ABIS.get(parts[1])
            if machine is not None:
                checked += 1
            try:
                if member.compress_type == ZIP_STORED:
                    # Stored libraries are mapped directly from the local ZIP entry.
                    raw.seek(member.header_offset + 26)
                    name_size, extra_size = struct.unpack("<HH", raw.read(4))
                    data_offset = member.header_offset + 30 + name_size + extra_size
                    if data_offset % PAGE_SIZE:
                        raise ValueError(f"uncompressed ZIP entry starts at {data_offset:#x}")
                if machine is not None:
                    with apk.open(member) as library:
                        check_load_segments(library, machine)
            except (struct.error, ValueError) as error:
                errors.append(f"{path}: {member.filename}: {error}")
    if not checked:
        errors.append(f"{path}: no 64-bit Android native libraries were found")
    if not errors:
        print(f"{path}: checked {checked} 64-bit native libraries for 16 KB alignment")
    return errors


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("usage: check-android-16k.py APK [APK ...]")
    failures = [error for argument in sys.argv[1:] for error in check_apk(Path(argument))]
    if failures:
        raise SystemExit("\n".join(failures))
