package general.backend;

import flixel.FlxG;
import flixel.system.scaleModes.RatioScaleMode;
#if (cpp && windows)
import general.backend.device.Native;
#end

/**
 * 与 `RatioScaleMode` 行为一致（默认 1280x720 逻辑分辨率、等比适配），
 * 额外支持"扩展视口"：当系统标题栏被隐藏（沉浸式界面）时，把游戏逻辑
 * 分辨率随窗口客户端同步扩展，使画面满幅铺满整个窗口——无黑边、无拉伸，
 * 且 UI 的物理尺寸保持不变（只是多看到一点内容）。
 *
 * 由 `WindowChromeManager` 在隐藏/恢复标题栏时切换 `extendedViewport`，
 * 窗口客户端变化触发的 stage resize 会自动走 `onMeasure` 完成重排。
 *
 * 关键：`FlxGame.onResize` 传入的是 `stage.stageWidth/Height`，但 stage
 * 尺寸可能在全屏切换瞬间尚未更新（SDL 事件延迟），导致 `cameras.resize()`
 * 用旧尺寸覆盖正确的相机视口。扩展视口模式下直接从 Windows API 读取
 * 真实客户区尺寸，确保 `onMeasure` 始终使用正确的物理尺寸。
 */
class ViewportScaleMode extends RatioScaleMode
{
	/** 是否处于扩展视口模式（标题栏隐藏、画面铺满窗口） */
	public static var extendedViewport:Bool = false;

	/** 最近一次应用到的逻辑尺寸（相机同步用） */
	public static var lastLogicalWidth:Int = 0;
	public static var lastLogicalHeight:Int = 0;

	override function onMeasure(Width:Int, Height:Int):Void
	{
		#if (cpp && windows)
		// 扩展视口模式：用 Windows API 的真实客户区尺寸替代可能延迟的 stage 尺寸。
		// FlxGame.onResize 传入的 stage.stageWidth/Height 在全屏切换时可能还是旧值，
		// 导致 cameras.resize() 用旧尺寸设 scrollRect，只显示左上角一小块。
		if (extendedViewport)
		{
			var realW:Int = Native.clientWidth();
			var realH:Int = Native.clientHeight();
			if (realW > 0 && realH > 0)
			{
				Width = realW;
				Height = realH;
			}
		}
		#end

		super.onMeasure(Width, Height);

		if (extendedViewport && Width > 0 && Height > 0)
		{
			// super 刚按 1280x720 逻辑算过等比缩放：
			// scale = 画面物理尺寸 / 逻辑尺寸（UI 的物理大小系数）
			var baseX:Float = scale.x;
			var baseY:Float = scale.y;
			if (baseX <= 0) baseX = 1;
			if (baseY <= 0) baseY = 1;

			var logicalW:Int = Math.round(Width / baseX);
			var logicalH:Int = Math.round(Height / baseY);
			if (logicalW < 1) logicalW = 1;
			if (logicalH < 1) logicalH = 1;

			untyped
			{
				FlxG.width = logicalW;
				FlxG.height = logicalH;
			}
			lastLogicalWidth = logicalW;
			lastLogicalHeight = logicalH;

			// 满幅：画面 = 设备尺寸（offset 归零，无黑边）
			gameSize.set(Width, Height);
			deviceSize.set(Width, Height);
			updateScaleOffset();
			updateGamePosition();
		}
		else
		{
			lastLogicalWidth = FlxG.width;
			lastLogicalHeight = FlxG.height;
		}
	}
}
