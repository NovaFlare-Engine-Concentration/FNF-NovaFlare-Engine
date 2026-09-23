package general.backend.device;

import lime.app.Application;
import lime.system.Display;
import lime.system.System;

#if (cpp && windows)
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows"/>
	<lib name="gdi32.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <windows.h>
#include <dwmapi.h>
#include <winuser.h>
#include <wingdi.h>
#include <string>
#include <stdio.h>

#define attributeDarkMode 20
#define attributeDarkModeFallback 19

#define attributeCaptionColor 34
#define attributeTextColor 35
#define attributeBorderColor 36

struct HandleData {
	DWORD pid = 0;
	HWND handle = 0;
};

BOOL CALLBACK findByPID(HWND handle, LPARAM lParam) {
	DWORD targetPID = ((HandleData*)lParam)->pid;
	DWORD curPID = 0;

	GetWindowThreadProcessId(handle, &curPID);
	if (targetPID != curPID || GetWindow(handle, GW_OWNER) != (HWND)0 || !IsWindowVisible(handle)) {
		return TRUE;
	}

	((HandleData*)lParam)->handle = handle;
	return FALSE;
}

HWND curHandle = 0;
void getHandle() {
	if (curHandle == (HWND)0) {
		HandleData data;
		data.pid = GetCurrentProcessId();
		EnumWindows(findByPID, (LPARAM)&data);
		curHandle = data.handle;
	}
}

