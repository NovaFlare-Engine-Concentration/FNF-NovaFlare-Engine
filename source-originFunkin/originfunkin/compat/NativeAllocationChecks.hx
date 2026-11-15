package originfunkin.compat;

#if (cpp && FEATURE_DEBUG_FUNCTIONS)
@:cppFileCode('
#include <thread>
#include <atomic>
#include <sstream>
#include <cstring>
#include <hx/Native.h>

namespace origin_allocation_probe {
struct DirtyObject : ::hx::Object {
  unsigned long long first, second, third;
  DirtyObject() : first(0x1111111122222222ULL), second(0x3333333344444444ULL), third(0x5555555566666666ULL) {}
};
}
')
class NativeAllocationChecks
{
  @:functionCode('
    unsigned long long nonzero = 0, checked = 0, firstBits = 0;
    std::atomic<int> phase(0);
    std::thread worker([&]() {
      for (int batch = 0; batch < 256; ++batch) {
        {
          ::hx::NativeAttach attached;
          for (int index = 0; index < 4096; ++index) {
            if ((index & 1) == 0) {
              auto *dirty = new origin_allocation_probe::DirtyObject();
              ::hx::GCAddRoot(reinterpret_cast<::hx::Object **>(&dirty));
              ::hx::GCRemoveRoot(reinterpret_cast<::hx::Object **>(&dirty));
            } else {
              auto *array = new ::cpp::VirtualArray_obj(::hx::arrayEmpty);
              unsigned long long bits = 0;
              std::memcpy(&bits, &array->base, sizeof(array->base));
              array->base = nullptr;
              ++checked;
              if (bits != 0) {
                if (nonzero == 0) firstBits = bits;
                ++nonzero;
              }
            }
          }
        }
        phase.store(1);
        while (phase.load() != 0) std::this_thread::yield();
      }
    });
    for (int batch = 0; batch < 256; ++batch) {
      ::hx::EnterGCFreeZone();
      while (phase.load() != 1) std::this_thread::yield();
      ::hx::ExitGCFreeZone();
      // Collect while the callback allocator is pooled, then attach it again.
      if ((batch & 7) == 7) ::hx::InternalCollect((batch & 31) == 31, false);
      phase.store(0);
    }
    ::hx::EnterGCFreeZone();
    worker.join();
    ::hx::ExitGCFreeZone();
    std::ostringstream report;
    report << "checked=" << checked << " nonzero=" << nonzero << " first=0x" << std::hex << firstBits;
    return ::String(report.str().c_str());
  ')
  static function probe():String return '';

  public static function run():Void
  {
    trace('[Origin native allocation check] Starting native attach, reuse and collection probe');
    var result = probe();
    trace('[Origin native allocation check] $result');
    if (result.indexOf('nonzero=0 ') < 0)
    {
      trace('[Origin native allocation check] FAIL: uncleared VirtualArray base pointers');
      Sys.exit(1);
    }
    trace('[Origin native allocation check] PASS');
    Sys.exit(0);
  }
}
#end
