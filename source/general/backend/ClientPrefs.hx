package general.backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.titleState.TitleState;

import games.backend.ExtraKeysHandler.EKNoteColor;


#if mobile
import general.objects.screen.MouseEffect;
import general.shaders.MobileShaderConverter;
#end

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables
{
	//更新这个直接原地爆破所有人设置
	public var prefsVersion:Int = 120;
	//更新这个能让性能相关的强制更新
	public var performanceDefaultsVersion:Int = 8;

	// General
	public var framerate:Int = 1000;
	public var scriptUpdateRate:Int = 0;
	public var scriptUpdateFrameLimit:Bool = false;
	public var drawFramerate:Int = 1000;
	public var lockRender:Bool = true;
	public var renderThread:Bool = true;
	public var vsync:Bool = true;
	public var resolution:String = 'Native';
	public var colorblindMode:String = 'None';
	public var lowQuality:Bool = false;
	public var gameQuality:Int = #if mobile 0 #else 1 #end;
	public var minImageCompressionSize:Int = 0;
	public var imageCompressionRatio:Float = 1.0;
	public var antialiasing:Bool = true;
	public var flashing:Bool = true;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = false;
	public var autoPause:Bool = true;
	public var gcFreeZone:Bool = true;
	public var generationalGC:Bool = false;
	#if android
	public var androidPerformanceHints:Bool = false;
	#end
	#if mobile
	public var autoOrientation:Bool = false;
	public var autoShaderConversion:Bool = true;
	public var mouseTrailEffect:Bool = true;
	#end

	// Gameplay
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var flipChart:Bool = false;
	public var ghostTapping:Bool = true;
	public var guitarHeroSustains:Bool = true;
	public var noReset:Bool = false;
	// Opponent s
	public var playOpponent:Bool = false;
	public var opponentCodeFix:Bool = false;
	public var botOpponentFix:Bool = true;
	public var healthDrainOPPOMult:Float = 0.5;
	public var healthDrainOPPO:Bool = false;

	// Backend
	// Gameplay backend s
	public var fixLNL:Int = 0; // fix long note length
	public var saveScoreBase:String = 'Score';
	public var mainMusic:String = 'None';
	public var optionMusic:String = 'None';
	public var pauseMusic:String = 'Tea Time';
	public var hitsoundType:String = 'Default';
	public var hitsoundVolume:Float = 0;
	public var oldHscriptVersion:Bool = false;
	public var pauseButton:Bool = #if mobile true #else false #end;
	public var compulsionPause:Bool = false;
	public var compulsionPauseNumber:Int = 3;
	public var gameOverVibration:Bool = false;
	public var ratingOffset:Int = 0;
	public var noteOffset:Int = 0;
	public var replayQuality:Bool = true;
	public var showReplayWatermark:Bool = true;
	public var marvelousWindow:Int = 15;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var marvelousRating:Bool = true;
	public var marvelousSprite:Bool = true;

	// App backend s
	public var discordRPC:Bool = true;
	public var checkForUpdates:Bool = true;
	public var screensaver:Bool = false;
	public var githubCheck:Bool = false;
	public var filesCheck:Bool = true;
	public var quotaGCIncreace:Float = 1;

	// Game UI
	// Visble s
	public var hideHud:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;
	public var opponentStrums:Bool = true;
	public var judgementCounter:Bool = false;
	public var keyboardViewer:Bool = true;
	// TimeBar s
	public var timeBarType:String = 'Time Left';
	// HealthBar s
	public var healthBarAlpha:Float = 1;
	public var oldHealthBarVersion:Bool = false;
	// Combe s
	public var comboStacking:Bool = true;
	public var comboColor:Bool = true;
	public var comboOffsetFix:Bool = true;
	// KeyBoard s
	public var keyboardAlpha:Float = 0.8;
	public var keyboardTimeDisplay:Bool = true;
	public var keyboardTime:Float = 500;
	public var keyboardBGColor:String = 'WHITE';
	public var keyboardTextColor:String = 'BLACK';
	// Camera s
	public var camZooms:Bool = true;
	public var scoreZoom:Bool = true;

	// Skin
	public var noteSkin:String = 'Default';
	// 音符着色体系三态：'auto' = 谱面皮肤优先 + 自动甄别 / 'legacy' = 沿用谱面皮肤 + 强制 HSV /
	// 'new' = 忽略谱面皮肤（换玩家皮肤）+ 强制 RGB。取值见 general.backend.NoteSkinStyle
	public var noteSystem:String = 'auto';
	// splash s
	public var splashSkin:String = 'Psych';
	public var splashSystem:String = 'auto';
	public var showSplash:Bool = true;
	public var splashAlpha:Float = 0.6;

	// Input
	// Moblie Input Backend s
	public var dynamicColors:Bool = true;
	public var needMobileControl:Bool = true; // work for desktop
	public var hitboxLocation:String = 'Bottom';
	public var controlsAlpha:Float = 0.6;
	public var playControlsAlpha:Float = 0.2;
	public var hideHitboxHints:Bool = false;

	public var extraKey:Int = 4;
	public var extraKeyReturn1:String = 'Space';
	public var extraKeyReturn2:String = 'Space';
	public var extraKeyReturn3:String = 'Shift';
	public var extraKeyReturn4:String = 'Shift';

	// User Interface
	public var uiScale:Float = 1;

	public var customFade:String = 'Move';
	public var customFadeSound:Float = 0.5;
	public var customFadeText:Bool = true;
	public var skipTitleVideo:Bool = false;
	public var audioDisplayQuality:Int = 1;
	public var audioDisplayUpdate:Int = 50;
	public var resultsScreen:Bool = true;
	public var loadingScreen:Bool = false;
	public var loadThreads:Int = #if mobile 2 #else 4 #end;
	public var useFlixelCoords:Bool = true;

	// Watermark
	public var showFPS:Bool = true;
	public var rainbowFPS:Bool = true;
	public var fpsDisplayMode:String = 'TPS';
	public var memoryType:String = 'Usage';
	public var fpsScale:Float = 1;
	public var watermarkScale:Float = 1;
	public var showWatermark:Bool = true;

	public var comboOffset:Array<Int> = [0, 0, 0, 0, 530, 470];

	public var language:String = 'English';

	public var storageFolder:String = 'NovaFlare Engine';

	public var developerMode:Bool = false;
	public var devConScale:Float = #if mobile 1.8 #else 1.5 #end;
	public var deepDebug:Bool = false;
	public var moreLuaErrors:Bool = false;
	public var hideLuaDebugText:Bool = false;

	//For Extra Keys (maybe)
	public var showKeybinds:Bool = false;
	
	public var enableRecordRotation:Bool = true;
	public var enableBpmZoom:Bool = true;
	
	//public var theme:Array<String> = ["Circle", "Straight", "None"];
	//public var songInfo:Array<String> = ["None", "Middle", "topLeft", "downLeft", "topRight", "downRight"];
	public var theme:String = "Circle";
	public var songInfo:String = "None";
	
	//////////////////////////////////////////////////////////////////////////////////////

	//Psych引擎的箭头RGB可以扔了，已经几乎被PsychEK代替了————卡昔233
	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];

	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	// legacy 体系的每轨 HSV 偏移：16 轨（多键引擎里 10 键也够用），lane 越界由 shaders.NoteHSV 取模归一
	public var arrowHSV:Array<Array<Float>> = [for (i in 0...16) [0.0, 0.0, 0.0]];

	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative',
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];
}

