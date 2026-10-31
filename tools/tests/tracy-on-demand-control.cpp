// Models a hxcpp automatic C zone containing a generated C++ scoped zone.
// Connect the collector while the first scope is held across startup.
#include <windows.h>
#include <cstring>
#include "tracy/Tracy.hpp"
#include "tracy/TracyC.h"

__declspec(noinline) void sample(int depth, bool hold)
{
    const char* file = __FILE__;
    const char* function = "demand consistency parent";
    auto source = ___tracy_alloc_srcloc(10 + depth, file, strlen(file), function, strlen(function), 0);
    auto context = ___tracy_emit_zone_begin_alloc(source, true);
    {
        const char* name = "demand consistency scoped child";
        tracy::ScopedZone child(20 + depth, file, strlen(file), function, strlen(function), name, strlen(name), -1);
        if (hold) Sleep(1500);
        if (depth > 0) sample(depth - 1, false);
    }
    ___tracy_emit_zone_end(context);
}

int main()
{
    tracy::SetThreadName("demand-consistency-control");
    sample(4, true);
    for (int frame = 0; frame < 160; ++frame)
    {
        for (int event = 0; event < 5; ++event) sample(4, false);
        FrameMark;
        Sleep(16);
    }
    // Both variants end after the collector's three-second window. A failed
    // on-demand connection can leave Tracy teardown waiting in the deliberately
    // mismatched variant; this control tests trace integrity, not shutdown.
    ExitProcess(0);
}
