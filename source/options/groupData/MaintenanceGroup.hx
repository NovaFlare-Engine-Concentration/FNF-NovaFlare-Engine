package options.groupData;

import developer.console.Console;
import developer.console.ConsoleToggleButton;
import lime.system.System as LimeSystem;

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

		#if sys
		originfunkin.OriginFunkinConfig.load();
		if (originfunkin.OriginFunkinConfig.hasEnteredOrigin)
		{
			var option:Option = new Option(this, 'enterOriginFunkin', STATE);
			option.setLanguageOverride('ENTER ORIGIN FUNKIN',
				'Exit NovaFlare Engine and start Origin Funkin on the next launch.');
			option.onChange = enterOriginFunkin;
			addOption(option);
		}
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