void refreshWindowFrame() {
	if (curHandle != (HWND)0) {
		SetWindowPos(curHandle, 0, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
		RedrawWindow(curHandle, NULL, NULL, RDW_INVALIDATE | RDW_FRAME | RDW_UPDATENOW);
		UpdateWindow(curHandle);
	}
}

void forceWindowFocusRefreshNative() {
	if (curHandle != (HWND)0) {
		HWND foregroundHandle = GetForegroundWindow();
		DWORD currentThread = GetCurrentThreadId();
		DWORD foregroundThread = foregroundHandle != (HWND)0 ? GetWindowThreadProcessId(foregroundHandle, NULL) : 0;
		BOOL attachedInput = FALSE;

		if (foregroundThread != 0 && foregroundThread != currentThread) {
			attachedInput = AttachThreadInput(currentThread, foregroundThread, TRUE);
		}

		SendMessage(curHandle, WM_NCACTIVATE, FALSE, 0);
		refreshWindowFrame();
		Sleep(10);

		ShowWindow(curHandle, SW_SHOW);
		BringWindowToTop(curHandle);
		SetForegroundWindow(curHandle);
		SetActiveWindow(curHandle);
		SetFocus(curHandle);
		SendMessage(curHandle, WM_NCACTIVATE, TRUE, 0);
		refreshWindowFrame();

		if (attachedInput) {
			AttachThreadInput(currentThread, foregroundThread, FALSE);
		}
	}
}

// ____________________________________________________________________________
// Runtime title bar (caption) helpers.
//
// 隐藏标题栏时窗口外框（位置+尺寸）保持不变：客户端区域向上扩入原标题栏
// 空间，画面随之铺满；显示时客户端缩回。cachedBarHeight 缓存标题栏物理
// 高度（隐藏前测量），供 hover 唤出判定使用。
// ____________________________________________________________________________

int cachedBarHeight = 0;

void setWindowChromeNative(bool showCaption) {
	if (curHandle == (HWND)0) return;
	if (IsIconic(curHandle)) return; // 最小化时不动窗口框

	const LONG_PTR caption = WS_CAPTION;
	const LONG_PTR thickFrame = WS_THICKFRAME;
	LONG_PTR style = GetWindowLongPtr(curHandle, GWL_STYLE);
	bool hasCaption = (style & caption) == caption;
	bool toggling = (hasCaption != showCaption);
	if (!toggling) return;

	// WS_POPUP 表示 SDL 处于全屏或窗口本为无边框：禁止往上加标题栏
	if (showCaption && (style & WS_POPUP)) return;

	RECT wr;
	GetWindowRect(curHandle, &wr);
	if (hasCaption) {
		// 即将隐藏：先记录标题栏物理高度（含边框）
		RECT cr;
		GetClientRect(curHandle, &cr);
		int bar = (wr.bottom - wr.top) - (cr.bottom - cr.top);
		if (bar > 0) cachedBarHeight = bar;
	}

	if (showCaption) {
		style |= caption | thickFrame;
	} else {
		// 隐藏时连 resize 边框一起去掉：窗口顶部不再有非客户区，
		// 鼠标贴顶时不会变成上下箭头，游戏也能收到顶部区域的鼠标事件
		style &= ~(caption | thickFrame);
	}

	SetWindowLongPtr(curHandle, GWL_STYLE, style);
	// 外框保持不变 → 客户端随标题栏伸缩（去标题栏 = 客户端向上扩一条）
	SetWindowPos(curHandle, (HWND)0, wr.left, wr.top,
		wr.right - wr.left, wr.bottom - wr.top,
		SWP_FRAMECHANGED | SWP_NOZORDER | SWP_NOACTIVATE);
	RedrawWindow(curHandle, NULL, NULL, RDW_INVALIDATE | RDW_FRAME | RDW_UPDATENOW);
	UpdateWindow(curHandle);
}

bool cursorInTopStripNative(int stripPx) {
	if (curHandle == (HWND)0) return false;
	POINT pt;
	GetCursorPos(&pt);
	if (WindowFromPoint(pt) != curHandle) return false;
	RECT rc;
	GetWindowRect(curHandle, &rc);
	if (pt.x < rc.left || pt.x >= rc.right) return false;
	return (pt.y >= rc.top && pt.y <= rc.top + stripPx);
}

bool cursorOverWindowNative() {
	if (curHandle == (HWND)0) return false;
	POINT pt;
	GetCursorPos(&pt);
	return WindowFromPoint(pt) == curHandle;
}

int cursorClientXNative() {
	if (curHandle == (HWND)0) return -1;
	POINT pt;
	GetCursorPos(&pt);
	if (WindowFromPoint(pt) != curHandle) return -1;
	POINT origin;
	origin.x = 0;
	origin.y = 0;
	ClientToScreen(curHandle, &origin);
	return pt.x - origin.x;
}

int cursorClientYNative() {
	if (curHandle == (HWND)0) return -1;
	POINT pt;
	GetCursorPos(&pt);
	if (WindowFromPoint(pt) != curHandle) return -1;
	POINT origin;
	origin.x = 0;
	origin.y = 0;
	ClientToScreen(curHandle, &origin);
	return pt.y - origin.y;
}

int windowClientWNative() {
	if (curHandle == (HWND)0) return 0;
	RECT c;
	GetClientRect(curHandle, &c);
	return c.right - c.left;
}

int windowClientHNative() {
	if (curHandle == (HWND)0) return 0;
	RECT c;
	GetClientRect(curHandle, &c);
	return c.bottom - c.top;
}

int windowBarHeightNative() {
	return cachedBarHeight;
}

int windowXNative() {
	if (curHandle == (HWND)0) return 0;
	RECT r;
	GetWindowRect(curHandle, &r);
	return r.left;
}

int windowYNative() {
	if (curHandle == (HWND)0) return 0;
	RECT r;
	GetWindowRect(curHandle, &r);
	return r.top;
}

int cursorXNative() {
	POINT pt;
	GetCursorPos(&pt);
	return pt.x;
}

int cursorYNative() {
	POINT pt;
	GetCursorPos(&pt);
	return pt.y;
}

bool windowMaximizedNative() {
	return curHandle != (HWND)0 && IsZoomed(curHandle) != FALSE;
}

void windowMinimizeNative() {
	if (curHandle != (HWND)0) ShowWindow(curHandle, SW_MINIMIZE);
}

// —— 直接最大化 / 还原（无自绘动画）——
// 系统 ShowWindow 会自行维护 rcNormalPosition（最大化前矩形），还原即
// 回到最大化前的位置与大小；不经逐帧 SetWindowPos，就没有 resize 事件
// 风暴把 flixel 视口带乱。
void windowMaximizeDirectNative() {
	if (curHandle == (HWND)0 || IsZoomed(curHandle)) return;
	ShowWindow(curHandle, SW_MAXIMIZE);
}

void windowRestoreDirectNative() {
	if (curHandle == (HWND)0 || !IsZoomed(curHandle)) return;
	ShowWindow(curHandle, SW_RESTORE);
}

void windowToggleMaximizeNative() {
	if (curHandle != (HWND)0) ShowWindow(curHandle, IsZoomed(curHandle) ? SW_RESTORE : SW_MAXIMIZE);
}

void windowCloseNative() {
	if (curHandle != (HWND)0) PostMessage(curHandle, WM_CLOSE, 0, 0);
}

// —— 引擎自绘标题栏用的拖拽支持（SDL 会吞掉 WM_NCLBUTTONDOWN，无法用
//    系统 HTCAPTION 拖拽，这里用捕获 + 手动移动实现）——
bool windowDraggingNative = false;
int dragStartCursorX = 0, dragStartCursorY = 0;
int dragStartWindowX = 0, dragStartWindowY = 0;

// 前向声明（定义在文件后面，beginWindowDragNative 需要用到）
int windowModeNative();
extern RECT fsWindowedRect;
extern bool hasFsWindowedRect;

void beginWindowDragNative() {
	if (curHandle == (HWND)0 || windowDraggingNative) return;

	// 物理左键已经松开（快速甩动：按下→移动→松开 全发生在同一帧内）→ 不启动
	// 拖动。否则拖动状态会被挂起一帧、又在下一帧 updateWindowDragNative 里
	// 因"左键已松开"立刻结束，表现为"拖不动"。
	if ((GetAsyncKeyState(VK_LBUTTON) & 0x8000) == 0) return;

	// 自管全屏/最大化模式下拖动窗口：先还原到进入前尺寸
	// （类似系统最大化窗口拖动时自动还原的行为）
	// 自管模式下窗口始终是"普通窗口"状态，拖动不会自动还原尺寸
	int mode = windowModeNative();
	if (mode != 0 && hasFsWindowedRect) {
		int restoreW = fsWindowedRect.right - fsWindowedRect.left;
		int restoreH = fsWindowedRect.bottom - fsWindowedRect.top;
		POINT pt0;
		GetCursorPos(&pt0);
		// 将窗口位置调整为鼠标位于标题栏区域（窗口顶部约 15px）
		int newX = pt0.x - restoreW / 2;
		int newY = pt0.y - 15;
		SetWindowPos(curHandle, (HWND)0, newX, newY, restoreW, restoreH,
			SWP_NOZORDER | SWP_NOACTIVATE);
		hasFsWindowedRect = false;
	}

	windowDraggingNative = true;
	POINT pt;
	GetCursorPos(&pt);
	RECT r;
	GetWindowRect(curHandle, &r);
	dragStartCursorX = pt.x;
	dragStartCursorY = pt.y;
	dragStartWindowX = r.left;
	dragStartWindowY = r.top;
	SetCapture(curHandle);
}

void endWindowDragNative() {
	if (!windowDraggingNative) return;
	windowDraggingNative = false;
	if (curHandle != (HWND)0 && GetCapture() == curHandle)
		ReleaseCapture();
}

void updateWindowDragNative() {
	if (!windowDraggingNative || curHandle == (HWND)0) return;
	// 物理左键已松开（即使游戏没收到 mouse up）→ 结束拖动
	if ((GetAsyncKeyState(VK_LBUTTON) & 0x8000) == 0) {
		endWindowDragNative();
		return;
	}
	POINT pt;
	GetCursorPos(&pt);
	int nx = dragStartWindowX + (pt.x - dragStartCursorX);
	int ny = dragStartWindowY + (pt.y - dragStartCursorY);
	SetWindowPos(curHandle, (HWND)0, nx, ny, 0, 0,
		SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
}

bool windowDraggingNativeState() {
	return windowDraggingNative;
}

// —— 窗口矩形动画（最大化 / 还原 / 最小化的缩放动效）——
RECT animFromRect;
RECT animToRect;
double animTime = -1;
double animDuration = 0.2;
int animFollowAction = 0; // 动画完成后执行：1=最大化 2=还原 3=最小化

// 最大化动画前的窗口矩形（还原动画的目标）。
// 注意：不能用系统 rcNormalPosition —— 最大化动画期间窗口仍处于 normal
// 状态，逐步 SetWindowPos 到工作区大小会把 rcNormalPosition 污染成“全屏”，
// 导致还原后窗口仍是全屏大小。
RECT restoreTargetRect;
bool hasRestoreTargetRect = false;

void startRectAnim(int tx, int ty, int tw, int th, double seconds, int action) {
	if (curHandle == (HWND)0) return;
	GetWindowRect(curHandle, &animFromRect);
	animToRect.left = tx;
	animToRect.top = ty;
	animToRect.right = tx + tw;
	animToRect.bottom = ty + th;
	animTime = 0;
	animDuration = seconds > 0.05 ? seconds : 0.2;
	animFollowAction = action;
}

void beginMaximizeAnimNative() {
	if (curHandle == (HWND)0) return;
	// 记录最大化前的窗口矩形，供还原动画使用
	GetWindowRect(curHandle, &restoreTargetRect);
	hasRestoreTargetRect = true;
	HMONITOR mon = MonitorFromWindow(curHandle, MONITOR_DEFAULTTONEAREST);
	MONITORINFO mi;
	mi.cbSize = sizeof(MONITORINFO);
	if (!GetMonitorInfo(mon, &mi)) return;
	startRectAnim(mi.rcWork.left, mi.rcWork.top, mi.rcWork.right - mi.rcWork.left,
		mi.rcWork.bottom - mi.rcWork.top, 0.18, 1);
}

void beginRestoreAnimNative() {
	if (curHandle == (HWND)0) return;
	RECT n;
	if (hasRestoreTargetRect && restoreTargetRect.right > restoreTargetRect.left
		&& restoreTargetRect.bottom > restoreTargetRect.top) {
		n = restoreTargetRect;
	} else {
		WINDOWPLACEMENT wp;
		wp.length = sizeof(WINDOWPLACEMENT);
		if (!GetWindowPlacement(curHandle, &wp)) return;
		n = wp.rcNormalPosition;
	}
	startRectAnim(n.left, n.top, n.right - n.left, n.bottom - n.top, 0.18, 2);
}

void beginMinimizeAnimNative() {
	if (curHandle == (HWND)0) return;
	// 缩向任务栏：窗口缩小并滑到工作区底部中央（任务栏上方），随后系统最小化
	HMONITOR mon = MonitorFromWindow(curHandle, MONITOR_DEFAULTTONEAREST);
	MONITORINFO mi;
	mi.cbSize = sizeof(MONITORINFO);
	if (!GetMonitorInfo(mon, &mi)) return;
	int cw = 220;
	int ch = 28;
	int cx = mi.rcWork.left + (mi.rcWork.right - mi.rcWork.left - cw) / 2;
	int cy = mi.rcWork.bottom - ch;
	startRectAnim(cx, cy, cw, ch, 0.16, 3);
}

bool updateWindowAnimNative(double dt) {
	if (curHandle == (HWND)0) { animTime = -1; return true; }
	if (animTime < 0) return true;
	animTime += dt;
	double t = animTime / animDuration;

	if (t >= 1) {
		// 收尾：定位到目标并执行后续动作（cpp 自完结，不依赖 haxe 回调）
		int x = animToRect.left;
		int y = animToRect.top;
		int w = animToRect.right - animToRect.left;
		int h = animToRect.bottom - animToRect.top;
		SetWindowPos(curHandle, (HWND)0, x, y, w, h, SWP_NOZORDER | SWP_NOACTIVATE);
		animTime = -1;
		int action = animFollowAction;
		animFollowAction = 0;
		if (action == 1) ShowWindow(curHandle, SW_MAXIMIZE);
		else if (action == 2) ShowWindow(curHandle, SW_RESTORE);
		else if (action == 3) ShowWindow(curHandle, SW_MINIMIZE);
		return true;
	}

	// easeOutCubic
	double u = 1 - t;
	double e = 1 - u * u * u;
	int x = animFromRect.left + (int)((animToRect.left - animFromRect.left) * e);
	int y = animFromRect.top + (int)((animToRect.top - animFromRect.top) * e);
	int w = (int)((animToRect.right - animToRect.left) * e) + (int)((animFromRect.right - animFromRect.left) * (1 - e));
	int h = (int)((animToRect.bottom - animToRect.top) * e) + (int)((animFromRect.bottom - animFromRect.top) * (1 - e));
	SetWindowPos(curHandle, (HWND)0, x, y, w, h, SWP_NOZORDER | SWP_NOACTIVATE);
	return false;
}

bool windowAnimRunningNative() {
	return animTime >= 0 && animTime < animDuration;
}

void finishWindowAnimNative() {
	// 动画已在 updateWindowAnimNative 内自完结；这里只清理状态
	animTime = -1;
	animFollowAction = 0;
}

// —— 窗口淡出（关闭动画）：整个窗口的透明度，而非画面内容 ——
// WS_EX_LAYERED + SetLayeredWindowAttributes 是整窗合成透明度；
// DWM 合成开启时对 OpenGL 内容同样生效。windowAlphaActive 避免反复
// 增删 layered 样式造成的闪屏。
bool windowAlphaActive = false;

void setWindowAlphaNative(int alpha) {
	if (curHandle == (HWND)0) return;
	if (alpha >= 255) {
		// 淡出未开始（或已完成恢复）时不动窗口；淡出中保持 255 帧不变
		if (!windowAlphaActive) return;
		SetLayeredWindowAttributes(curHandle, 0, 255, LWA_ALPHA);
		return;
	}
	LONG_PTR ex = GetWindowLongPtr(curHandle, GWL_EXSTYLE);
	if (!(ex & WS_EX_LAYERED)) {
		SetWindowLongPtr(curHandle, GWL_EXSTYLE, ex | WS_EX_LAYERED);
		windowAlphaActive = true;
	}
	SetLayeredWindowAttributes(curHandle, 0, (BYTE)(alpha < 0 ? 0 : (alpha > 255 ? 255 : alpha)), LWA_ALPHA);
}

void resetWindowAlphaNative() {
	if (curHandle == (HWND)0) return;
	if (!windowAlphaActive) return;
	windowAlphaActive = false;
	LONG_PTR ex = GetWindowLongPtr(curHandle, GWL_EXSTYLE);
	if (ex & WS_EX_LAYERED) {
		SetWindowLongPtr(curHandle, GWL_EXSTYLE, ex & ~WS_EX_LAYERED);
		RECT r;
		GetWindowRect(curHandle, &r);
		SetWindowPos(curHandle, (HWND)0, r.left, r.top, r.right - r.left, r.bottom - r.top,
			SWP_FRAMECHANGED | SWP_NOZORDER | SWP_NOACTIVATE);
	}
}

// 分辨率更改确认弹窗：系统 MessageBox（独立线程，不阻塞游戏）。
// 状态机：0=无 1=运行中 2=撤销(否) 3=应用(是)/直接关闭/超时自动应用。
// 文本直接取 ::String.wchar_str()（UTF-16），杜绝编码猜测导致的乱码。
// ____________________________________________________________________________

volatile int resDlgState = 0;
volatile bool resDlgThreadRunning = false;
std::wstring resDlgMsg = L"";

void resDlgCloseMessageBox() {
	if (curHandle == (HWND)0) return;
	// MessageBox 对话框是游戏窗口的 popup：用 GetLastActivePopup 找到它
	HWND pop = GetLastActivePopup(curHandle);
	if (pop != 0 && pop != curHandle)
		PostMessage(pop, WM_CLOSE, 0, 0);
}

DWORD WINAPI resMsgThread(LPVOID param) {
	UINT flags = MB_YESNO | MB_ICONINFORMATION | MB_TOPMOST | MB_SETFOREGROUND | MB_DEFBUTTON1;
	int r = MessageBoxW(curHandle != 0 ? curHandle : 0, resDlgMsg.c_str(), L"NovaFlare Engine", flags);
	if (resDlgState == 1)
		resDlgState = (r == IDNO) ? 2 : 3; // 是=应用 否=撤销；WM_CLOSE/异常=应用
	resDlgThreadRunning = false;
	return 0;
}

void showResDialogNative(::String text) {
	// 旧弹窗还在：按“应用”关闭并等线程退出，避免竞态
	if (resDlgState == 1 || resDlgThreadRunning) {
		resDlgState = 3;
		resDlgCloseMessageBox();
		for (int i = 0; i < 200 && resDlgThreadRunning; i++)
			Sleep(10);
	}
	const wchar_t* wtext = text.wchar_str();
	resDlgMsg = std::wstring(wtext != 0 ? wtext : L"");
	resDlgState = 1;
	resDlgThreadRunning = true;
	CreateThread(0, 0, resMsgThread, 0, 0, 0);
}

int resDialogStateNative() {
	return resDlgState;
}

void resDialogClearNative() {
	resDlgState = 0;
}

void closeResDialogNative(int result) {
	if (resDlgState != 1 && !resDlgThreadRunning) return;
	if (result == 2 || result == 3)
		resDlgState = result;
	resDlgCloseMessageBox();
}

// —— 默认窗口矩形（“恢复默认窗口大小”按钮用）——
RECT defaultWindowRect;
bool hasDefaultWindowRect = false;

void captureDefaultWindowRectNative() {
	if (curHandle == (HWND)0) return;
	GetWindowRect(curHandle, &defaultWindowRect);
	hasDefaultWindowRect = true;
}

// —— 进入全屏前的完整窗口矩形（退出全屏后原样恢复，位置+大小）——
RECT fsWindowedRect;
bool hasFsWindowedRect = false;

void captureWindowedRectNative() {
	if (curHandle == (HWND)0) return;
	GetWindowRect(curHandle, &fsWindowedRect);
	hasFsWindowedRect = true;
}

void restoreWindowedRectNative() {
	if (curHandle == (HWND)0 || !hasFsWindowedRect) return;
	if (IsZoomed(curHandle))
		ShowWindow(curHandle, SW_RESTORE);
	SetWindowPos(curHandle, (HWND)0, fsWindowedRect.left, fsWindowedRect.top,
		fsWindowedRect.right - fsWindowedRect.left, fsWindowedRect.bottom - fsWindowedRect.top,
		SWP_NOZORDER | SWP_NOACTIVATE);
}

// —— 自管窗口模式（激进方案：不碰 SDL 全屏/系统最大化）——
// 最大化 / 全屏 / 还原全部用 SetWindowPos 一步到位：
//   mode 1 = 最大化（工作区，任务栏可见）
//   mode 2 = 全屏（铺满整个显示器，盖住任务栏）
//   mode 0 = 还原（回到进入 1/2 前的矩形）
// 窗口始终保持“普通窗口”状态，SDL 只会看到普通 resize 事件，
// flixel 视口由轮询对账兜底，彻底消除 SDL 全屏状态机的各种错乱。
int windowModeNative() {
	if (curHandle == (HWND)0) return 0;
	HMONITOR mon = MonitorFromWindow(curHandle, MONITOR_DEFAULTTONEAREST);
	MONITORINFO mi;
	mi.cbSize = sizeof(MONITORINFO);
	if (!GetMonitorInfo(mon, &mi)) return 0;
	// 用客户区尺寸判断，而不是外框：
	// 自管模式下 SetWindowPos 设置的是外框（含边框），外框尺寸可能与目标不一致，
	// 但客户区才是游戏实际渲染区域，客户区铺满 = 全屏/最大化。
	RECT cr;
	GetClientRect(curHandle, &cr);
	int cw = cr.right - cr.left;
	int ch = cr.bottom - cr.top;
	// 客户区左上角的屏幕坐标
	POINT ctl;
	ctl.x = 0; ctl.y = 0;
	ClientToScreen(curHandle, &ctl);
	int monW = mi.rcMonitor.right - mi.rcMonitor.left;
	int monH = mi.rcMonitor.bottom - mi.rcMonitor.top;
	int workW = mi.rcWork.right - mi.rcWork.left;
	int workH = mi.rcWork.bottom - mi.rcWork.top;
	// 允许 ±2px 误差（DWM 边框/舍入）
	const int TOL = 2;
	if (ctl.x <= mi.rcMonitor.left + TOL && ctl.y <= mi.rcMonitor.top + TOL
		&& abs(cw - monW) <= TOL && abs(ch - monH) <= TOL)
		return 2;
	if (ctl.x <= mi.rcWork.left + TOL && ctl.y <= mi.rcWork.top + TOL
		&& abs(cw - workW) <= TOL && abs(ch - workH) <= TOL)
		return 1;
	return 0;
}

void windowApplyModeNative(int mode) {
	if (curHandle == (HWND)0) return;
	if (mode == 0) {
		restoreWindowedRectNative();
		return;
	}
	int curMode = windowModeNative();
	if (curMode == mode) return;
	// 记录当前窗口矩形，供还原使用
	GetWindowRect(curHandle, &fsWindowedRect);
	hasFsWindowedRect = true;
	HMONITOR mon = MonitorFromWindow(curHandle, MONITOR_DEFAULTTONEAREST);
	MONITORINFO mi;
	mi.cbSize = sizeof(MONITORINFO);
	if (!GetMonitorInfo(mon, &mi)) return;
	RECT target = (mode == 1) ? mi.rcWork : mi.rcMonitor;
	int targetW = target.right - target.left;
	int targetH = target.bottom - target.top;
	// 计算当前边框厚度（外框尺寸 - 客户区尺寸），SetWindowPos 设置的是外框，
	// 必须加上边框差值才能保证最终客户区正好等于目标大小（全屏铺满无裁切）。
	RECT curWr, curCr;
	GetWindowRect(curHandle, &curWr);
	GetClientRect(curHandle, &curCr);
	int frameW = (curWr.right - curWr.left) - (curCr.right - curCr.left);
	int frameH = (curWr.bottom - curWr.top) - (curCr.bottom - curCr.top);
	if (frameW < 0) frameW = 0;
	if (frameH < 0) frameH = 0;
	SetWindowPos(curHandle, (HWND)0, target.left, target.top,
		targetW + frameW, targetH + frameH,
		SWP_NOZORDER | SWP_NOACTIVATE);
}

void windowRestoreDefaultNative() {
	if (curHandle == (HWND)0) return;
	if (IsZoomed(curHandle))
		ShowWindow(curHandle, SW_RESTORE);
	RECT target;
	if (hasDefaultWindowRect) {
		target = defaultWindowRect;
	} else {
		// 兜底：主显示器工作区 0.7 比例、1280x720 居中
		HMONITOR mon = MonitorFromWindow(curHandle, MONITOR_DEFAULTTONEAREST);
		MONITORINFO mi;
		mi.cbSize = sizeof(MONITORINFO);
		if (!GetMonitorInfo(mon, &mi)) return;
		int cw = (int)((mi.rcWork.right - mi.rcWork.left) * 0.7);
		int ch = (int)(cw * 9 / 16);
		target.left = mi.rcWork.left + ((mi.rcWork.right - mi.rcWork.left) - cw) / 2;
		target.top = mi.rcWork.top + ((mi.rcWork.bottom - mi.rcWork.top) - ch) / 2;
		target.right = target.left + cw;
		target.bottom = target.top + ch;
	}
	SetWindowPos(curHandle, (HWND)0, target.left, target.top,
		target.right - target.left, target.bottom - target.top,
		SWP_NOZORDER | SWP_NOACTIVATE);
}

void windowSetClientSizeNative(int cw, int ch) {
	if (curHandle == (HWND)0 || cw <= 0 || ch <= 0) return;
	if (IsZoomed(curHandle))
		ShowWindow(curHandle, SW_RESTORE);
	RECT cur;
	GetWindowRect(curHandle, &cur);
	RECT cli;
	GetClientRect(curHandle, &cli);
	int frameW = (cur.right - cur.left) - (cli.right - cli.left);
	int frameH = (cur.bottom - cur.top) - (cli.bottom - cli.top);
	SetWindowPos(curHandle, (HWND)0, cur.left, cur.top, cw + frameW, ch + frameH,
		SWP_NOZORDER | SWP_NOACTIVATE);
}
')
#end
class Native
{
	public static function __init__():Void
	{
		registerDPIAware();
	}

	public static function registerDPIAware():Void
	{
		#if (cpp && windows)
		// DPI Scaling fix for windows
		// this shouldn't be needed for other systems
		// Credit to YoshiCrafter29 for finding this function
		untyped __cpp__('
			SetProcessDPIAware();	
			#ifdef DPI_AWARENESS_CONTEXT
			SetProcessDpiAwarenessContext(
				#ifdef DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				#else
				DPI_AWARENESS_CONTEXT_SYSTEM_AWARE
				#endif
			);
			#endif
		');
		#end
	}

	private static var fixedScaling:Bool = false;

	/** fixScaling 计算的目标客户区尺寸（隐藏系统标题栏后用它恢复窗口大小，
	 *  因为 SDL 初始窗口把 1280x720 当作“客户区”创建出 1296x759 的外框，
	 *  隐藏标题栏后客户区会扩成整个外框）。*/
	public static var defaultClientW:Int = 0;
	public static var defaultClientH:Int = 0;

	public static function fixScaling():Void
	{
		if (fixedScaling)
			return;
		fixedScaling = true;

		#if (cpp && windows)
		final display:Null<Display> = System.getDisplay(0);
		if (display != null)
		{
			var dpiScale:Float = display.dpi / 96;
			final cfgW:Float = @:privateAccess Main.gameConfig.width;
			final cfgH:Float = @:privateAccess Main.gameConfig.height;
			final targetRatio:Float = 0.7;
			final targetW:Float = display.bounds.width * targetRatio;
			final targetH:Float = display.bounds.height * targetRatio;
			final maxScale:Float = Math.min(targetW / cfgW, targetH / cfgH);
			if (dpiScale > maxScale) dpiScale = maxScale;

			if (Main.nativeResRequested())
			{
				// 「屏幕原生分辨率创建」实验：窗口直接铺满屏幕，
				// 让 OpenFL 的舞台/后缓冲从一开始就是屏幕分辨率。
				defaultClientW = Std.int(display.bounds.width);
				defaultClientH = Std.int(display.bounds.height);
			}
			else
			{
				defaultClientW = Std.int(cfgW * dpiScale);
				defaultClientH = Std.int(cfgH * dpiScale);
			}
			@:privateAccess Application.current.window.width = defaultClientW;
			@:privateAccess Application.current.window.height = defaultClientH;

			Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
			Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
		}

		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				HDC curHDC = GetDC(curHandle);
				RECT curRect;
				GetClientRect(curHandle, &curRect);
				FillRect(curHDC, &curRect, (HBRUSH)GetStockObject(BLACK_BRUSH));
				ReleaseDC(curHandle, curHDC);
			}
		');

		// 记录默认窗口矩形（“恢复默认窗口大小”按钮使用）
		captureDefaultWindowRect();
		#end
	}

	/**
	 * Enables or disables dark mode support for the title bar.
	 * Only works on Windows.
	 * 
	 * @param enable Whether to enable or disable dark mode support.
	 * @param instant Whether to skip the transition tween.
	 */
	public static function setWindowDarkMode(enable:Bool = true, instant:Bool = false):Void
	{
		#if (cpp && windows)
		var success:Bool = false;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const BOOL darkMode = enable ? TRUE : FALSE;
				if (
					S_OK == DwmSetWindowAttribute(curHandle, attributeDarkMode, (LPCVOID)&darkMode, (DWORD)sizeof(darkMode)) ||
					S_OK == DwmSetWindowAttribute(curHandle, attributeDarkModeFallback, (LPCVOID)&darkMode, (DWORD)sizeof(darkMode))
				) {
					success = true;
				}

				refreshWindowFrame();
			}
		');

		if (instant && success)
		{
			final curBarColor:Null<FlxColor> = windowBarColor;
			windowBarColor = FlxColor.BLACK;
			windowBarColor = curBarColor;
		}
		#end
	}

	public static function applyStartupDarkMode():Void
	{
		#if (cpp && windows)
		setWindowDarkMode(true, true);
		windowBarColor = FlxColor.BLACK;
		windowTextColor = FlxColor.WHITE;
		windowBorderColor = FlxColor.BLACK;

		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				forceWindowFocusRefreshNative();
			}
		');
		#end
	}

	/**
	 * The color of the window title bar. If `null`, the default is used.
	 * Only works on Windows.
	 */
	public static var windowBarColor(default, set):Null<FlxColor> = null;

	public static function set_windowBarColor(value:Null<FlxColor>):Null<FlxColor>
	{
		#if (cpp && windows)
		final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const COLORREF targetColor = (COLORREF)intColor;
				DwmSetWindowAttribute(curHandle, attributeCaptionColor, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor));
				refreshWindowFrame();
			}
		');
		#end

		return windowBarColor = value;
	}

	/**
	 * The color of the window title bar text. If `null`, the default is used.
	 * Only works on Windows.
	 */
	public static var windowTextColor(default, set):Null<FlxColor> = null;

	public static function set_windowTextColor(value:Null<FlxColor>):Null<FlxColor>
	{
		#if (cpp && windows)
		final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const COLORREF targetColor = (COLORREF)intColor;
				DwmSetWindowAttribute(curHandle, attributeTextColor, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor));
				refreshWindowFrame();
			}
		');
		#end

		return windowTextColor = value;
	}

	/**
	 * The color of the window border. If `null`, the default is used.
	 * Only works on Windows.
	 */
	public static var windowBorderColor(default, set):Null<FlxColor> = null;

	public static function set_windowBorderColor(value:Null<FlxColor>):Null<FlxColor>
	{
		#if (cpp && windows)
		final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
		untyped __cpp__('
			getHandle();
			if (curHandle != (HWND)0) {
				const COLORREF targetColor = (COLORREF)intColor;
				DwmSetWindowAttribute(curHandle, attributeBorderColor, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor));
				refreshWindowFrame();
			}
		');
		#end

		return windowBorderColor = value;
	}

	// __________________________________________________________________________
	// Native window chrome primitives (used by WindowChromeManager).
	//
	// 沉浸式界面（StoryMode / 加载 / 游玩 / 编辑器）隐藏系统标题栏。隐藏时
	// 窗口外框（位置 + 尺寸）保持不变，客户端区域向上扩入原标题栏空间；
	// WindowChromeManager + ViewportScaleMode 再把游戏逻辑视口同步扩展，
	// 使画面满幅铺满整个窗口（无黑边、无拉伸）。
	// ____________________________________________________________________________
	/**
	 * Physical height of the native title bar (incl. frame), in px.
	 * Measured right before the bar is hidden; 0 if never measured yet.
	 */
	public static function titleBarHeightPx():Int
	{
		#if (cpp && windows)
		return untyped __cpp__('windowBarHeightNative()');
		#else
		return 0;
		#end
	}

	/** Current client area width in physical pixels. */
	public static function clientWidth():Int
	{
		#if (cpp && windows)
		return untyped __cpp__('windowClientWNative()');
		#else
		return 0;
		#end
	}

	/** Current client area height in physical pixels. */
	public static function clientHeight():Int
	{
		#if (cpp && windows)
		return untyped __cpp__('windowClientHNative()');
		#else
		return 0;
		#end
	}

	/**
	 * True while the cursor sits inside the top `stripPx` physical pixels of
	 * this window. Used for the "mouse near the top edge reveals the bar"
	 * behaviour.
	 */
	public static function cursorInTopStrip(stripPx:Int):Bool
	{
		#if (cpp && windows)
		return untyped __cpp__('cursorInTopStripNative(stripPx)');
		#else
		return false;
		#end
	}

	/** True while the cursor is physically over this window. */
	public static function cursorOverWindow():Bool
	{
		#if (cpp && windows)
		return untyped __cpp__('cursorOverWindowNative()');
		#else
		return false;
		#end
	}

	/**
	 * Cursor position relative to the client area origin (physical px).
	 * Returns -1 when the cursor is not over this window.
	 */
	public static function cursorClientX():Int
	{
		#if (cpp && windows)
		return untyped __cpp__('cursorClientXNative()');
		#else
		return -1;
		#end
	}

	public static function cursorClientY():Int
	{
		#if (cpp && windows)
		return untyped __cpp__('cursorClientYNative()');
		#else
		return -1;
		#end
	}

	public static function windowIsMaximized():Bool
	{
		#if (cpp && windows)
		return untyped __cpp__('windowModeNative() == 1');
		#else
		return false;
		#end
	}

	/** 自管窗口模式：0=普通 1=最大化（工作区） 2=全屏（整显示器）。 */
	public static function windowMode():Int
	{
		#if (cpp && windows)
		return untyped __cpp__('windowModeNative()');
		#else
		return 0;
		#end
	}

	/** 窗口模式切换：0=还原 1=最大化 2=全屏。
	 *
	 * 全屏走 SDL 正规 fullscreen（lime Window.fullscreen →
	 * SDL_SetWindowFullscreen DESKTOP）：SDL 自己管理窗口尺寸与事件/渲染链，
	 * 避免外部 SetWindowPos 直改窗口导致 OpenGL 呈现损坏（画面停在旧尺寸、
	 * 条按钮错位）。最大化走系统 ShowWindow（同为 SDL 正规事件链）。
	 * 还原：先退 SDL 全屏 / 系统最大化，再用进入前记录的矩形兜底强制恢复。
	 */
	public static function windowApplyMode(mode:Int):Void
	{
		#if (cpp && windows)
		var cur:Int = windowMode();
		if (mode == cur)
			return;
		var win:lime.ui.Window = (lime.app.Application.current != null) ? lime.app.Application.current.window : null;
		if (win == null)
			return;

		if (mode == 2)
		{
			// 进全屏：先还原成普通窗口（避免系统最大化残留污染 SDL 的还原矩形），
			// 记录当前窗口矩形（退出后兜底恢复），再走 SDL 正规全屏。
			untyped __cpp__('if (IsZoomed(curHandle)) ShowWindow(curHandle, SW_RESTORE);');
			captureWindowedRect();
			win.fullscreen = true;
		}
		else if (mode == 1)
		{
			// 最大化：系统 ShowWindow（SDL 正规事件链，渲染可靠）
			captureWindowedRect();
			untyped __cpp__('ShowWindow(curHandle, SW_MAXIMIZE);');
		}
		else
		{
			// 还原：先退 SDL 全屏（若在），再退系统最大化，最后强制恢复进入前矩形
			if (cur == 2)
				win.fullscreen = false;
			untyped __cpp__('if (IsZoomed(curHandle)) ShowWindow(curHandle, SW_RESTORE);');
			restoreWindowedRect();
		}
		#end
	}

	public static function windowMinimize():Void
	{
		#if (cpp && windows)
		untyped __cpp__('windowMinimizeNative();');
		#end
	}

	/** 直接最大化（系统一步到位，无自绘动画）。 */
	public static function windowMaximizeDirect():Void
	{
		#if (cpp && windows)
		untyped __cpp__('windowMaximizeDirectNative();');
		#end
	}

	/** 直接还原到最大化前的位置与大小（系统一步到位，无自绘动画）。 */
	public static function windowRestoreDirect():Void
	{
		#if (cpp && windows)
		untyped __cpp__('windowRestoreDirectNative();');
		#end
	}

	public static function windowToggleMaximize():Void
	{
		#if (cpp && windows)
		untyped __cpp__('windowToggleMaximizeNative();');
		#end
	}

	public static function windowClose():Void
	{
		#if (cpp && windows)
		untyped __cpp__('windowCloseNative();');
		#end
	}

	/** Window drag helpers for the engine-drawn title bar. */
	public static function windowDragBegin():Void
	{
		#if (cpp && windows)
		untyped __cpp__('beginWindowDragNative();');
		#end
	}

	public static function windowDragUpdate():Void
	{
		#if (cpp && windows)
		untyped __cpp__('updateWindowDragNative();');
		#end
	}

	public static function windowDragEnd():Void
	{
		#if (cpp && windows)
		untyped __cpp__('endWindowDragNative();');
		#end
	}

	public static function windowDragging():Bool
	{
		#if (cpp && windows)
		return untyped __cpp__('windowDraggingNativeState()');
		#else
		return false;
		#end
	}

	/** 窗口缩放动效：最大化 / 还原 / 最小化。每帧调 `windowAnimUpdate` 驱动。 */
	public static function windowAnimMaximize():Void
	{
		#if (cpp && windows)
		untyped __cpp__('beginMaximizeAnimNative();');
		#end
	}

	public static function windowAnimRestore():Void
	{
		#if (cpp && windows)
		untyped __cpp__('beginRestoreAnimNative();');
		#end
	}

	public static function windowAnimMinimize():Void
	{
		#if (cpp && windows)
		untyped __cpp__('beginMinimizeAnimNative();');
		#end
	}

	/** 推进窗口动画；返回 true 表示动画已完成（应调用 windowAnimFinish）。 */
	public static function windowAnimUpdate(dt:Float):Bool
	{
		#if (cpp && windows)
		return untyped __cpp__('updateWindowAnimNative(dt)');
		#else
		return true;
		#end
	}

	public static function windowAnimRunning():Bool
	{
		#if (cpp && windows)
		return untyped __cpp__('windowAnimRunningNative()');
		#else
		return false;
		#end
	}

	/** 动画完成后执行收尾动作（ShowWindow 最大化/还原/最小化）。 */
	public static function windowAnimFinish():Void
	{
		#if (cpp && windows)
		untyped __cpp__('finishWindowAnimNative();');
		#end
	}

	/** 设置窗口整体透明度（0~255，255=不透明）。用于关闭淡出动画。 */
	public static function windowSetAlpha(alpha:Int):Void
	{
		#if (cpp && windows)
		untyped __cpp__('setWindowAlphaNative(alpha);');
		#end
	}

	/** 移除窗口 layered 样式，恢复完全不透明（淡出被取消时用）。 */
	public static function windowAlphaReset():Void
	{
		#if (cpp && windows)
		untyped __cpp__('resetWindowAlphaNative();');
		#end
	}

	/**
	 * 弹出“分辨率已应用”系统 MessageBox 确认（独立线程，不阻塞游戏）。
	 * 是 = 应用，否 = 撤销；游戏侧 20 秒未选择会自动按“应用”关闭。
	 */
	public static function showResolutionDialog(text:String):Void
	{
		#if (cpp && windows)
		untyped __cpp__('showResDialogNative(text)');
		#end
	}

	/** 分辨率弹窗状态：0=无 1=运行中 2=用户撤销 3=用户应用/超时自动应用 */
	public static function resolutionDialogState():Int
	{
		#if (cpp && windows)
		return untyped __cpp__('resDialogStateNative()');
		#else
		return 0;
		#end
	}

	/** 复位分辨率弹窗状态（结果处理完后调用）。 */
	public static function resolutionDialogClear():Void
	{
		#if (cpp && windows)
		untyped __cpp__('resDialogClearNative();');
		#end
	}

	/** 主动结束分辨率弹窗（result：2=撤销 3=应用）。 */
	public static function closeResolutionDialog(result:Int):Void
	{
		#if (cpp && windows)
		untyped __cpp__('closeResDialogNative(result);');
		#end
	}

	/** 记录进入全屏前的完整窗口矩形（退出全屏后原样恢复）。 */
	public static function captureWindowedRect():Void
	{
		#if (cpp && windows)
		untyped __cpp__('captureWindowedRectNative();');
		#end
	}

	/** 把窗口恢复到进入全屏前的位置与大小。 */
	public static function restoreWindowedRect():Void
	{
		#if (cpp && windows)
		untyped __cpp__('restoreWindowedRectNative();');
		#end
	}
	/** 记录当前窗口矩形为“默认窗口”（fixScaling 后调用）。 */
	public static function captureDefaultWindowRect():Void
	{
		#if (cpp && windows)
		untyped __cpp__('captureDefaultWindowRectNative();');
		#end
	}

	/** 把窗口恢复到默认大小与位置（先退出最大化）。 */
	public static function windowRestoreDefault():Void
	{
		#if (cpp && windows)
		untyped __cpp__('windowRestoreDefaultNative();');
		#end
	}

	/** 设置窗口客户区尺寸（物理像素），最大化时先还原。 */
	public static function windowSetClientSize(w:Int, h:Int):Void
	{
		#if (cpp && windows)
		untyped __cpp__('windowSetClientSizeNative(w, h);');
		#end
	}

	/**
	 * Shows or hides the native Windows title bar (caption + min/max/close
	 * buttons) at runtime.
	 *
	 * The OUTER window rect (position + size) never changes: hiding the bar
	 * makes the client area grow up into the title bar space, showing it
	 * shrinks the client back down. The game viewport is expected to be
	 * re-measured afterwards (WindowChromeManager -> ViewportScaleMode).
	 *
	 * - Adding a caption is skipped while the window is WS_POPUP (SDL
	 *   fullscreen / borderless), because that would break fullscreen.
	 * - The bar height is cached into `titleBarHeightPx()` before hiding.
	 * - No-op on every non-Windows target.
	 *
	 * @param show `true` to restore the title bar, `false` to remove it.
	 */
	public static function setWindowChromeVisible(show:Bool):Void
	{
		#if (cpp && windows)
		untyped __cpp__('setWindowChromeNative(show);');

		// 同步 SDL 的 borderless 状态：自绘方案用 SetWindowLongPtr 直接改样式
		// （去 WS_CAPTION/WS_THICKFRAME），SDL 内部不知情——它的 GetWindowStyle
		// 仍按"普通窗口"返回 WS_CAPTION 样式，导致 SDL 全屏切换（win.fullscreen）
		// 时用错误样式覆盖窗口（退出全屏会把标题栏加回来、客户区变 1264x681），
		// 样式互相打架可能破坏 GL 呈现。隐藏标题栏 = borderless(true) 同步。
		var win:lime.ui.Window = (lime.app.Application.current != null) ? lime.app.Application.current.window : null;
		if (win != null && win.borderless != !show)
			win.borderless = !show;
		#end
	}
}
