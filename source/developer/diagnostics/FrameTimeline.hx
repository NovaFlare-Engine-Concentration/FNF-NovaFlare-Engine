package developer.diagnostics;

#if (windows && cpp)
@:cppFileCode('
#include <windows.h>
#include <cstdio>

static void novaFlareMarkSongBoundary(bool ended) {
    LARGE_INTEGER counter;
    if (QueryPerformanceCounter(&counter)) {
        std::printf("perf:song_%s_qpc=%llu\\n", ended ? "finish" : "start",
            static_cast<unsigned long long>(counter.QuadPart));
        std::fflush(stdout);
    }
}
')
#elseif (android && cpp)
@:cppFileCode('
#include <android/log.h>
#include <time.h>

static void novaFlareMarkSongBoundary(bool ended) {
    timespec counter;
    if (clock_gettime(CLOCK_MONOTONIC, &counter) == 0) {
        const long long nanoseconds = static_cast<long long>(counter.tv_sec) * 1000000000 + counter.tv_nsec;
        __android_log_print(ANDROID_LOG_INFO, "NovaFlareTimeline", "song_%s_ns=%lld",
            ended ? "finish" : "start", nanoseconds);
    }
}
')
#end
class FrameTimeline
{
	#if (windows && cpp && novaflare_transition_trace)
	static final transitionTraceEnabled = Sys.getEnv('NOVAFLARE_FRAME_TIMELINE') != null;

	static function transitionQpc():cpp.Int64
	{
		untyped __cpp__('LARGE_INTEGER counter');
		return untyped __cpp__('QueryPerformanceCounter(&counter) ? counter.QuadPart : 0');
	}

	public static function beginTransitionPhase():cpp.Int64
	{
		return transitionTraceEnabled ? transitionQpc() : 0;
	}

	public static function endTransitionPhase(phase:String, begin:cpp.Int64):Void
	{
		if (begin == (0:cpp.Int64)) return;
		var end = transitionQpc();
		if (end == (0:cpp.Int64)) return;
		untyped __cpp__('std::printf("perf:transition_phase phase=%s begin_qpc=%llu end_qpc=%llu\\n", {0}.utf8_str(),
			static_cast<unsigned long long>({1}), static_cast<unsigned long long>({2}))', phase, begin, end);
	}

	public static function traceSongEndCallback(callback:Void->Void):Void
	{
		var begin = beginTransitionPhase();
		callback();
		endTransitionPhase('end_callback', begin);
		if (begin != (0:cpp.Int64)) untyped __cpp__('std::fflush(stdout)');
	}
	#end

	public static function markSongBoundary(ended:Bool):Void
	{
		#if (windows && cpp)
		if (Sys.getEnv('NOVAFLARE_FRAME_TIMELINE') != null)
			untyped __cpp__('novaFlareMarkSongBoundary({0})', ended);
		#elseif (android && cpp)
		if (Sys.getEnv('NOVAFLARE_ANDROID_DIAGNOSTICS') == '1')
			untyped __cpp__('novaFlareMarkSongBoundary({0})', ended);
		#end
	}
}
