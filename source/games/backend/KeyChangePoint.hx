package games.backend;

/**
	KeyChange(MoreKey) 事件时间线上的一个切换点。
	time 与 Note.strumTime 同一坐标系（已含 noteOffset）。
**/
typedef KeyChangePoint =
{
	/** 事件触发时间（与 Note.strumTime 同一坐标系，已含 noteOffset） */
	var time:Float;

	/** 目标键数（显示键数，4 = 4K），事件生效后每侧键数 */
	var keys:Int;

	/** 过渡时间（秒，事件 value2；strum 淡入重渲染用，<=0 时为默认值） */
	var trans:Float;
}
