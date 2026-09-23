package general.objects;

/**
 * 自绘窗口控制条的显示模式。
 */
enum abstract WindowBarMode(Int)
{
	/** 常驻显示（编辑器：融入顶栏右侧） */
	var CONSTANT = 0;

	/** 平时隐藏，鼠标靠近窗口顶部时滑入，移开后滑出 */
	var AUTO_HIDE = 1;
}
