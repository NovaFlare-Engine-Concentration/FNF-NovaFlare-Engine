package developer.editors.psych104;

/** Adapts the mobile editor's file-saving calls to NovaFlare's storage API. */
class StorageUtil
{
	public static function saveContent(fileName:String, data:String):Void
	{
		var safeName = fileName.split('\\').join('/');
		safeName = safeName.substr(safeName.lastIndexOf('/') + 1);
		var extensionStart = safeName.lastIndexOf('.');
		var extension = extensionStart >= 0 ? safeName.substr(extensionStart) : '';
		var baseName = extensionStart >= 0 ? safeName.substr(0, extensionStart) : safeName;
		mobile.backend.SUtil.saveContent(baseName, extension, data);
	}
}
