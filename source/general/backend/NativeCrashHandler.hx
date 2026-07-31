package general.backend;

#if (cpp && (windows || android))
import haxe.io.Path;
import sys.FileSystem;

@:buildXml('
<target id="haxe">
	<lib name="dbghelp.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

static char novaflare_native_commit[128] = "unknown";
static char novaflare_native_crash_directory[4096] = "crash";
static char novaflare_native_report_buffer[65536];

struct NovaFlareNativeBuffer {
	char* data;
	size_t length;
	size_t capacity;
};

static void novaflare_buffer_char(NovaFlareNativeBuffer* buffer, char value) {
	if (buffer->length + 1 < buffer->capacity) {
		buffer->data[buffer->length++] = value;
		buffer->data[buffer->length] = 0;
	}
}

static void novaflare_buffer_text(NovaFlareNativeBuffer* buffer, const char* value) {
	if (value == 0) return;
	while (*value != 0 && buffer->length + 1 < buffer->capacity) {
		buffer->data[buffer->length++] = *value++;
	}
	buffer->data[buffer->length] = 0;
}

static void novaflare_buffer_u64(NovaFlareNativeBuffer* buffer, uint64_t value) {
	char digits[32];
	size_t count = 0;
	do {
		digits[count++] = (char)(48 + value % 10);
		value /= 10;
	} while (value != 0 && count < sizeof(digits));
	while (count > 0) novaflare_buffer_char(buffer, digits[--count]);
}

static void novaflare_buffer_i64(NovaFlareNativeBuffer* buffer, int64_t value) {
	if (value < 0) {
		novaflare_buffer_char(buffer, 45);
		novaflare_buffer_u64(buffer, (uint64_t)(-(value + 1)) + 1);
	} else {
		novaflare_buffer_u64(buffer, (uint64_t)value);
	}
}

static void novaflare_buffer_hex(NovaFlareNativeBuffer* buffer, uint64_t value) {
	static const char* hex = "0123456789abcdef";
	char digits[32];
	size_t count = 0;
	do {
		digits[count++] = hex[value & 15];
		value >>= 4;
	} while (value != 0 && count < sizeof(digits));
	novaflare_buffer_text(buffer, "0x");
	while (count > 0) novaflare_buffer_char(buffer, digits[--count]);
}

static void novaflare_buffer_key_text(NovaFlareNativeBuffer* buffer, const char* key, const char* value) {
	novaflare_buffer_text(buffer, key);
	novaflare_buffer_char(buffer, 61);
	novaflare_buffer_text(buffer, value);
	novaflare_buffer_char(buffer, 10);
}

static void novaflare_buffer_key_u64(NovaFlareNativeBuffer* buffer, const char* key, uint64_t value) {
	novaflare_buffer_text(buffer, key);
	novaflare_buffer_char(buffer, 61);
	novaflare_buffer_u64(buffer, value);
	novaflare_buffer_char(buffer, 10);
}

static void novaflare_buffer_key_i64(NovaFlareNativeBuffer* buffer, const char* key, int64_t value) {
	novaflare_buffer_text(buffer, key);
	novaflare_buffer_char(buffer, 61);
	novaflare_buffer_i64(buffer, value);
	novaflare_buffer_char(buffer, 10);
}

static void novaflare_buffer_key_hex(NovaFlareNativeBuffer* buffer, const char* key, uint64_t value) {
	novaflare_buffer_text(buffer, key);
	novaflare_buffer_char(buffer, 61);
	novaflare_buffer_hex(buffer, value);
	novaflare_buffer_char(buffer, 10);
}

static void novaflare_copy_string(char* destination, size_t capacity, const char* source) {
	if (destination == 0 || capacity == 0) return;
	size_t index = 0;
	if (source != 0) {
		while (source[index] != 0 && index + 1 < capacity) {
			destination[index] = source[index];
			index++;
		}
	}
	destination[index] = 0;
}

static void novaflare_native_crash_set_directory(const char* directory) {
	if (directory != 0 && directory[0] != 0) {
		novaflare_copy_string(
			novaflare_native_crash_directory,
			sizeof(novaflare_native_crash_directory),
			directory);
	}
}

#if defined(HX_WINDOWS)

#include <windows.h>
#include <dbghelp.h>

static PVOID novaflare_windows_vectored_handle = 0;
static volatile LONG novaflare_windows_installed = 0;
static volatile LONG novaflare_windows_report_lock = 0;
static volatile LONG novaflare_windows_report_count = 0;
static wchar_t novaflare_windows_crash_directory[4096];
static wchar_t novaflare_windows_text_path[4096];
static wchar_t novaflare_windows_dump_path[4096];
static wchar_t novaflare_windows_module_path[4096];
static char novaflare_windows_module_utf8[8192];
static ULONG_PTR novaflare_windows_stack_words[48];

static const char* novaflare_windows_exception_name(DWORD code) {
	switch (code) {
		case EXCEPTION_ACCESS_VIOLATION: return "EXCEPTION_ACCESS_VIOLATION";
		case EXCEPTION_ARRAY_BOUNDS_EXCEEDED: return "EXCEPTION_ARRAY_BOUNDS_EXCEEDED";
		case EXCEPTION_BREAKPOINT: return "EXCEPTION_BREAKPOINT";
		case EXCEPTION_DATATYPE_MISALIGNMENT: return "EXCEPTION_DATATYPE_MISALIGNMENT";
		case EXCEPTION_FLT_DENORMAL_OPERAND: return "EXCEPTION_FLT_DENORMAL_OPERAND";
		case EXCEPTION_FLT_DIVIDE_BY_ZERO: return "EXCEPTION_FLT_DIVIDE_BY_ZERO";
		case EXCEPTION_FLT_INEXACT_RESULT: return "EXCEPTION_FLT_INEXACT_RESULT";
		case EXCEPTION_FLT_INVALID_OPERATION: return "EXCEPTION_FLT_INVALID_OPERATION";
		case EXCEPTION_FLT_OVERFLOW: return "EXCEPTION_FLT_OVERFLOW";
		case EXCEPTION_FLT_STACK_CHECK: return "EXCEPTION_FLT_STACK_CHECK";
		case EXCEPTION_FLT_UNDERFLOW: return "EXCEPTION_FLT_UNDERFLOW";
		case EXCEPTION_ILLEGAL_INSTRUCTION: return "EXCEPTION_ILLEGAL_INSTRUCTION";
		case EXCEPTION_IN_PAGE_ERROR: return "EXCEPTION_IN_PAGE_ERROR";
		case EXCEPTION_INT_DIVIDE_BY_ZERO: return "EXCEPTION_INT_DIVIDE_BY_ZERO";
		case EXCEPTION_INT_OVERFLOW: return "EXCEPTION_INT_OVERFLOW";
		case EXCEPTION_INVALID_DISPOSITION: return "EXCEPTION_INVALID_DISPOSITION";
		case EXCEPTION_NONCONTINUABLE_EXCEPTION: return "EXCEPTION_NONCONTINUABLE_EXCEPTION";
		case EXCEPTION_PRIV_INSTRUCTION: return "EXCEPTION_PRIV_INSTRUCTION";
		case EXCEPTION_SINGLE_STEP: return "EXCEPTION_SINGLE_STEP";
		case EXCEPTION_STACK_OVERFLOW: return "EXCEPTION_STACK_OVERFLOW";
		default: return "UNKNOWN_NATIVE_EXCEPTION";
	}
}

static bool novaflare_windows_is_fatal(DWORD code) {
	switch (code) {
		case EXCEPTION_ACCESS_VIOLATION:
		case EXCEPTION_ARRAY_BOUNDS_EXCEEDED:
		case EXCEPTION_DATATYPE_MISALIGNMENT:
		case EXCEPTION_FLT_DIVIDE_BY_ZERO:
		case EXCEPTION_FLT_INVALID_OPERATION:
		case EXCEPTION_FLT_OVERFLOW:
		case EXCEPTION_ILLEGAL_INSTRUCTION:
		case EXCEPTION_IN_PAGE_ERROR:
		case EXCEPTION_INT_DIVIDE_BY_ZERO:
		case EXCEPTION_INT_OVERFLOW:
		case EXCEPTION_INVALID_DISPOSITION:
		case EXCEPTION_NONCONTINUABLE_EXCEPTION:
		case EXCEPTION_PRIV_INSTRUCTION:
		case EXCEPTION_STACK_OVERFLOW:
			return true;
		default:
			return false;
	}
}

static void novaflare_windows_prepare_paths(LONG reportIndex) {
	int converted = MultiByteToWideChar(
		CP_UTF8,
		MB_ERR_INVALID_CHARS,
		novaflare_native_crash_directory,
		-1,
		novaflare_windows_crash_directory,
		(int)(sizeof(novaflare_windows_crash_directory) / sizeof(wchar_t)));
	if (converted <= 0) {
		MultiByteToWideChar(
			CP_ACP,
			0,
			novaflare_native_crash_directory,
			-1,
			novaflare_windows_crash_directory,
			(int)(sizeof(novaflare_windows_crash_directory) / sizeof(wchar_t)));
	}
	CreateDirectoryW(novaflare_windows_crash_directory, 0);

	SYSTEMTIME now;
	GetLocalTime(&now);
	DWORD pid = GetCurrentProcessId();
	DWORD tid = GetCurrentThreadId();
	_snwprintf_s(
		novaflare_windows_text_path,
		sizeof(novaflare_windows_text_path) / sizeof(wchar_t),
		_TRUNCATE,
		L"%s\\\\native-crash-%04u%02u%02u-%02u%02u%02u-%03u-p%lu-t%lu-%ld.txt",
		novaflare_windows_crash_directory,
		now.wYear,
		now.wMonth,
		now.wDay,
		now.wHour,
		now.wMinute,
		now.wSecond,
		now.wMilliseconds,
		(unsigned long)pid,
		(unsigned long)tid,
		(long)reportIndex);
	_snwprintf_s(
		novaflare_windows_dump_path,
		sizeof(novaflare_windows_dump_path) / sizeof(wchar_t),
		_TRUNCATE,
		L"%s\\\\native-crash-%04u%02u%02u-%02u%02u%02u-%03u-p%lu-t%lu-%ld.dmp",
		novaflare_windows_crash_directory,
		now.wYear,
		now.wMonth,
		now.wDay,
		now.wHour,
		now.wMinute,
		now.wSecond,
		now.wMilliseconds,
		(unsigned long)pid,
		(unsigned long)tid,
		(long)reportIndex);
}

static void novaflare_windows_write_file(const wchar_t* path, const char* data, size_t length, DWORD creation) {
	HANDLE file = CreateFileW(
		path,
		GENERIC_WRITE,
		FILE_SHARE_READ | FILE_SHARE_WRITE,
		0,
		creation,
		FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH,
		0);
	if (file == INVALID_HANDLE_VALUE) return;
	if (creation == OPEN_EXISTING) SetFilePointer(file, 0, 0, FILE_END);
	DWORD written = 0;
	while (length > 0) {
		DWORD chunk = length > 0x7fffffff ? 0x7fffffff : (DWORD)length;
		if (!WriteFile(file, data, chunk, &written, 0) || written == 0) break;
		data += written;
		length -= written;
	}
	FlushFileBuffers(file);
	CloseHandle(file);
}

static void novaflare_windows_append_registers(NovaFlareNativeBuffer* buffer, CONTEXT* context) {
	novaflare_buffer_text(buffer, "\\n[registers]\\n");
#if defined(_M_X64) || defined(__x86_64__)
	novaflare_buffer_key_hex(buffer, "rip", context->Rip);
	novaflare_buffer_key_hex(buffer, "rsp", context->Rsp);
	novaflare_buffer_key_hex(buffer, "rbp", context->Rbp);
	novaflare_buffer_key_hex(buffer, "rax", context->Rax);
	novaflare_buffer_key_hex(buffer, "rbx", context->Rbx);
	novaflare_buffer_key_hex(buffer, "rcx", context->Rcx);
	novaflare_buffer_key_hex(buffer, "rdx", context->Rdx);
	novaflare_buffer_key_hex(buffer, "rsi", context->Rsi);
	novaflare_buffer_key_hex(buffer, "rdi", context->Rdi);
	novaflare_buffer_key_hex(buffer, "r8", context->R8);
	novaflare_buffer_key_hex(buffer, "r9", context->R9);
	novaflare_buffer_key_hex(buffer, "r10", context->R10);
	novaflare_buffer_key_hex(buffer, "r11", context->R11);
	novaflare_buffer_key_hex(buffer, "r12", context->R12);
	novaflare_buffer_key_hex(buffer, "r13", context->R13);
	novaflare_buffer_key_hex(buffer, "r14", context->R14);
	novaflare_buffer_key_hex(buffer, "r15", context->R15);
	ULONG_PTR stackPointer = (ULONG_PTR)context->Rsp;
#else
	novaflare_buffer_key_hex(buffer, "eip", context->Eip);
	novaflare_buffer_key_hex(buffer, "esp", context->Esp);
	novaflare_buffer_key_hex(buffer, "ebp", context->Ebp);
	novaflare_buffer_key_hex(buffer, "eax", context->Eax);
	novaflare_buffer_key_hex(buffer, "ebx", context->Ebx);
	novaflare_buffer_key_hex(buffer, "ecx", context->Ecx);
	novaflare_buffer_key_hex(buffer, "edx", context->Edx);
	novaflare_buffer_key_hex(buffer, "esi", context->Esi);
	novaflare_buffer_key_hex(buffer, "edi", context->Edi);
	ULONG_PTR stackPointer = (ULONG_PTR)context->Esp;
#endif

	SIZE_T bytesRead = 0;
	if (ReadProcessMemory(
		GetCurrentProcess(),
		(const void*)stackPointer,
		novaflare_windows_stack_words,
		sizeof(novaflare_windows_stack_words),
		&bytesRead)) {
		novaflare_buffer_text(buffer, "\\n[raw_stack_words]\\n");
		size_t count = bytesRead / sizeof(ULONG_PTR);
		for (size_t index = 0; index < count; index++) {
			novaflare_buffer_text(buffer, "stack_");
			novaflare_buffer_u64(buffer, index);
			novaflare_buffer_char(buffer, 61);
			novaflare_buffer_hex(buffer, (uint64_t)novaflare_windows_stack_words[index]);
			novaflare_buffer_char(buffer, 10);
		}
	}
}

static void novaflare_windows_write_report(EXCEPTION_POINTERS* pointers, const char* phase, bool writeDump) {
	if (pointers == 0 || pointers->ExceptionRecord == 0 || pointers->ContextRecord == 0) return;
	if (InterlockedCompareExchange(&novaflare_windows_report_lock, 1, 0) != 0) return;
	LONG reportIndex = InterlockedIncrement(&novaflare_windows_report_count);
	if (reportIndex > 8) {
		InterlockedExchange(&novaflare_windows_report_lock, 0);
		return;
	}

	novaflare_windows_prepare_paths(reportIndex);
	NovaFlareNativeBuffer buffer = {
		novaflare_native_report_buffer,
		0,
		sizeof(novaflare_native_report_buffer)
	};
	buffer.data[0] = 0;

	EXCEPTION_RECORD* record = pointers->ExceptionRecord;
	novaflare_buffer_key_text(&buffer, "format", "novaflare-native-crash-v1");
	novaflare_buffer_key_text(&buffer, "platform", "windows");
	novaflare_buffer_key_text(&buffer, "commit", novaflare_native_commit);
	novaflare_buffer_key_text(&buffer, "phase", phase);
	novaflare_buffer_key_u64(&buffer, "process_id", GetCurrentProcessId());
	novaflare_buffer_key_u64(&buffer, "thread_id", GetCurrentThreadId());
	novaflare_buffer_key_text(&buffer, "exception_name", novaflare_windows_exception_name(record->ExceptionCode));
	novaflare_buffer_key_hex(&buffer, "exception_code", record->ExceptionCode);
	novaflare_buffer_key_hex(&buffer, "exception_flags", record->ExceptionFlags);
	novaflare_buffer_key_hex(&buffer, "exception_address", (uint64_t)(uintptr_t)record->ExceptionAddress);

	HMODULE module = 0;
	if (GetModuleHandleExW(
		GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
		(LPCWSTR)record->ExceptionAddress,
		&module)) {
		DWORD moduleLength = GetModuleFileNameW(
			module,
			novaflare_windows_module_path,
			(DWORD)(sizeof(novaflare_windows_module_path) / sizeof(wchar_t)));
		if (moduleLength > 0) {
			WideCharToMultiByte(
				CP_UTF8,
				0,
				novaflare_windows_module_path,
				-1,
				novaflare_windows_module_utf8,
				(int)sizeof(novaflare_windows_module_utf8),
				0,
				0);
			novaflare_buffer_key_text(&buffer, "fault_module", novaflare_windows_module_utf8);
		}
		novaflare_buffer_key_hex(&buffer, "fault_module_base", (uint64_t)(uintptr_t)module);
		novaflare_buffer_key_hex(
			&buffer,
			"fault_module_rva",
			(uint64_t)((uintptr_t)record->ExceptionAddress - (uintptr_t)module));
	}

	novaflare_buffer_key_u64(&buffer, "exception_parameter_count", record->NumberParameters);
	for (DWORD index = 0; index < record->NumberParameters && index < EXCEPTION_MAXIMUM_PARAMETERS; index++) {
		novaflare_buffer_text(&buffer, "exception_parameter_");
		novaflare_buffer_u64(&buffer, index);
		novaflare_buffer_char(&buffer, 61);
		novaflare_buffer_hex(&buffer, (uint64_t)record->ExceptionInformation[index]);
		novaflare_buffer_char(&buffer, 10);
	}
	if ((record->ExceptionCode == EXCEPTION_ACCESS_VIOLATION || record->ExceptionCode == EXCEPTION_IN_PAGE_ERROR)
		&& record->NumberParameters >= 2) {
		const char* access = record->ExceptionInformation[0] == 0
			? "read"
			: (record->ExceptionInformation[0] == 1 ? "write" : "execute");
		novaflare_buffer_key_text(&buffer, "access_type", access);
		novaflare_buffer_key_hex(&buffer, "access_address", (uint64_t)record->ExceptionInformation[1]);
	}

	novaflare_windows_append_registers(&buffer, pointers->ContextRecord);
	novaflare_windows_write_file(
		novaflare_windows_text_path,
		buffer.data,
		buffer.length,
		CREATE_ALWAYS);

	if (writeDump) {
		HANDLE dumpFile = CreateFileW(
			novaflare_windows_dump_path,
			GENERIC_WRITE,
			FILE_SHARE_READ,
			0,
			CREATE_ALWAYS,
			FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH,
			0);
		BOOL dumpResult = FALSE;
		DWORD dumpError = 0;
		if (dumpFile != INVALID_HANDLE_VALUE) {
			MINIDUMP_EXCEPTION_INFORMATION exceptionInfo;
			exceptionInfo.ThreadId = GetCurrentThreadId();
			exceptionInfo.ExceptionPointers = pointers;
			exceptionInfo.ClientPointers = FALSE;
			MINIDUMP_TYPE dumpType = (MINIDUMP_TYPE)(
				MiniDumpWithDataSegs
				| MiniDumpWithHandleData
				| MiniDumpWithUnloadedModules
				| MiniDumpWithIndirectlyReferencedMemory
				| MiniDumpWithProcessThreadData
				| MiniDumpWithThreadInfo
				| MiniDumpIgnoreInaccessibleMemory);
			dumpResult = MiniDumpWriteDump(
				GetCurrentProcess(),
				GetCurrentProcessId(),
				dumpFile,
				dumpType,
				&exceptionInfo,
				0,
				0);
			if (!dumpResult) dumpError = GetLastError();
			FlushFileBuffers(dumpFile);
			CloseHandle(dumpFile);
		} else {
			dumpError = GetLastError();
		}

		NovaFlareNativeBuffer dumpStatus = {
			novaflare_native_report_buffer,
			0,
			sizeof(novaflare_native_report_buffer)
		};
		dumpStatus.data[0] = 0;
		novaflare_buffer_text(&dumpStatus, "\\n[minidump]\\n");
		novaflare_buffer_key_text(&dumpStatus, "written", dumpResult ? "true" : "false");
		novaflare_buffer_key_u64(&dumpStatus, "win32_error", dumpError);
		novaflare_windows_write_file(
			novaflare_windows_text_path,
			dumpStatus.data,
			dumpStatus.length,
			OPEN_EXISTING);
	}

	InterlockedExchange(&novaflare_windows_report_lock, 0);
}

static LONG CALLBACK novaflare_windows_vectored_exception(EXCEPTION_POINTERS* pointers) {
	if (pointers != 0
		&& pointers->ExceptionRecord != 0
		&& novaflare_windows_is_fatal(pointers->ExceptionRecord->ExceptionCode)) {
		novaflare_windows_write_report(pointers, "vectored-first-chance", false);
	}
	return EXCEPTION_CONTINUE_SEARCH;
}

static void novaflare_windows_show_crash_notification() {
	const wchar_t* title =
		L"NovaFlare Engine - \\u5e94\\u7528\\u7a0b\\u5e8f\\u95ea\\u9000 / Application Crash";
	const wchar_t* message =
		L"\\u5e94\\u7528\\u7a0b\\u5e8f\\u5df2\\u95ea\\u9000\\uff0c\\u9519\\u8bef\\u4fe1\\u606f\\u5df2\\u4fdd\\u5b58\\u81f3 crash \\u6587\\u4ef6\\u5939\\u3002\\r\\n"
		L"The application has crashed. Error information was saved to the crash folder.";
	typedef int (WINAPI* NovaFlareMessageBoxTimeoutW)(
		HWND,
		LPCWSTR,
		LPCWSTR,
		UINT,
		WORD,
		DWORD);
	HMODULE user32 = GetModuleHandleW(L"user32.dll");
	NovaFlareMessageBoxTimeoutW showMessage = user32 == 0
		? 0
		: (NovaFlareMessageBoxTimeoutW)GetProcAddress(user32, "MessageBoxTimeoutW");
	if (showMessage != 0) {
		showMessage(
			0,
			message,
			title,
			MB_OK | MB_ICONERROR | MB_SETFOREGROUND | MB_TOPMOST,
			0,
			8000);
	} else {
		MessageBoxW(
			0,
			message,
			title,
			MB_OK | MB_ICONERROR | MB_SETFOREGROUND | MB_TOPMOST);
	}
}

static LONG WINAPI novaflare_windows_unhandled_exception(EXCEPTION_POINTERS* pointers) {
	novaflare_windows_write_report(pointers, "unhandled-filter", true);
	novaflare_windows_show_crash_notification();
	return EXCEPTION_EXECUTE_HANDLER;
}

static void novaflare_windows_install() {
	if (InterlockedCompareExchange(&novaflare_windows_installed, 1, 0) == 0) {
		novaflare_windows_vectored_handle = AddVectoredExceptionHandler(
			1,
			novaflare_windows_vectored_exception);
	}
	SetUnhandledExceptionFilter(novaflare_windows_unhandled_exception);
}

#endif

#if defined(ANDROID)

#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <jni.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <time.h>
#include <ucontext.h>
#include <unistd.h>

static volatile sig_atomic_t novaflare_android_handling_crash = 0;
static volatile sig_atomic_t novaflare_android_installed = 0;
static int novaflare_android_pending_fd = -1;
static char novaflare_android_pending_path[4096];
static char novaflare_android_final_path[4096];
static unsigned char novaflare_android_alt_stack_memory[64 * 1024];
static JavaVM* novaflare_android_java_vm = 0;
static jobject novaflare_android_context = 0;
static jclass novaflare_android_crash_dialog_class = 0;
static jmethodID novaflare_android_crash_dialog_method = 0;
static int novaflare_android_notification_request[2] = {-1, -1};
static int novaflare_android_notification_ack[2] = {-1, -1};
static pthread_t novaflare_android_notification_thread;
static volatile sig_atomic_t novaflare_android_notification_status = 0;

typedef void* (*NovaFlareAndroidSDLObjectGetter)(void);
static void novaflare_android_write_all(int fd, const char* data, size_t length);

static void novaflare_android_clear_jni_exception(JNIEnv* environment) {
	if (environment != 0 && environment->ExceptionCheck()) {
		environment->ExceptionClear();
	}
}

static jclass novaflare_android_load_application_class(
	JNIEnv* environment,
	jobject activity,
	const char* className) {
	if (environment == 0 || activity == 0 || className == 0) return 0;

	jclass activityClass = environment->GetObjectClass(activity);
	jmethodID getClassLoader = activityClass == 0
		? 0
		: environment->GetMethodID(
			activityClass,
			"getClassLoader",
			"()Ljava/lang/ClassLoader;");
	jobject classLoader = getClassLoader == 0
		? 0
		: environment->CallObjectMethod(activity, getClassLoader);
	jclass classLoaderClass = environment->FindClass("java/lang/ClassLoader");
	jmethodID loadClass = classLoaderClass == 0
		? 0
		: environment->GetMethodID(
			classLoaderClass,
			"loadClass",
			"(Ljava/lang/String;)Ljava/lang/Class;");
	jstring requestedClass = environment->NewStringUTF(className);
	jclass result = classLoader == 0 || loadClass == 0 || requestedClass == 0
		? 0
		: (jclass)environment->CallObjectMethod(
			classLoader,
			loadClass,
			requestedClass);

	if (requestedClass != 0) environment->DeleteLocalRef(requestedClass);
	if (classLoaderClass != 0) environment->DeleteLocalRef(classLoaderClass);
	if (classLoader != 0) environment->DeleteLocalRef(classLoader);
	if (activityClass != 0) environment->DeleteLocalRef(activityClass);
	if (environment->ExceptionCheck()) {
		environment->ExceptionClear();
		return 0;
	}
	return result;
}

static int novaflare_android_sdk_int(JNIEnv* environment) {
	jclass versionClass = environment->FindClass("android/os/Build$VERSION");
	if (versionClass == 0) {
		novaflare_android_clear_jni_exception(environment);
		return 0;
	}
	jfieldID sdkField = environment->GetStaticFieldID(versionClass, "SDK_INT", "I");
	int result = sdkField == 0 ? 0 : environment->GetStaticIntField(versionClass, sdkField);
	environment->DeleteLocalRef(versionClass);
	novaflare_android_clear_jni_exception(environment);
	return result;
}

static int novaflare_android_notification_icon(JNIEnv* environment, jobject context) {
	int icon = 0;
	jclass contextClass = environment->GetObjectClass(context);
	jmethodID applicationInfoMethod = contextClass == 0
		? 0
		: environment->GetMethodID(
			contextClass,
			"getApplicationInfo",
			"()Landroid/content/pm/ApplicationInfo;");
	jobject applicationInfo = applicationInfoMethod == 0
		? 0
		: environment->CallObjectMethod(context, applicationInfoMethod);
	if (applicationInfo != 0) {
		jclass applicationInfoClass = environment->GetObjectClass(applicationInfo);
		jfieldID iconField = applicationInfoClass == 0
			? 0
			: environment->GetFieldID(applicationInfoClass, "icon", "I");
		if (iconField != 0) icon = environment->GetIntField(applicationInfo, iconField);
		if (applicationInfoClass != 0) environment->DeleteLocalRef(applicationInfoClass);
		environment->DeleteLocalRef(applicationInfo);
	}
	if (contextClass != 0) environment->DeleteLocalRef(contextClass);
	novaflare_android_clear_jni_exception(environment);

	if (icon == 0) {
		jclass drawableClass = environment->FindClass("android/R$drawable");
		jfieldID fallbackField = drawableClass == 0
			? 0
			: environment->GetStaticFieldID(drawableClass, "ic_dialog_alert", "I");
		if (fallbackField != 0) icon = environment->GetStaticIntField(drawableClass, fallbackField);
		if (drawableClass != 0) environment->DeleteLocalRef(drawableClass);
		novaflare_android_clear_jni_exception(environment);
	}
	return icon;
}

static void novaflare_android_publish_crash_notification(JNIEnv* environment) {
	novaflare_android_notification_status = 40;
	if (environment == 0 || novaflare_android_context == 0) {
		novaflare_android_notification_status = -40;
		return;
	}

	jclass contextClass = environment->GetObjectClass(novaflare_android_context);
	jmethodID serviceMethod = contextClass == 0
		? 0
		: environment->GetMethodID(
			contextClass,
			"getSystemService",
			"(Ljava/lang/String;)Ljava/lang/Object;");
	jstring notificationService = environment->NewStringUTF("notification");
	jobject manager = serviceMethod == 0
		? 0
		: environment->CallObjectMethod(
			novaflare_android_context,
			serviceMethod,
			notificationService);
	novaflare_android_clear_jni_exception(environment);
	if (manager == 0) {
		novaflare_android_notification_status = -41;
		if (notificationService != 0) environment->DeleteLocalRef(notificationService);
		if (contextClass != 0) environment->DeleteLocalRef(contextClass);
		return;
	}
	novaflare_android_notification_status = 41;

	const int sdk = novaflare_android_sdk_int(environment);
	jstring channelId = environment->NewStringUTF("novaflare_native_crash");
	jstring channelName = environment->NewStringUTF(
		"NovaFlare Crash Reports / \\u5d29\\u6e83\\u62a5\\u544a");
	jclass managerClass = environment->GetObjectClass(manager);

	if (sdk >= 26) {
		jclass channelClass = environment->FindClass("android/app/NotificationChannel");
		jmethodID channelConstructor = channelClass == 0
			? 0
			: environment->GetMethodID(
				channelClass,
				"<init>",
				"(Ljava/lang/String;Ljava/lang/CharSequence;I)V");
		jobject channel = channelConstructor == 0
			? 0
			: environment->NewObject(
				channelClass,
				channelConstructor,
				channelId,
				channelName,
				4);
		jmethodID createChannelMethod = managerClass == 0
			? 0
			: environment->GetMethodID(
				managerClass,
				"createNotificationChannel",
				"(Landroid/app/NotificationChannel;)V");
		if (channel != 0 && createChannelMethod != 0) {
			environment->CallVoidMethod(manager, createChannelMethod, channel);
		}
		if (channel != 0) environment->DeleteLocalRef(channel);
		if (channelClass != 0) environment->DeleteLocalRef(channelClass);
		novaflare_android_clear_jni_exception(environment);
	}

	jclass builderClass = environment->FindClass("android/app/Notification$Builder");
	jmethodID builderConstructor = builderClass == 0
		? 0
		: environment->GetMethodID(
			builderClass,
			"<init>",
			sdk >= 26
				? "(Landroid/content/Context;Ljava/lang/String;)V"
				: "(Landroid/content/Context;)V");
	jobject builder = builderConstructor == 0
		? 0
		: (sdk >= 26
			? environment->NewObject(
				builderClass,
				builderConstructor,
				novaflare_android_context,
				channelId)
			: environment->NewObject(
				builderClass,
				builderConstructor,
				novaflare_android_context));
	novaflare_android_clear_jni_exception(environment);

	if (builder != 0) {
		novaflare_android_notification_status = 42;
		jstring title = environment->NewStringUTF(
			"NovaFlare Engine - \\u5e94\\u7528\\u7a0b\\u5e8f\\u95ea\\u9000 / Application Crash");
		jstring message = environment->NewStringUTF(
			"\\u5e94\\u7528\\u7a0b\\u5e8f\\u5df2\\u95ea\\u9000\\uff0c\\u9519\\u8bef\\u4fe1\\u606f\\u5df2\\u4fdd\\u5b58\\u81f3 crash \\u6587\\u4ef6\\u5939\\u3002\\n"
			"The application has crashed. Error information was saved to the crash folder.");
		jmethodID setAutoCancel = environment->GetMethodID(
			builderClass,
			"setAutoCancel",
			"(Z)Landroid/app/Notification$Builder;");
		jmethodID setTitle = environment->GetMethodID(
			builderClass,
			"setContentTitle",
			"(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;");
		jmethodID setText = environment->GetMethodID(
			builderClass,
			"setContentText",
			"(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;");
		jmethodID setDefaults = environment->GetMethodID(
			builderClass,
			"setDefaults",
			"(I)Landroid/app/Notification$Builder;");
		jmethodID setSmallIcon = environment->GetMethodID(
			builderClass,
			"setSmallIcon",
			"(I)Landroid/app/Notification$Builder;");
		jmethodID setWhen = environment->GetMethodID(
			builderClass,
			"setWhen",
			"(J)Landroid/app/Notification$Builder;");
		if (setAutoCancel != 0) environment->CallObjectMethod(builder, setAutoCancel, JNI_TRUE);
		if (setTitle != 0) environment->CallObjectMethod(builder, setTitle, title);
		if (setText != 0) environment->CallObjectMethod(builder, setText, message);
		if (setDefaults != 0) environment->CallObjectMethod(builder, setDefaults, -1);
		const int icon = novaflare_android_notification_icon(
			environment,
			novaflare_android_context);
		if (setSmallIcon != 0 && icon != 0) {
			environment->CallObjectMethod(builder, setSmallIcon, icon);
		}
		struct timespec notificationTime;
		clock_gettime(CLOCK_REALTIME, &notificationTime);
		jlong milliseconds =
			(jlong)notificationTime.tv_sec * 1000 + notificationTime.tv_nsec / 1000000;
		if (setWhen != 0) environment->CallObjectMethod(builder, setWhen, milliseconds);

		jmethodID buildMethod = environment->GetMethodID(
			builderClass,
			"build",
			"()Landroid/app/Notification;");
		jobject notification = buildMethod == 0
			? 0
			: environment->CallObjectMethod(builder, buildMethod);
		jmethodID notifyMethod = managerClass == 0
			? 0
			: environment->GetMethodID(
				managerClass,
				"notify",
				"(ILandroid/app/Notification;)V");
		if (notification != 0 && notifyMethod != 0) {
			environment->CallVoidMethod(manager, notifyMethod, 0x4e46, notification);
		}
		if (environment->ExceptionCheck()) {
			environment->ExceptionClear();
			novaflare_android_notification_status = -43;
		} else if (notification != 0 && notifyMethod != 0) {
			novaflare_android_notification_status = 50;
		} else {
			novaflare_android_notification_status = -44;
		}
		if (notification != 0) environment->DeleteLocalRef(notification);
		if (title != 0) environment->DeleteLocalRef(title);
		if (message != 0) environment->DeleteLocalRef(message);
		environment->DeleteLocalRef(builder);
	} else {
		novaflare_android_notification_status = -42;
	}

	if (builderClass != 0) environment->DeleteLocalRef(builderClass);
	if (managerClass != 0) environment->DeleteLocalRef(managerClass);
	if (channelId != 0) environment->DeleteLocalRef(channelId);
	if (channelName != 0) environment->DeleteLocalRef(channelName);
	environment->DeleteLocalRef(manager);
	if (notificationService != 0) environment->DeleteLocalRef(notificationService);
	if (contextClass != 0) environment->DeleteLocalRef(contextClass);
	novaflare_android_clear_jni_exception(environment);
}

static bool novaflare_android_show_crash_dialog(JNIEnv* environment) {
	if (environment == 0
		|| novaflare_android_crash_dialog_class == 0
		|| novaflare_android_crash_dialog_method == 0) {
		return false;
	}

	jboolean confirmed = environment->CallStaticBooleanMethod(
		novaflare_android_crash_dialog_class,
		novaflare_android_crash_dialog_method);
	if (environment->ExceptionCheck()) {
		environment->ExceptionClear();
		return false;
	}
	return confirmed == JNI_TRUE;
}

static void* novaflare_android_notification_worker(void*) {
	novaflare_android_notification_status = 20;
	if (novaflare_android_java_vm == 0) {
		novaflare_android_notification_status = -20;
		return 0;
	}
	JNIEnv* environment = 0;
	bool attached = novaflare_android_java_vm->GetEnv(
		(void**)&environment,
		JNI_VERSION_1_6) != JNI_OK;
	if (attached
		&& novaflare_android_java_vm->AttachCurrentThread(&environment, 0) != JNI_OK) {
		novaflare_android_notification_status = -21;
		return 0;
	}
	novaflare_android_notification_status = 21;

	for (;;) {
		unsigned char request = 0;
		ssize_t count = read(
			novaflare_android_notification_request[0],
			&request,
			sizeof(request));
		if (count == (ssize_t)sizeof(request)) {
			novaflare_android_notification_status = 30;
			bool confirmed = novaflare_android_show_crash_dialog(environment);
			novaflare_android_notification_status = confirmed ? 50 : -50;
			unsigned char acknowledgement = 1;
			write(
				novaflare_android_notification_ack[1],
				&acknowledgement,
				sizeof(acknowledgement));
			break;
		}
		if (count < 0 && errno == EINTR) continue;
		if (count <= 0) break;
	}

	if (attached) novaflare_android_java_vm->DetachCurrentThread();
	return 0;
}

static void novaflare_android_start_notification_worker() {
	novaflare_android_notification_status = 1;
	void* limeLibrary = dlopen("liblime.so", RTLD_NOW | RTLD_NOLOAD);
	if (limeLibrary == 0) limeLibrary = dlopen("liblime.so", RTLD_NOW);
	if (limeLibrary == 0) {
		novaflare_android_notification_status = -1;
		return;
	}
	NovaFlareAndroidSDLObjectGetter getEnvironment =
		(NovaFlareAndroidSDLObjectGetter)dlsym(
			limeLibrary,
			"SDL_AndroidGetJNIEnv");
	NovaFlareAndroidSDLObjectGetter getActivity =
		(NovaFlareAndroidSDLObjectGetter)dlsym(
			limeLibrary,
			"SDL_AndroidGetActivity");
	if (getEnvironment == 0 || getActivity == 0) {
		novaflare_android_notification_status = -2;
		return;
	}
	novaflare_android_notification_status = 2;
	JNIEnv* environment = (JNIEnv*)getEnvironment();
	jobject activity = (jobject)getActivity();
	if (environment == 0 || activity == 0) {
		novaflare_android_notification_status = -3;
		return;
	}
	if (environment->GetJavaVM(&novaflare_android_java_vm) != JNI_OK) {
		novaflare_android_notification_status = -4;
		return;
	}
	novaflare_android_context = environment->NewGlobalRef(activity);
	if (novaflare_android_context == 0) {
		novaflare_android_notification_status = -5;
		return;
	}
	jclass localDialogClass = novaflare_android_load_application_class(
		environment,
		activity,
		"org.novaflare.crash.NativeCrashDialog");
	if (localDialogClass == 0) {
		novaflare_android_clear_jni_exception(environment);
		novaflare_android_notification_status = -9;
		return;
	}
	novaflare_android_crash_dialog_class =
		(jclass)environment->NewGlobalRef(localDialogClass);
	environment->DeleteLocalRef(localDialogClass);
	if (novaflare_android_crash_dialog_class == 0) {
		novaflare_android_notification_status = -10;
		return;
	}
	novaflare_android_crash_dialog_method = environment->GetStaticMethodID(
		novaflare_android_crash_dialog_class,
		"showAndWait",
		"()Z");
	if (novaflare_android_crash_dialog_method == 0) {
		novaflare_android_clear_jni_exception(environment);
		novaflare_android_notification_status = -11;
		return;
	}
	if (pipe(novaflare_android_notification_request) != 0) {
		novaflare_android_notification_status = -6;
		return;
	}
	if (pipe(novaflare_android_notification_ack) != 0) {
		novaflare_android_notification_status = -7;
		return;
	}

	fcntl(
		novaflare_android_notification_request[1],
		F_SETFL,
		fcntl(novaflare_android_notification_request[1], F_GETFL)
			| O_NONBLOCK);
	fcntl(
		novaflare_android_notification_ack[0],
		F_SETFL,
		fcntl(novaflare_android_notification_ack[0], F_GETFL)
			| O_NONBLOCK);
	if (pthread_create(
		&novaflare_android_notification_thread,
		0,
		novaflare_android_notification_worker,
		0) == 0) {
		pthread_detach(novaflare_android_notification_thread);
	} else {
		novaflare_android_notification_status = -8;
	}
}

static void novaflare_android_notify_before_exit() {
	if (novaflare_android_notification_request[1] < 0
		|| novaflare_android_notification_ack[0] < 0) {
		return;
	}
	unsigned char request = 1;
	if (write(
		novaflare_android_notification_request[1],
		&request,
		sizeof(request)) != (ssize_t)sizeof(request)) {
		return;
	}

	struct timespec delay;
	delay.tv_sec = 0;
	delay.tv_nsec = 10 * 1000 * 1000;
	for (int attempt = 0; attempt < 6500; attempt++) {
		unsigned char acknowledgement = 0;
		if (read(
			novaflare_android_notification_ack[0],
			&acknowledgement,
			sizeof(acknowledgement)) == (ssize_t)sizeof(acknowledgement)) {
			break;
		}
		nanosleep(&delay, 0);
	}
}

static void novaflare_android_append_notification_status() {
	if (novaflare_android_final_path[0] == 0) return;
	int statusFd = open(
		novaflare_android_final_path,
		O_WRONLY | O_APPEND | O_CLOEXEC);
	if (statusFd < 0) return;
	NovaFlareNativeBuffer statusBuffer = {
		novaflare_native_report_buffer,
		0,
		sizeof(novaflare_native_report_buffer)
	};
	statusBuffer.data[0] = 0;
	novaflare_buffer_text(&statusBuffer, "\\n[native_crash_dialog]\\n");
	novaflare_buffer_key_i64(
		&statusBuffer,
		"status_code",
		(int64_t)novaflare_android_notification_status);
	novaflare_android_write_all(
		statusFd,
		statusBuffer.data,
		statusBuffer.length);
	fsync(statusFd);
	close(statusFd);
}

static pid_t novaflare_android_gettid() {
#if defined(__NR_gettid)
	return (pid_t)syscall(__NR_gettid);
#else
	return getpid();
#endif
}

static void novaflare_android_write_all(int fd, const char* data, size_t length) {
	while (fd >= 0 && length > 0) {
		ssize_t written = write(fd, data, length);
		if (written > 0) {
			data += written;
			length -= (size_t)written;
		} else if (written < 0 && errno == EINTR) {
			continue;
		} else {
			break;
		}
	}
}

static void novaflare_android_cleanup_pending() {
	if (novaflare_android_pending_fd >= 0) {
		close(novaflare_android_pending_fd);
		novaflare_android_pending_fd = -1;
	}
	if (novaflare_android_pending_path[0] != 0) {
		unlink(novaflare_android_pending_path);
		novaflare_android_pending_path[0] = 0;
	}
}

static void novaflare_android_prepare_output() {
	novaflare_android_cleanup_pending();
	mkdir(novaflare_native_crash_directory, 0775);

	struct timespec now;
	clock_gettime(CLOCK_REALTIME, &now);
	pid_t pid = getpid();
	snprintf(
		novaflare_android_pending_path,
		sizeof(novaflare_android_pending_path),
		"%s/.native-crash-pending-%d.txt",
		novaflare_native_crash_directory,
		(int)pid);
	snprintf(
		novaflare_android_final_path,
		sizeof(novaflare_android_final_path),
		"%s/native-crash-%lld-%09ld-p%d.txt",
		novaflare_native_crash_directory,
		(long long)now.tv_sec,
		now.tv_nsec,
		(int)pid);
	novaflare_android_pending_fd = open(
		novaflare_android_pending_path,
		O_CREAT | O_WRONLY | O_TRUNC | O_CLOEXEC,
		0644);
}

static const char* novaflare_android_signal_name(int signalNumber) {
	switch (signalNumber) {
		case SIGABRT: return "SIGABRT";
		case SIGBUS: return "SIGBUS";
		case SIGFPE: return "SIGFPE";
		case SIGILL: return "SIGILL";
		case SIGSEGV: return "SIGSEGV";
		default: return "UNKNOWN_SIGNAL";
	}
}

#if defined(__aarch64__) && defined(__NR_process_vm_readv)
struct NovaFlareAndroidFrameRecord {
	uintptr_t previousFrame;
	uintptr_t returnAddress;
};

static bool novaflare_android_read_frame(uintptr_t address, NovaFlareAndroidFrameRecord* frame) {
	struct iovec local;
	local.iov_base = frame;
	local.iov_len = sizeof(NovaFlareAndroidFrameRecord);
	struct iovec remote;
	remote.iov_base = (void*)address;
	remote.iov_len = sizeof(NovaFlareAndroidFrameRecord);
	ssize_t result = syscall(
		__NR_process_vm_readv,
		getpid(),
		&local,
		1,
		&remote,
		1,
		0);
	return result == (ssize_t)sizeof(NovaFlareAndroidFrameRecord);
}
#endif

static void novaflare_android_append_context(NovaFlareNativeBuffer* buffer, void* rawContext) {
	novaflare_buffer_text(buffer, "\\n[registers]\\n");
#if defined(__aarch64__)
	ucontext_t* context = (ucontext_t*)rawContext;
	novaflare_buffer_key_text(buffer, "architecture", "arm64");
	novaflare_buffer_key_hex(buffer, "pc", (uint64_t)context->uc_mcontext.pc);
	novaflare_buffer_key_hex(buffer, "sp", (uint64_t)context->uc_mcontext.sp);
	novaflare_buffer_key_hex(buffer, "pstate", (uint64_t)context->uc_mcontext.pstate);
	for (int index = 0; index < 31; index++) {
		novaflare_buffer_text(buffer, "x");
		novaflare_buffer_u64(buffer, (uint64_t)index);
		novaflare_buffer_char(buffer, 61);
		novaflare_buffer_hex(buffer, (uint64_t)context->uc_mcontext.regs[index]);
		novaflare_buffer_char(buffer, 10);
	}

	novaflare_buffer_text(buffer, "\\n[frame_pointer_backtrace]\\n");
	novaflare_buffer_key_hex(buffer, "frame_0", (uint64_t)context->uc_mcontext.pc);
	novaflare_buffer_key_hex(buffer, "frame_1", (uint64_t)context->uc_mcontext.regs[30]);
#if defined(__NR_process_vm_readv)
	uintptr_t framePointer = (uintptr_t)context->uc_mcontext.regs[29];
	for (int frameIndex = 2; frameIndex < 64; frameIndex++) {
		if (framePointer == 0 || (framePointer & (sizeof(uintptr_t) - 1)) != 0) break;
		NovaFlareAndroidFrameRecord frame;
		if (!novaflare_android_read_frame(framePointer, &frame)) break;
		if (frame.returnAddress == 0) break;
		novaflare_buffer_text(buffer, "frame_");
		novaflare_buffer_u64(buffer, (uint64_t)frameIndex);
		novaflare_buffer_char(buffer, 61);
		novaflare_buffer_hex(buffer, (uint64_t)frame.returnAddress);
		novaflare_buffer_char(buffer, 10);
		if (frame.previousFrame <= framePointer || frame.previousFrame - framePointer > 1024 * 1024) break;
		framePointer = frame.previousFrame;
	}
#endif
#elif defined(__arm__)
	ucontext_t* context = (ucontext_t*)rawContext;
	novaflare_buffer_key_text(buffer, "architecture", "arm");
	novaflare_buffer_key_hex(buffer, "pc", (uint64_t)context->uc_mcontext.arm_pc);
	novaflare_buffer_key_hex(buffer, "sp", (uint64_t)context->uc_mcontext.arm_sp);
	novaflare_buffer_key_hex(buffer, "lr", (uint64_t)context->uc_mcontext.arm_lr);
#elif defined(__x86_64__)
	ucontext_t* context = (ucontext_t*)rawContext;
	novaflare_buffer_key_text(buffer, "architecture", "x86_64");
	novaflare_buffer_key_hex(buffer, "rip", (uint64_t)context->uc_mcontext.gregs[REG_RIP]);
	novaflare_buffer_key_hex(buffer, "rsp", (uint64_t)context->uc_mcontext.gregs[REG_RSP]);
	novaflare_buffer_key_hex(buffer, "rbp", (uint64_t)context->uc_mcontext.gregs[REG_RBP]);
#elif defined(__i386__)
	ucontext_t* context = (ucontext_t*)rawContext;
	novaflare_buffer_key_text(buffer, "architecture", "x86");
	novaflare_buffer_key_hex(buffer, "eip", (uint64_t)context->uc_mcontext.gregs[REG_EIP]);
	novaflare_buffer_key_hex(buffer, "esp", (uint64_t)context->uc_mcontext.gregs[REG_ESP]);
	novaflare_buffer_key_hex(buffer, "ebp", (uint64_t)context->uc_mcontext.gregs[REG_EBP]);
#else
	novaflare_buffer_key_text(buffer, "architecture", "unknown");
#endif
}

static void novaflare_android_signal_handler(int signalNumber, siginfo_t* signalInfo, void* rawContext) {
	if (novaflare_android_handling_crash) _exit(128 + signalNumber);
	novaflare_android_handling_crash = 1;

	int reportFd = novaflare_android_pending_fd;
	if (reportFd < 0) {
		reportFd = open(
			"native-crash-emergency.txt",
			O_CREAT | O_WRONLY | O_TRUNC | O_CLOEXEC,
			0644);
	}

	NovaFlareNativeBuffer buffer = {
		novaflare_native_report_buffer,
		0,
		sizeof(novaflare_native_report_buffer)
	};
	buffer.data[0] = 0;
	struct timespec now;
	clock_gettime(CLOCK_REALTIME, &now);
	novaflare_buffer_key_text(&buffer, "format", "novaflare-native-crash-v1");
	novaflare_buffer_key_text(&buffer, "platform", "android");
	novaflare_buffer_key_text(&buffer, "commit", novaflare_native_commit);
	novaflare_buffer_key_u64(&buffer, "timestamp_seconds", (uint64_t)now.tv_sec);
	novaflare_buffer_key_u64(&buffer, "timestamp_nanoseconds", (uint64_t)now.tv_nsec);
	novaflare_buffer_key_u64(&buffer, "process_id", (uint64_t)getpid());
	novaflare_buffer_key_u64(&buffer, "thread_id", (uint64_t)novaflare_android_gettid());
	novaflare_buffer_key_text(&buffer, "signal_name", novaflare_android_signal_name(signalNumber));
	novaflare_buffer_key_u64(&buffer, "signal_number", (uint64_t)signalNumber);
	if (signalInfo != 0) {
		novaflare_buffer_key_u64(&buffer, "signal_code", (uint64_t)signalInfo->si_code);
		novaflare_buffer_key_hex(&buffer, "fault_address", (uint64_t)(uintptr_t)signalInfo->si_addr);
	}
	if (rawContext != 0) novaflare_android_append_context(&buffer, rawContext);
	novaflare_android_write_all(reportFd, buffer.data, buffer.length);

	static const char mapsHeader[] = "\\n[proc_self_maps]\\n";
	novaflare_android_write_all(reportFd, mapsHeader, sizeof(mapsHeader) - 1);
	int mapsFd = open("/proc/self/maps", O_RDONLY | O_CLOEXEC);
	if (mapsFd >= 0) {
		char mapsBuffer[4096];
		for (;;) {
			ssize_t count = read(mapsFd, mapsBuffer, sizeof(mapsBuffer));
			if (count > 0) {
				novaflare_android_write_all(reportFd, mapsBuffer, (size_t)count);
			} else if (count < 0 && errno == EINTR) {
				continue;
			} else {
				break;
			}
		}
		close(mapsFd);
	}

	if (reportFd >= 0) {
		fsync(reportFd);
		close(reportFd);
	}
	novaflare_android_pending_fd = -1;
	if (novaflare_android_pending_path[0] != 0 && novaflare_android_final_path[0] != 0) {
		rename(novaflare_android_pending_path, novaflare_android_final_path);
	}
	novaflare_android_notify_before_exit();
	novaflare_android_append_notification_status();

	struct sigaction action;
	memset(&action, 0, sizeof(action));
	action.sa_handler = SIG_DFL;
	sigemptyset(&action.sa_mask);
	sigaction(signalNumber, &action, 0);
#if defined(__NR_tgkill)
	syscall(__NR_tgkill, getpid(), novaflare_android_gettid(), signalNumber);
#else
	kill(getpid(), signalNumber);
#endif
	_exit(128 + signalNumber);
}

static void novaflare_android_install() {
	if (novaflare_android_installed) {
		novaflare_android_prepare_output();
		return;
	}
	novaflare_android_installed = 1;
	novaflare_android_start_notification_worker();

	stack_t alternateStack;
	memset(&alternateStack, 0, sizeof(alternateStack));
	alternateStack.ss_sp = novaflare_android_alt_stack_memory;
	alternateStack.ss_size = sizeof(novaflare_android_alt_stack_memory);
	alternateStack.ss_flags = 0;
	sigaltstack(&alternateStack, 0);

	struct sigaction action;
	memset(&action, 0, sizeof(action));
	action.sa_sigaction = novaflare_android_signal_handler;
	sigemptyset(&action.sa_mask);
	action.sa_flags = SA_SIGINFO | SA_ONSTACK;
	sigaction(SIGABRT, &action, 0);
	sigaction(SIGBUS, &action, 0);
	sigaction(SIGFPE, &action, 0);
	sigaction(SIGILL, &action, 0);
	sigaction(SIGSEGV, &action, 0);
	atexit(novaflare_android_cleanup_pending);
	novaflare_android_prepare_output();
}

#endif

static void novaflare_native_crash_install(const char* commit) {
	novaflare_copy_string(
		novaflare_native_commit,
		sizeof(novaflare_native_commit),
		commit);
#if defined(HX_WINDOWS)
	novaflare_windows_install();
#elif defined(ANDROID)
	novaflare_android_install();
#endif
}

static void novaflare_native_crash_force_test() {
	volatile int* invalidAddress = (volatile int*)0;
	*invalidAddress = 0x4e46;
}
')
#end
class NativeCrashHandler
{
	public static function init(commit:String):Void
	{
		#if (cpp && (windows || android))
		if (commit == null || commit.length == 0)
			commit = "unknown";
		untyped __cpp__('novaflare_native_crash_install({0}.utf8_str())', commit);
		refreshDirectory();

		#if native_crash_test
		// Opt-in diagnostic build hook. Production builds do not expose an
		// environment-controlled path that deliberately crashes the process.
		if (Sys.getEnv("NOVAFLARE_TEST_NATIVE_CRASH") == "1")
			untyped __cpp__('novaflare_native_crash_force_test()');
		#end
		#end
	}

	public static function refreshDirectory():Void
	{
		#if (cpp && (windows || android))
		var diagnosticRoot:String = Sys.getEnv("NOVAFLARE_DIAGNOSTIC_DIR");
		var crashDirectory:String = diagnosticRoot != null && diagnosticRoot.length > 0
			? Path.join([diagnosticRoot, "native-crash"])
			: Path.join([Sys.getCwd(), "crash"]);
		try
		{
			if (!FileSystem.exists(crashDirectory))
				FileSystem.createDirectory(crashDirectory);
		}
		catch (_:Dynamic) {}
		untyped __cpp__('novaflare_native_crash_set_directory({0}.utf8_str())', crashDirectory);
		#if android
		// Android pre-opens the report file so a corrupted allocator or stack
		// cannot prevent the fatal signal handler from recording the crash.
		untyped __cpp__('novaflare_android_prepare_output()');
		#if native_crash_test
		// Diagnostic APKs only: adb can place this one-shot marker in the
		// selected runtime folder after installation. The name and deliberate
		// crash are not compiled into production builds.
		var testMarker:String = Path.join([Sys.getCwd(), ".novaflare-native-crash-test"]);
		if (FileSystem.exists(testMarker))
		{
			try FileSystem.deleteFile(testMarker) catch (_:Dynamic) {}
			untyped __cpp__('novaflare_native_crash_force_test()');
		}
		#end
		#end
		#end
	}
}