class ClientPrefs
{
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};
	public static var modsData:Map<String, Map<String, Dynamic>>= [];

	// Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		// Key Bind, Name for ControlsSubState
		'note_left' => [A, LEFT],
		'note_down' => [S, DOWN],
		'note_up' => [K, UP],
		'note_right' => [L, RIGHT],

		'0_key_0' => [SPACE],

		'1_key_0' => [D, LEFT],
		'1_key_1' => [K, RIGHT],

		'2_key_0' => [D],
		'2_key_1' => [SPACE],
		'2_key_2' => [K],

		'4_key_0' => [D],
		'4_key_1' => [F],
		'4_key_2' => [SPACE],
		'4_key_3' => [J],
		'4_key_4' => [K],

		'5_key_0' => [S],
		'5_key_1' => [D],
		'5_key_2' => [F],
		'5_key_3' => [J],
		'5_key_4' => [K],
		'5_key_5' => [L],

		'6_key_0' => [S],
		'6_key_1' => [D],
		'6_key_2' => [F],
		'6_key_3' => [SPACE],
		'6_key_4' => [J],
		'6_key_5' => [K],
		'6_key_6' => [L],

		'7_key_0' => [A],
		'7_key_1' => [S],
		'7_key_2' => [D],
		'7_key_3' => [F],
		'7_key_4' => [J],
		'7_key_5' => [K],
		'7_key_6' => [L],
		'7_key_7' => [SEMICOLON],

		'8_key_0' => [A],
		'8_key_1' => [S],
		'8_key_2' => [D],
		'8_key_3' => [F],
		'8_key_4' => [SPACE],
		'8_key_5' => [J],
		'8_key_6' => [K],
		'8_key_7' => [L],
		'8_key_8' => [SEMICOLON],

		'9_key_0' => [A],
		'9_key_1' => [S],
		'9_key_2' => [D],
		'9_key_3' => [F],
		'9_key_4' => [V],
		'9_key_5' => [N],
		'9_key_6' => [J],
		'9_key_7' => [K],
		'9_key_8' => [L],
		'9_key_9' => [SEMICOLON],

		'ui_up' => [W, UP],
		'ui_left' => [A, LEFT],
		'ui_down' => [S, DOWN],
		'ui_right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R],
		'volume_mute' => [#if mobile F10 #else ZERO #end],
		'volume_up' => [NUMPADPLUS, PLUS],
		'volume_down' => [NUMPADMINUS, MINUS],
		'debug_1' => [SEVEN],
		'debug_2' => [EIGHT],
		'fullscreen' => [F11]
	];

	//(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)(男人叹气)
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'0_key_0' => [DPAD_LEFT, X],

		'1_key_0'	 => [DPAD_LEFT, X],
		'1_key_1' 	 => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],

		'2_key_0'	 => [DPAD_LEFT, X],
		'2_key_1'	 => [DPAD_UP, Y],
		'2_key_2'	 => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],

		'note_up'    => [DPAD_UP, Y],
		'note_left'  => [DPAD_LEFT, X],
		'note_down'  => [DPAD_DOWN, A],
		'note_right' => [DPAD_RIGHT, B],

		'ui_up'      => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'    => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'    => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'   => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		'accept'     => [A, START],
		'back'       => [B],
		'pause'      => [START],
		'reset'      => [BACK]
	];
	
	public static var defaultMobileBinds:Map<String, Array<FlxKey>> = null;
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null)
	{
		if (controller != true)
			for (key in keyBinds.keys())
				if (defaultKeys.exists(key))
				{
					var arr = keyBinds.get(key);
					arr.resize(0);
					for (i in defaultKeys.get(key))
						arr.push(i);
				}

		if (controller != false)
			for (key in gamepadBinds.keys())
				if (defaultButtons.exists(key))
				{
					var arr = gamepadBinds.get(key);
					arr.resize(0);
					for (i in defaultButtons.get(key))
						arr.push(i);
				}
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		while (keyBind != null && keyBind.contains(NONE))
			keyBind.remove(NONE);
	}

	public static function clearInvalidButtons(key:String)
	{
		var buttonBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while (buttonBind != null && buttonBind.contains(FlxGamepadInputID.NONE))
			buttonBind.remove(FlxGamepadInputID.NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = [for (key => value in keyBinds) key => value.copy()];
		loadDefaultButtons();
	}

	public static function loadDefaultButtons()
	{
		defaultButtons = [for (key => value in gamepadBinds) key => value.copy()];
	}

	public static function savePreferences():Bool
	{
		for (key in Reflect.fields(data))
			if (key != 'arrowRGB' && key != 'arrowRGBPixel')
			{
				Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
			} //遍历data输入到flxsave里
		#if sys
		else if (key == 'arrowRGB')
			saveArrowRGBData('arrowRGB.json', data.arrowRGB);
		else if (key == 'arrowRGBPixel')
			saveArrowRGBData('arrowRGBPixel.json', data.arrowRGBPixel);
		#end

		FlxG.save.data.modsData = modsData;

		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		return FlxG.save.flush();
	}

	public static function saveSettings():Void
	{
		final saved = savePreferences();

		// Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var save:FlxSave = new FlxSave();
		save.bind('controls_v4', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;

		save.flush();
		if (saved) FlxG.log.add("Settings saved!");
	}

	#if (cpp && NOVAFLARE_GC_GENERATIONAL_PREFERENCE && !hxcpp_zgc)
	public static var generationalGCAtStartup(default, null):Bool = false;
	static var generationalGCInitialized = false;

	public static function initializeGenerationalGC():Void
	{
		if (generationalGCInitialized) return;
		generationalGCInitialized = true;
		final prefs = new FlxSave();
		try
		{
			if (prefs.bind('funkin', CoolUtil.getSavePath()))
			{
				final saved:Dynamic = Reflect.field(prefs.data, 'generationalGC');
				generationalGCAtStartup = Std.isOfType(saved, Bool) && saved == true;
			}
		}
		catch (error:haxe.Exception)
		{
			trace('Could not read the generational GC preference: ${error.message}');
		}
		prefs.destroy();
		data.generationalGC = generationalGCAtStartup;
		general.backend.gc.GCManager.configureGenerationalGC(generationalGCAtStartup);
	}
	#end

	#if sys
	public static function saveArrowRGBData(path:String, rgbArray:Array<Array<FlxColor>>)
	{
		var saveArrowRGB:ArrowRGBSavedData;
		var colors:Array<EKNoteColor> = [];
		for (color in rgbArray)
		{
			var inner = color[0];
			var border = color[1];
			var outline = color[2];

			var resultColor = new EKNoteColor();
			resultColor.inner = inner.toHexString(false, false);
			resultColor.border = border.toHexString(false, false);
			resultColor.outline = outline.toHexString(false, false);

			colors.push(resultColor);

			// trace('Saved color ${resultColor.inner} ${resultColor.border} ${resultColor.outline}');
		}

		saveArrowRGB = new ArrowRGBSavedData(colors);
		var writer = new json2object.JsonWriter<ArrowRGBSavedData>();
		var content = writer.write(saveArrowRGB, '    ');
		File.saveContent(path, content);

		trace('Wrote to $path');
	}
	#end

	public static function loadArrowRGBData(path:String, pixel:Bool = false, defaultColors:Array<EKNoteColor>)
	{
		var savedColors:CoolUtil.ArrowRGBSavedData = CoolUtil.getArrowRGB(path, defaultColors);

		if (pixel)
			ClientPrefs.defaultData.arrowRGBPixel = [];
		else
			ClientPrefs.defaultData.arrowRGB = [];

		for (defaultColor in defaultColors)
		{
			var thisNote = [
				CoolUtil.colorFromString(defaultColor.inner),
				CoolUtil.colorFromString(defaultColor.border),
				CoolUtil.colorFromString(defaultColor.outline)
			];
			if (pixel)
				ClientPrefs.defaultData.arrowRGBPixel.push(thisNote);
			else
				ClientPrefs.defaultData.arrowRGB.push(thisNote);
		}

		if (pixel)
			ClientPrefs.data.arrowRGBPixel = [];
		else
			ClientPrefs.data.arrowRGB = [];

		for (color in savedColors.colors)
		{
			var thisNote = [
				CoolUtil.colorFromString(color.inner),
				CoolUtil.colorFromString(color.border),
				CoolUtil.colorFromString(color.outline)
			];

			// trace('Loaded color into save: $thisNote, pixel? $pixel');

			if (pixel)
				ClientPrefs.data.arrowRGBPixel.push(thisNote);
			else
				ClientPrefs.data.arrowRGB.push(thisNote);
		}
	}

	public static function applyVSyncPreference():Bool
	{
		#if cpp
		var window = lime.app.Application.current?.window;
		return window != null && window.setVSyncMode(data.vsync ? lime.ui.WindowVSyncMode.ON : lime.ui.WindowVSyncMode.OFF);
		#else
		return false;
		#end
	}

	public static function loadPrefs()
	{
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		if (FlxG.save.data.prefsVersion != data.prefsVersion)
		{
			data = {};
			modsData = [];
			for (key in Reflect.fields(defaultData))
			{
				if (key == 'arrowRGB' || key == 'arrowRGBPixel' || key == 'modsData')
					continue;
				#if (cpp && NOVAFLARE_GC_GENERATIONAL_PREFERENCE && !hxcpp_zgc)
				if (key == 'generationalGC')
				{
					data.generationalGC = generationalGCAtStartup;
					Reflect.setField(FlxG.save.data, key, data.generationalGC);
					continue;
				}
				#end
				if (key == 'gameplaySettings')
				{
					data.gameplaySettings.clear();
					for (k => v in defaultData.gameplaySettings)
						data.gameplaySettings.set(k, v);
					FlxG.save.data.gameplaySettings = data.gameplaySettings;
					continue;
				}
				Reflect.setField(data, key, Reflect.field(defaultData, key));
				Reflect.setField(FlxG.save.data, key, Reflect.field(defaultData, key));
			}
			FlxG.save.data.modsData = modsData;

			#if desktop
			data.framerate = 240;
			data.drawFramerate = 1200;
			Reflect.setField(FlxG.save.data, 'framerate', data.framerate);
			Reflect.setField(FlxG.save.data, 'drawFramerate', data.drawFramerate);
			#elseif (!html5 && !switch)
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate * 2, 60, 1000));
			data.drawFramerate = Std.int(FlxMath.bound(refreshRate, 60, 1000));
			Reflect.setField(FlxG.save.data, 'framerate', data.framerate);
			Reflect.setField(FlxG.save.data, 'drawFramerate', data.drawFramerate);
			#end

			FlxG.save.flush();

			#if sys
			if (FileSystem.exists('arrowRGB.json')) FileSystem.deleteFile('arrowRGB.json');
			if (FileSystem.exists('arrowRGBPixel.json')) FileSystem.deleteFile('arrowRGBPixel.json');
			#end
			loadArrowRGBData('arrowRGB.json', false, ExtraKeysHandler.instance.data.colors);
			loadArrowRGBData('arrowRGBPixel.json', true, ExtraKeysHandler.instance.data.pixelNoteColors);

			if (defaultKeys == null)
				loadDefaultKeys();
			if (defaultButtons == null)
				loadDefaultButtons();

			keyBinds.clear();
			for (name => keys in defaultKeys)
				keyBinds.set(name, keys.copy());

			gamepadBinds.clear();
			for (name => buttons in defaultButtons)
				gamepadBinds.set(name, buttons.copy());

			var controlSave:FlxSave = new FlxSave();
			controlSave.bind('controls_v4', CoolUtil.getSavePath());
			if (controlSave != null)
			{
				controlSave.data.keyboard = defaultKeys;
				controlSave.data.gamepad = defaultButtons;
				controlSave.flush();
			}
			reloadVolumeKeys();
		}
		else
		{
			for (key in Reflect.fields(data))
				if (key != 'gameplaySettings' && 
					key != 'arrowRGB' &&
					key != 'arrowRGBPixel' &&
					// Keep the compiled migration target. Loading the saved marker
					// here makes the later comparison oldVersion < targetVersion
					// compare the old value with itself and silently skip migration.
					key != 'performanceDefaultsVersion' && Reflect.hasField(FlxG.save.data, key))
				{
					var savedValue:Dynamic = Reflect.field(FlxG.save.data, key);
					#if (cpp && NOVAFLARE_GC_GENERATIONAL_PREFERENCE && !hxcpp_zgc)
					if (key == 'generationalGC') savedValue = generationalGCAtStartup;
					#end
					// Older builds exposed this integer as a checkbox and may have saved a Bool.
					if (key == 'fixLNL' && Std.isOfType(savedValue, Bool)) savedValue = savedValue ? 1 : 0;
					Reflect.setField(data, key, savedValue);
				}
				else if (key == 'arrowRGB') 
				{
					loadArrowRGBData('arrowRGB.json', false, ExtraKeysHandler.instance.data.colors);
				} 
				else if (key == 'arrowRGBPixel') 
				{
					loadArrowRGBData('arrowRGBPixel.json', true, ExtraKeysHandler.instance.data.pixelNoteColors);
				}

			if (FlxG.save.data.modsData != null)
				modsData = FlxG.save.data.modsData;
			else modsData = [];

			var save:FlxSave = new FlxSave();
			save.bind('controls_v4', CoolUtil.getSavePath());
			if (save != null)
			{
				if (save.data.keyboard != null)
				{
					var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;
					for (control => keys in loadedControls)
						if (keyBinds.exists(control))
						{
							var arr = keyBinds.get(control);
							arr.resize(0);
							for (i in keys)
								arr.push(i);
						}
				}
				if (save.data.gamepad != null)
				{
					var loadedButtons:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;
					for (control => buttons in loadedButtons)
						if (gamepadBinds.exists(control))
						{
							var arr = gamepadBinds.get(control);
							arr.resize(0);
							for (i in buttons)
								arr.push(i);
						}
				}
				reloadVolumeKeys();
			}
		}

		#if desktop
		// Migrate only the measured desktop scheduling defaults. Keep every other
		// preference and key binding intact.
		var savedPerformanceDefaultsVersion:Dynamic = Reflect.field(FlxG.save.data, 'performanceDefaultsVersion');
		if (savedPerformanceDefaultsVersion == null || savedPerformanceDefaultsVersion < data.performanceDefaultsVersion)
		{
			data.framerate = 240;
			data.drawFramerate = 1200;
			data.lockRender = true;
			// Lime's GL worker keeps a bounded two-frame pipeline. Keep driver
			// submission off the update thread; direct submission serializes UI
			// traversal with GL commands and causes a high-FPS regression.
			data.renderThread = true;
			// Keep desktop high-FPS mode at the engine's authored resolution.
			// Higher resolutions remain selectable, but should be an explicit
			// image-quality choice rather than a hidden cost on every interface.
			data.resolution = '720P';
			Reflect.setField(FlxG.save.data, 'framerate', data.framerate);
			Reflect.setField(FlxG.save.data, 'drawFramerate', data.drawFramerate);
			Reflect.setField(FlxG.save.data, 'lockRender', data.lockRender);
			Reflect.setField(FlxG.save.data, 'renderThread', data.renderThread);
			Reflect.setField(FlxG.save.data, 'resolution', data.resolution);
			Reflect.setField(FlxG.save.data, 'performanceDefaultsVersion', data.performanceDefaultsVersion);
			FlxG.save.flush();
		}
		#end

		if (Main.fpsVar != null)
			Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = data.autoPause;

		if (FlxG.save.data.framerate == null)
		{
			#if desktop
			data.framerate = 240;
			#else
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate * 2;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 60, 1000));
			#end
		}

		if (FlxG.save.data.drawFramerate == null)
		{
			#if desktop
			data.drawFramerate = 1200;
			#else
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.drawFramerate = Std.int(FlxMath.bound(refreshRate, 60, 1000));
			#end
		}
		#end

		var useRenderThread:Bool = data.renderThread;
		#if sys
		// Keep the saved preference as the default, while allowing repeatable
		// render-path A/B tests without rewriting the user's save file.
		final renderThreadOverride:String = Sys.getEnv('NOVAFLARE_RENDER_THREAD');
		if (renderThreadOverride == '0')
			useRenderThread = false;
		else if (renderThreadOverride == '1')
			useRenderThread = true;
		#end
		lime.graphics.opengl.GL.setMultiThreaded(useRenderThread);
		#if cpp
		if (!applyVSyncPreference())
		{
			trace('Could not apply the saved VSync preference');
		}
		#end

		#if android
		mobile.backend.AndroidPerformanceHints.setEnabled(data.androidPerformanceHints);
		#end
		#if mobile
		MobileShaderConverter.setEnabled(data.autoShaderConversion);
		MouseEffect.setUserEffectsEnabled(data.mouseTrailEffect);
		#end

		FlxG.updateFramerate = data.framerate;
		data.resolution = RenderResolution.normalize(data.resolution);
		RenderResolution.configureStage(openfl.Lib.current.stage);
		RenderResolution.apply(openfl.Lib.current.stage);

		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;
			for (name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}

		// flixel automatically saves your volume!
		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;

		normalizeNoteSystems();

		#if DISCORD_ALLOWED
		DiscordClient.check();
		#end
	}

	/**
	 * 音符 / 溅射着色体系的三态规范化，以及从已废弃的 noteRGB / noteColorSwap / splashRGB 迁移。
	 *
	 * 老存档里这三个 Bool 是"强制"语义：noteColorSwap=true 等价于强制 HSV（legacy），
	 * noteRGB=false 是同一诉求的另一种写法；splashRGB=false 同理。新存档只写 noteSystem /
	 * splashSystem，所以只在「还没有新键」时执行迁移，不会覆盖用户后来选的 auto。
	 */
	static function normalizeNoteSystems():Void
	{
		// 16 轨：老存档只有 4 项，补到 16 项；顺手把残缺项修成三元组。
		// 重建一份新数组，别和 defaultData 共享同一份引用（否则"重置默认值"会带上用户的改动）
		final oldHSV:Array<Array<Float>> = data.arrowHSV;
		final normalized:Array<Array<Float>> = [];
		for (i in 0...16)
		{
			final row:Array<Float> = (oldHSV != null && i < oldHSV.length) ? oldHSV[i] : null;
			normalized.push((row != null && row.length >= 3) ? row.copy() : [0.0, 0.0, 0.0]);
		}
		data.arrowHSV = normalized;

		// 新存档没有 noteRGB / noteColorSwap / splashRGB 这三个键，老存档才有
		final savedNoteSystem:Dynamic = Reflect.field(FlxG.save.data, 'noteSystem');
		if (savedNoteSystem == null)
		{
			final oldSwap:Dynamic = Reflect.field(FlxG.save.data, 'noteColorSwap');
			final oldRGB:Dynamic = Reflect.field(FlxG.save.data, 'noteRGB');
			if (oldSwap == true || oldRGB == false)
				data.noteSystem = NoteSkinStyle.LEGACY;
		}

		final savedSplashSystem:Dynamic = Reflect.field(FlxG.save.data, 'splashSystem');
		if (savedSplashSystem == null)
		{
			final oldSplashRGB:Dynamic = Reflect.field(FlxG.save.data, 'splashRGB');
			if (oldSplashRGB == false)
				data.splashSystem = NoteSkinStyle.LEGACY;
		}

		data.noteSystem = NoteSkinStyle.normalizeMode(data.noteSystem);
		data.splashSystem = NoteSkinStyle.normalizeMode(data.splashSystem);
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if (!customDefaultValue)
			defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys()
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		FlxG.sound.muteKeys = turnOn ? TitleState.muteKeys : [];
		FlxG.sound.volumeDownKeys = turnOn ? TitleState.volumeDownKeys : [];
		FlxG.sound.volumeUpKeys = turnOn ? TitleState.volumeUpKeys : [];
	}

	public static function get(variable:String, supportMods:Bool = true):Dynamic {
		if (supportMods) {
			if (modsData.get(Mods.currentModDirectory).get(variable) != null)
					return modsData.get(Mods.currentModDirectory).get(variable);

			if (modsData.get('Global mod').get(variable) != null)
					return modsData.get('Global mod').get(variable);

			for (mod in Mods.getGlobalMods())
			{
				if (modsData.get(mod).get(variable) != null)
					return modsData.get(mod).get(variable);
			}
		}

		if (Reflect.getProperty(ClientPrefs.data, variable) != null)
			return Reflect.getProperty(ClientPrefs.data, variable);

		return null;
	}

	public static function set(variable:String, data:Bool = true, path:String = '') {
		switch (path) {
			case '':
				if (Mods.currentModDirectory != '') {
					if (modsData.get(Mods.currentModDirectory) == null)
						modsData.set(Mods.currentModDirectory, []);
					modsData.get(Mods.currentModDirectory).set(variable, data);
				} else {
					if (modsData.get('Global mod') == null)
						modsData.set('Global mod', []);
					modsData.get('Global mod').set(variable, data);
				}
			case 'data':
				try{ Reflect.setProperty(ClientPrefs.data, variable, data); }
			case _:
				if (modsData.get(path) == null)
						modsData.set(path, []);
				modsData.get(path).set(variable, data);
		}
	}
}

