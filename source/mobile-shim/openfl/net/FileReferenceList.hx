package openfl.net;

import openfl.events.EventDispatcher;

/**
 * Mobile 桩：openfl 的 FileReferenceList 在移动端不存在（仅桌面/Flash），
 * 这里提供空实现保证移动端可编译（批量文件选择仅桌面可用）。
 * 注意：不能遮蔽 openfl 原版 FileReference —— File 类继承它。
 */
class FileReferenceList extends EventDispatcher
{
	public var fileList:Array<FileReference> = [];

	public function new()
	{
		super();
	}

	public function browse(?typeFilters:Array<FileFilter>):Bool
	{
		return false;
	}
}
