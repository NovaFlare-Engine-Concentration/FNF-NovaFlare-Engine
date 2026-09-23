package options.groupData;

import developer.console.Console;
import developer.console.ConsoleToggleButton;
import lime.system.System as LimeSystem;

import mobile.objects.EditorMobileKeys;

class MaintenanceGroup extends OptionCata
{
	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y, width, height);

        var option:Option = new Option(this, 'Maintenance', TITLE);
        addOption(option);

        var option:Option = new Option(this, 'developerMode', BOOL);
		option.experMode = true;
		option.onChange = function() {
			if (!ClientPrefs.data.developerMode) {
				Console.hide();
				ConsoleToggleButton.hide();
			} else {
				ConsoleToggleButton.show();
			}
		};
        addOption(option);

		#if sys
		var option:Option = new Option(this, 'deepDebug', BOOL);
		option.experMode = true;
		addOption(option);
		#end

		// Lua 语法错误提示：脚本报错要不要一条条铺在屏幕左上角。
		// 默认关闭 —— 报错只写进日志（控制台/日志文件里照样查得到），屏幕不再被 mod 的
		// 一堆 "image could not be loaded" 刷满；打开则回到以前的表现。
		// ★ 只管脚本报错这一条通道（PlayState.addScriptErrorToDebug）；
		//   debugPrint、luaTrace 和引擎自身的报错不受影响，始终显示。
		var option:Option = new Option(this, 'luaErrorOverlay', BOOL);
		addOption(option);

		// HScript 语法错误提示：与上一条对称，各自独立、互不影响。
		// ★ 先说清楚：HScript 脚本自身的报错（Iris.error / Iris.warn）**本来就不上屏** ——
		//   走的是 Iris.logLevel → Sys.println + 开发者控制台 + 1145 trace 客户端。
		//   这个开关管的是 HScriptBase 里那几处会铺到屏幕上的脚本报错
		//   （runHaxeCode 执行抛错、addHaxeLibrary 解析失败）。
		var option:Option = new Option(this, 'hscriptErrorOverlay', BOOL);
		addOption(option);

		// 调整移动端各 Editor 键位：开启后暂时隐藏所有默认 Editor 虚拟按键，
		// 并打开外部窗口（本地 HTTP 页面）创建/删除/保存自定义按键。
		var option:Option = new Option(this, 'adjustMobileEditorKeys', BOOL);
		option.experMode = true;
		option.onChange = () -> EditorMobileKeys.setEnabled(ClientPrefs.data.adjustMobileEditorKeys);
		addOption(option);
        
        var option:Option = new Option(this, 'devConScale', FLOAT, [0.5, 3, 1]);
		addOption(option);
		option.onChange = () -> updateText();
	
		/////--App--\\\\\

		var option:Option = new Option(this, 'APP', TEXT);
		addOption(option);

		#if android
		var storageFolderArray:Array<String> = ['NovaFlare Engine', 'NovaFlare Engine-1.2'];
		var option:Option = new Option(this, 'storageFolder', STRING, storageFolderArray);
		option.onChange = onChangeStorageFolder;
		addOption(option);
		#end

		var option:Option = new Option(this, 'discordRPC', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'checkForUpdates', BOOL);
		addOption(option);

		#if mobile
		var option:Option = new Option(this, 'screensaver', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'filesCheck', BOOL);
		addOption(option);

		var option:Option = new Option(this, 'filesCheckNew', STATE); //copystate
		option.onChange = function() { changeState(6); };
		addOption(option);
		#end

		changeHeight(0); //初始化真正的height
	}
	
	function changeState(type:Int) {
		OptionsState.instance.moveState(type);
	}
	
	function updateText(){
	    if(Console.consoleInstance != null) {
	        Console.consoleInstance.updateScale(ClientPrefs.data.devConScale);
	    }
	}

	#if sys
	function enterOriginFunkin():Void
	{
		if (!originfunkin.OriginFunkinMode.canEnterOrigin())
		{
			trace('[originFunkin] Switch cancelled: ${originfunkin.OriginFunkinMode.preparationError}');
			return;
		}

		if (!originfunkin.OriginFunkinConfig.requestOrigin())
		{
			trace('[originFunkin] Switch cancelled: could not save the Origin Funkin startup request.');
			return;
		}
		try
		{
			ClientPrefs.saveSettings();
		}
		catch (error:Dynamic)
		{
			trace('[originFunkin] Could not save NovaFlare preferences before entering Origin Funkin: $error');
		}
		LimeSystem.exit(0);
	}
	#end
 

	#if android
	function onChangeStorageFolder()
	{
		ClientPrefs.saveSettings();
		
		// Write the config file for next startup
		var configFile:String = AndroidEnvironment.getExternalStorageDirectory() + '/.novaflare_storage_config';
		try {
			sys.io.File.saveContent(configFile, ClientPrefs.data.storageFolder);
		} catch (e:Dynamic) {
			trace('Failed to save storage config: $e');
		}
		
		Sys.exit(0);
	}
	#end
}
