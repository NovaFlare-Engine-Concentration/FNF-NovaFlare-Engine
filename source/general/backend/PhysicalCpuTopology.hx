package general.backend;

#if cpp
@:cppFileCode('
#if defined(_WIN32)
#include <windows.h>
#include <vector>
#elif defined(__linux__)
#include <cerrno>
#include <fstream>
#include <limits>
#include <memory>
#include <sched.h>
#include <set>
#include <sstream>
#include <string>
#elif defined(__APPLE__)
#include <sys/sysctl.h>
#endif

namespace {
#if defined(_WIN32)
int physicalCoreCount() {
    DWORD bytes = 0;
    GetLogicalProcessorInformationEx(RelationProcessorCore, nullptr, &bytes);
    if (bytes == 0) return 0;

    std::vector<unsigned char> buffer(bytes);
    auto topology = reinterpret_cast<PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX>(buffer.data());
    if (!GetLogicalProcessorInformationEx(RelationProcessorCore, topology, &bytes)) return 0;

    int cores = 0;
    for (DWORD offset = 0; offset < bytes;) {
        auto core = reinterpret_cast<PSYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX>(buffer.data() + offset);
        if (core->Relationship != RelationProcessorCore || core->Size == 0 || core->Size > bytes - offset) return 0;
        ++cores;
        offset += core->Size;
    }
    return cores;
}
#elif defined(__linux__)
std::string coreSiblings(int cpu) {
    const auto directory = "/sys/devices/system/cpu/cpu" + std::to_string(cpu) + "/topology/";
    std::string siblings;
    std::ifstream current(directory + "core_cpus_list");
    if (current >> siblings) return siblings;

    std::ifstream legacy(directory + "thread_siblings_list");
    if (legacy >> siblings) return siblings;
    return {};
}

bool addCore(std::set<std::string>& cores, int cpu) {
    const auto siblings = coreSiblings(cpu);
    if (siblings.empty()) return false;
    cores.insert(siblings);
    return true;
}

int countPresentCores(const std::string& cpuList) {
    std::istringstream list(cpuList);
    std::set<std::string> cores;
    int cpu;
    while (list >> cpu) {
        if (cpu < 0) return 0;
        int last = cpu;
        if (list.peek() == \'-\') {
            list.get();
            if (!(list >> last) || last < cpu) return 0;
        }
        for (;;) {
            if (!addCore(cores, cpu)) return 0;
            if (cpu == last) break;
            ++cpu;
        }
        if (list.eof()) return static_cast<int>(cores.size());
        if (list.get() != \',\') return 0;
    }
    return 0;
}

int countAvailableCores(const cpu_set_t* mask, int capacity, size_t bytes) {
    std::set<std::string> cores;
    for (int cpu = 0; cpu < capacity; ++cpu) {
        if (CPU_ISSET_S(cpu, bytes, mask) && !addCore(cores, cpu)) return 0;
    }
    return static_cast<int>(cores.size());
}

int countAffinityCores() {
    const auto freeMask = [](cpu_set_t* mask) { CPU_FREE(mask); };
    for (int capacity = CPU_SETSIZE; capacity <= std::numeric_limits<int>::max() / 2; capacity *= 2) {
        std::unique_ptr<cpu_set_t, decltype(freeMask)> mask(CPU_ALLOC(capacity), freeMask);
        if (!mask) return 0;
        const auto bytes = CPU_ALLOC_SIZE(capacity);
        CPU_ZERO_S(bytes, mask.get());
        if (sched_getaffinity(0, bytes, mask.get()) == 0) return countAvailableCores(mask.get(), capacity, bytes);
        if (errno != EINVAL) return 0;
    }
    return 0;
}

int physicalCoreCount() {
    // Thread affinity can shrink when an Android window loses focus.
    std::ifstream present("/sys/devices/system/cpu/present");
    std::string cpuList;
    if (present >> cpuList) {
        const int cores = countPresentCores(cpuList);
        if (cores > 0) return cores;
    }
    return countAffinityCores();
}
#elif defined(__APPLE__)
int physicalCoreCount() {
    int cores = 0;
    size_t bytes = sizeof(cores);
    return sysctlbyname("hw.physicalcpu", &cores, &bytes, nullptr, 0) == 0 && bytes == sizeof(cores) ? cores : 0;
}
#else
int physicalCoreCount() { return 0; }
#endif
}
')
#end
class PhysicalCpuTopology {
	#if cpp
	@:functionCode('return physicalCoreCount();')
	#end
	public static function coreCount():Int {
		return 0;
	}
}
