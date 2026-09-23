package developer.editors;

import games.objects.Note;
import games.objects.NoteSplash;
import games.objects.StrumNote;

import openfl.net.FileFilter;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import haxe.Json;

import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;

@:access(games.objects.NoteSplash)
/**
 * Note Splash 编辑器（NovaFlare 新版 UI）：
 *  - Adobe 风格顶栏菜单（NoteSplashEditorMenuBar）+ 底部状态栏 + EditorChromeUI 窗口栏
 *  - 4 音符预览/溅射预览保留；动画/属性/染色参数收进菜单（原生 FlxUI 控件只作数据源）
 */
class NoteSplashEditorState extends MusicBeatState
{
	var strums:FlxTypedSpriteGroup<StrumNote> = new FlxTypedSpriteGroup();
	var splashes:FlxTypedSpriteGroup<NoteSplash> = new FlxTypedSpriteGroup();
	var config = NoteSplash.createConfig();

	var errorText:FlxText;
	var curText:FlxText;

	static var imageSkin:String = null;
	var splash:NoteSplash;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	// ===== 顶栏菜单 =====
	var menuBar:NoteSplashEditorMenuBar;
	#if (cpp && windows)
	var windowChrome:EditorChromeUI;
	var modInfoPopup:general.objects.ModInfoPopup;
	#end

	var uiLayer:FlxSpriteGroup;
	var overlayLayer:FlxSpriteGroup;

	// ===== 原生控件（只作数据源，不渲染）=====
	var w_image:FlxUIInputText;         // 皮肤图片
	var w_scale:FlxUINumericStepper;    // 缩放
	var w_anim:FlxUIDropDownMenu;       // 动画列表
	var w_anim_name:FlxUIInputText;     // 动画名
	var w_prefix:FlxUIInputText;        // 帧前缀
	var w_note_data:FlxUINumericStepper;// note data
	var w_indices:FlxUIInputText;       // 帧索引
	var w_min_fps:FlxUINumericStepper;  // 最低帧率
	var w_max_fps:FlxUINumericStepper;  // 最高帧率
	var w_allow_rgb:FlxUICheckBox;      // 允许 RGB
	var w_allow_pixel:FlxUICheckBox;    // 允许像素
	var w_target:FlxUIDropDownMenu;     // 替换目标通道
	var w_r:FlxUINumericStepper;        // R
	var w_g:FlxUINumericStepper;        // G
	var w_b:FlxUINumericStepper;        // B
	var w_no_replace:FlxUICheckBox;     // 不替换该通道

	var syncingWidgets:Bool = false;

	var curAnim:String;

	var redEnabled:Bool = true;
	var blueEnabled:Bool = true;
	var greenEnabled:Bool = true;
	var redShader:Array<Int> = [0, 0, 0];
	var greenShader:Array<Int> = [0, 0, 0];
	var blueShader:Array<Int> = [0, 0, 0];

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var copiedOffset:Array<Float> = [0, 0];
	var transitioning:Bool = false;

	override function create()
	{
		if (imageSkin == null)
			imageSkin = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();

		camGame = initPsychCamera();
		camGame.bgColor = FlxColor.fromHSL(0, 0, 0.5);
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		FlxG.mouse.visible = true;

		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Note Splash Editor');
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF505050;
		bg.cameras = [camGame];
		add(bg);

		for (i in 0...4)
		{
			var babyArrow:StrumNote = new StrumNote(0, 50, i % 4, 1);
			babyArrow.x = (FlxG.width - Note.swagWidth * 4) / 2 + i * Note.swagWidth;
			babyArrow.screenCenter(Y);
			babyArrow.ID = i;
			// ★ 构造器不会自动播放动画（游戏里是 postAddedToGroup() 负责），这里必须显式播一次：
			//   否则 animation.curAnim 一直为 null，update() 里读 curAnim.name 会直接空指针。
			babyArrow.playAnim('static');
			strums.add(babyArrow);
		}
		add(strums);
		add(splashes);

		splash = new NoteSplash(0, 0, imageSkin); // this cannot be recycled
		splash.inEditor = true;
		splash.alpha = .0;
		splashes.add(splash);

		if (splash.config != null)
			config = splash.config;

		// UI 提示文本（HUD 相机，顶栏下方）
		errorText = new FlxText();
		errorText.setFormat(null, 16, FlxColor.RED);
		errorText.text = "ERROR!";
		errorText.y = FlxG.height - errorText.height;
		errorText.alpha = .0;
		errorText.cameras = [camHUD];
		errorText.scrollFactor.set();
		add(errorText);

		curText = new FlxText();
		curText.setFormat(null, 16, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		curText.text = 'Copied Offsets: [0, 0]\nCurrent Animation: NONE';
		curText.y = FlxG.height - curText.height - 26;
		curText.x += 5;
		curText.cameras = [camHUD];
		curText.scrollFactor.set();
		add(curText);

		// ===== UI 层 =====
		uiLayer = new FlxSpriteGroup();
		uiLayer.cameras = [camHUD];
		uiLayer.scrollFactor.set();
		add(uiLayer);

		createLegacyWidgets();
		parseRGB();
		setupMenuBar();
		setupOverlayLayer();
		addLegacyWidgetsToScene();
		hideAllLegacyWidgets();

		#if (cpp && windows)
		windowChrome = new EditorChromeUI();
		windowChrome.scrollFactor.set();
		windowChrome.cameras = [camHUD];
		add(windowChrome);
		modInfoPopup = new general.objects.ModInfoPopup();
		modInfoPopup.scrollFactor.set();
		modInfoPopup.cameras = [camHUD];
		add(modInfoPopup);
		windowChrome.onTitleClick = () -> modInfoPopup.openUnder(windowChrome);
		// 顶栏左侧「退出 音符溅射调试」按钮
		windowChrome.setupExitButton('noteSplashDebug', exitEditor);
		#end

		refreshWidgetsFromConfig();
		super.create();
	}

	// ============ 顶栏菜单 ============
	function setupMenuBar():Void
	{
		menuBar = new NoteSplashEditorMenuBar();
		menuBar.scrollFactor.set();
		menuBar.uiCamera = camHUD;
		menuBar.cameras = [camHUD];
		menuBar.onAction = function(actionKey:String) {
			handleMenuAction(actionKey);
		};
		menuBar.onMenuOpened = function(menuKey:String) {
			refreshWidgetsFromConfig();
		};

		menuBar.registerWidget('w_anim', w_anim);
		menuBar.registerWidget('w_anim_name', w_anim_name);
		menuBar.registerWidget('w_prefix', w_prefix);
		menuBar.registerWidget('w_note_data', w_note_data);
		menuBar.registerWidget('w_indices', w_indices);
		menuBar.registerWidget('w_min_fps', w_min_fps);
		menuBar.registerWidget('w_max_fps', w_max_fps);
		menuBar.registerWidget('w_image', w_image);
		menuBar.registerWidget('w_scale', w_scale);
		menuBar.registerWidget('w_allow_rgb', w_allow_rgb);
		menuBar.registerWidget('w_allow_pixel', w_allow_pixel);
		menuBar.registerWidget('w_target', w_target);
		menuBar.registerWidget('w_r', w_r);
		menuBar.registerWidget('w_g', w_g);
		menuBar.registerWidget('w_b', w_b);
		menuBar.registerWidget('w_no_replace', w_no_replace);

		uiLayer.add(menuBar);
	}

	function setupOverlayLayer():Void
	{
		overlayLayer = new FlxSpriteGroup();
		overlayLayer.cameras = [camHUD];
		overlayLayer.scrollFactor.set();
		add(overlayLayer);
		menuBar.overlayLayer = overlayLayer;
	}

	// ============ 隐藏的原生控件（只作数据源）============
	function createLegacyWidgets():Void
	{
		w_image = new FlxUIInputText(0, 0, 160, imageSkin, 8);
		w_scale = new FlxUINumericStepper(0, 0, 0.1, 1, 0, 4, 2);
		w_anim = new FlxUIDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray([''], false), function(id:String) {
			if (syncingWidgets) return;
			var name:String = w_anim.selectedLabel;
			if (name != null && name.length > 0 && config != null && config.animations.exists(name))
				selectAnimation(name);
		});
		w_anim_name = new FlxUIInputText(0, 0, 120, '', 8);
		w_prefix = new FlxUIInputText(0, 0, 120, '', 8);
		w_note_data = new FlxUINumericStepper(0, 0, 1, 0, 0, 999, 0);
		w_indices = new FlxUIInputText(0, 0, 120, '', 8);
		w_min_fps = new FlxUINumericStepper(0, 0, 1, 22, 1, 120, 0);
		w_max_fps = new FlxUINumericStepper(0, 0, 1, 26, 1, 120, 0);
		w_allow_rgb = new FlxUICheckBox(0, 0, null, null, "Allow RGB", 100);
		w_allow_pixel = new FlxUICheckBox(0, 0, null, null, "Allow Pixel", 100);
		w_target = new FlxUIDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray(['Red', 'Green', 'Blue'], false), function(id:String) {
			if (syncingWidgets) return;
			refreshRGBWidgets();
		});
		w_r = new FlxUINumericStepper(0, 0, 1, 0, 0, 255, 0);
		w_g = new FlxUINumericStepper(0, 0, 1, 0, 0, 255, 0);
		w_b = new FlxUINumericStepper(0, 0, 1, 0, 0, 255, 0);
		w_no_replace = new FlxUICheckBox(0, 0, null, null, "No Replace", 100);

		w_allow_rgb.callback = function() {
			if (syncingWidgets) return;
			if (config != null) config.allowRGB = w_allow_rgb.checked;
		};
		w_allow_pixel.callback = function() {
			if (syncingWidgets) return;
			if (config != null) config.allowPixel = w_allow_pixel.checked;
		};
		w_no_replace.callback = function() {
			if (syncingWidgets) return;
			switch (w_target.selectedLabel)
			{
				case 'Red': redEnabled = !w_no_replace.checked;
				case 'Green': greenEnabled = !w_no_replace.checked;
				case 'Blue': blueEnabled = !w_no_replace.checked;
			}
			setConfigRGB();
		};
	}

	function addLegacyWidgetsToScene():Void
	{
		function addOne(w:Dynamic):Void {
			if (w == null) return;
			try { overlayLayer.add(w); } catch (e:Dynamic) {}
			try { w.scrollFactor.set(0, 0); } catch (e:Dynamic) {}
			try { w.setScrollFactor(0, 0); } catch (e:Dynamic) {}
			try { w.cameras = [camHUD]; } catch (e:Dynamic) {}
			try { w.visible = false; } catch (e:Dynamic) {}
			try { w.active = true; } catch (e:Dynamic) {}
		}
		var all:Array<Dynamic> = [w_image, w_scale, w_anim, w_anim_name, w_prefix, w_note_data, w_indices,
			w_min_fps, w_max_fps, w_allow_rgb, w_allow_pixel, w_target, w_r, w_g, w_b, w_no_replace];
		for (w in all) addOne(w);
	}

	function hideAllLegacyWidgets():Void
	{
		var all:Array<Dynamic> = [w_image, w_scale, w_anim, w_anim_name, w_prefix, w_note_data, w_indices,
			w_min_fps, w_max_fps, w_allow_rgb, w_allow_pixel, w_target, w_r, w_g, w_b, w_no_replace];
		for (w in all)
			EditorInputStyle.deepHide(w);
	}

	// ============ 菜单动作分发 ============
	function handleMenuAction(actionKey:String):Void
	{
		switch (actionKey)
		{
			case 'anim_add':
				addUpdateAnimation();
			case 'anim_remove':
				removeAnimation();
			case 'reload_image':
				reloadImage();
			case 'template':
				NoteSplash.configs.clear();
				config = NoteSplash.createConfig();
				curAnim = null;
				refreshWidgetsFromConfig();
				parseRGB();
			case 'convert_txt':
				loadTxt();
			case 'reset_rgb':
				resetRGB();
				setConfigRGB();
				refreshRGBWidgets();
			case 'save':
				saveSplash();
			case 'exit':
				exitEditor();
		}
	}

	function exitEditor():Void
	{
		MusicBeatState.switchState(new MasterEditorMenu());
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
		transitioning = true;
	}

	// ============ 动画选择 / 增删 ============
	function selectAnimation(name:String):Void
	{
		if (config == null || !config.animations.exists(name)) return;
		var i:NoteSplashAnim = config.animations.get(name);
		curAnim = name;
		syncingWidgets = true;
		w_anim_name.text = name;
		w_prefix.text = i.prefix;
		w_note_data.value = i.noteData;
		w_min_fps.value = i.fps[0];
		w_max_fps.value = i.fps[1];
		if (i.indices != null && i.indices.length > 0)
			w_indices.text = i.indices.toString().substring(1, i.indices.toString().length - 1);
		else
			w_indices.text = '';
		syncingWidgets = false;
		playStrumAnim(name, i.noteData);
	}

	function addUpdateAnimation():Void
	{
		if (config == null) return;
		var name:String = w_anim_name.text.trim();
		if (name.length < 1) return;

		var indices:Array<Int> = [];
		if (w_indices.text.split(',').length > 1)
		{
			for (i in w_indices.text.split(','))
			{
				var index:Null<Int> = Std.parseInt(i);
				if (!Math.isNaN(index) && index != null) indices.push(index);
			}
		}

		var offsets:Array<Float> = [0, 0];
		var conf = config.animations.get(name);
		if (conf != null) offsets = conf.offsets;
		if (offsets == null) offsets = [0, 0];
		else offsets = offsets.copy();

		config = NoteSplash.addAnimationToConfig(config, w_scale.value, name, w_prefix.text,
			[cast w_min_fps.value, cast w_max_fps.value], offsets, indices, cast w_note_data.value);
		curAnim = name;
		playStrumAnim(name, cast w_note_data.value);
		refreshWidgetsFromConfig();
	}

	function removeAnimation():Void
	{
		if (config == null || curAnim == null) return;
		if (config.animations.exists(curAnim))
		{
			config.animations.remove(curAnim);
			curAnim = null;
			refreshWidgetsFromConfig();
		}
	}

	// ============ 皮肤重载 ============
	function reloadImage():Void
	{
		imageSkin = w_image.text.trim();
		if (imageSkin.length < 1) return;

		errorText.color = FlxColor.RED;
		FlxTween.cancelTweensOf(errorText);

		var image = Paths.image(imageSkin);
		if (image == null)
		{
			errorText.text = 'ERROR! Couldn\'t find $imageSkin.png';
			errorText.alpha = 1;
			return;
		}
		else
		{
			errorText.color = FlxColor.GREEN;
			errorText.alpha = 1;
			errorText.text = 'Succesfully loaded $imageSkin.png';
		}

		NoteSplash.configs.clear();

		FlxTween.tween(errorText, {alpha: 0}, 1, {startDelay: 1, onComplete: (twn) -> {
			errorText.color = FlxColor.RED;
		}});

		splash.loadSplash(imageSkin);
		splash.alpha = 0.0001;

		if (splash.config != null) config = splash.config;
		else config = NoteSplash.createConfig();

		curAnim = null;
		refreshWidgetsFromConfig();
		parseRGB();
	}

	// ============ RGB 染色 ============
	function refreshRGBWidgets():Void
	{
		if (w_target == null || w_r == null) return; // 控件尚未创建
		syncingWidgets = true;
		var arr:Array<Int> = switch (w_target.selectedLabel)
		{
			case 'Red': redShader;
			case 'Green': greenShader;
			default: blueShader;
		}
		w_r.value = arr[0];
		w_g.value = arr[1];
		w_b.value = arr[2];
		w_no_replace.checked = switch (w_target.selectedLabel)
		{
			case 'Red': !redEnabled;
			case 'Green': !greenEnabled;
			default: !blueEnabled;
		}
		syncingWidgets = false;
	}

	function resetRGB():Void
	{
		redShader = [0, 0, 0];
		greenShader = [0, 0, 0];
		blueShader = [0, 0, 0];
	}

	function parseRGB():Void
	{
		resetRGB();
		redEnabled = blueEnabled = greenEnabled = false;
		if (config != null && config.rgb != null)
		{
			for (i in 0...config.rgb.length)
			{
				if (i > 2) break;
				var rgb = config.rgb[i];
				if (rgb == null) continue;
				if (i == 0) { redEnabled = true; redShader = [rgb.r, rgb.g, rgb.b]; }
				else if (i == 1) { greenEnabled = true; greenShader = [rgb.r, rgb.g, rgb.b]; }
				else if (i == 2) { blueEnabled = true; blueShader = [rgb.r, rgb.g, rgb.b]; }
			}
		}
		refreshRGBWidgets();
	}

	function setConfigRGB():Void
	{
		if (config == null) config = NoteSplash.createConfig();

		if (!redEnabled && !greenEnabled && !blueEnabled)
		{
			config.rgb = null;
			return;
		}

		config.rgb = [];
		config.rgb.push(redEnabled ? {r: redShader[0], g: redShader[1], b: redShader[2]} : null);
		config.rgb.push(greenEnabled ? {r: greenShader[0], g: greenShader[1], b: greenShader[2]} : null);
		config.rgb.push(blueEnabled ? {r: blueShader[0], g: blueShader[1], b: blueShader[2]} : null);
	}

	// ============ 控件回填 ============
	function refreshWidgetsFromConfig():Void
	{
		syncingWidgets = true;
		w_image.text = imageSkin;
		w_scale.value = config != null ? config.scale : 1;

		// 动画下拉
		var names:Array<String> = [];
		if (config != null && config.animations != null)
			for (k in config.animations.keys()) names.push(k);
		if (names.length < 1) names.push('');
		if (curAnim == null && names.length > 0 && names[0].length > 0) curAnim = names[0];
		w_anim.setData(FlxUIDropDownMenu.makeStrIdLabelArray(names, false));
		if (curAnim != null) w_anim.selectedLabel = curAnim;

		if (curAnim != null && config != null && config.animations.exists(curAnim))
		{
			var i:NoteSplashAnim = config.animations.get(curAnim);
			w_anim_name.text = i.name;
			w_prefix.text = i.prefix;
			w_note_data.value = i.noteData;
			w_min_fps.value = i.fps[0];
			w_max_fps.value = i.fps[1];
			if (i.indices != null && i.indices.length > 0)
				w_indices.text = i.indices.toString().substring(1, i.indices.toString().length - 1);
			else
				w_indices.text = '';
		}
		else
		{
			w_anim_name.text = '';
			w_prefix.text = '';
			w_note_data.value = 0;
			w_min_fps.value = 22;
			w_max_fps.value = 26;
			w_indices.text = '';
		}

		w_allow_rgb.checked = config != null && cast(config.allowRGB, Null<Bool>) != null ? config.allowRGB : true;
		w_allow_pixel.checked = config != null && cast(config.allowPixel, Null<Bool>) != null ? config.allowPixel : true;
		syncingWidgets = false;
		refreshRGBWidgets();
	}

	// ============ FlxUI 控件变更 ============
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (syncingWidgets) return;

		if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == w_scale)
			{
				if (config != null) config.scale = w_scale.value;
			}
			else if (sender == w_note_data || sender == w_min_fps || sender == w_max_fps)
			{
				if (curAnim != null && config != null && config.animations.exists(curAnim))
				{
					var i:NoteSplashAnim = config.animations.get(curAnim);
					if (sender == w_note_data) { i.noteData = Std.int(w_note_data.value); }
					else if (sender == w_min_fps) { i.fps[0] = Std.int(w_min_fps.value); }
					else { i.fps[1] = Std.int(w_max_fps.value); }
					config.animations.set(curAnim, i);
					config.scale = w_scale.value;
					if (sender == w_note_data) playStrumAnim(curAnim, i.noteData);
				}
			}
			else if (sender == w_r || sender == w_g || sender == w_b)
			{
				// ★ w_target 可能尚未创建（控件构造顺序 / 移动端裁剪 UI 时）——
				//   旧代码直接 selectedLabel 会空指针崩溃。
				if (w_target == null) return;
				var target:Array<Int> = switch (w_target.selectedLabel)
				{
					case 'Red': redShader;
					case 'Green': greenShader;
					default: blueShader;
				}
				if (sender == w_r) target[0] = Std.int(w_r.value);
				else if (sender == w_g) target[1] = Std.int(w_g.value);
				else target[2] = Std.int(w_b.value);
				setConfigRGB();
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == w_image)
			{
				imageSkin = w_image.text;
			}
			else if (curAnim != null && config != null && config.animations.exists(curAnim))
			{
				var i:NoteSplashAnim = config.animations.get(curAnim);
				if (sender == w_anim_name)
				{
					var newName:String = w_anim_name.text.trim();
					if (newName.length > 0 && newName != curAnim)
					{
						config.animations.remove(curAnim);
						i.name = newName;
						config.animations.set(newName, i);
						curAnim = newName;
						syncingWidgets = true;
						w_anim.selectedLabel = newName;
						syncingWidgets = false;
					}
				}
				else if (sender == w_prefix)
				{
					i.prefix = w_prefix.text;
					config.animations.set(curAnim, i);
				}
				else if (sender == w_indices)
				{
					var idx:Array<Int> = [];
					if (w_indices.text.trim().length > 0)
						for (p in w_indices.text.split(','))
						{
							var v:Null<Int> = Std.parseInt(p.trim());
							if (v != null) idx.push(v);
						}
					i.indices = idx;
					config.animations.set(curAnim, i);
				}
			}
		}
	}

	// ============ 预览 ============
	/**
	 * ★ 预览专用对象，只创建一次、后续反复复用。
	 *
	 * 旧实现在 playStrumAnim() 里 `new NoteSplash(...)`：而 update() 中只要按住方向键，
	 * `changedOffset` 每帧都会置 true → splashPreview() 每帧都会调到这里 →
	 * **每秒新建 60 个 NoteSplash**，而每个 NoteSplash 都自带一个 PixelSplashShader
	 * （FlxShader 实例）。FlxTypedGroup.add() 只回收 null 槽位、不回收已 kill 的成员，
	 * 这些对象既不会被销毁也不会被复用 —— 于是按住方向键几秒钟就能堆出成百上千个
	 * shader 实例。本工程 NotesSubState 里已经写明了这种「shader 实例无限增长」的后果：
	 * GL 的当前着色器/uniform 状态被冲垮，画面出现"伽马值减少"式发黑、逐轨染色错误的
	 * 现象，最终耗尽资源崩溃。这与「溅射调试里偶发 note 渲染错误 + 崩溃」完全吻合。
	 */
	var previewSplash:NoteSplash;

	function splashPreview():Void
	{
		if (config != null && config.animations.get(curAnim) != null)
		{
			playStrumAnim(curAnim, config.animations.get(curAnim).noteData);
			FlxTween.cancelTweensOf(errorText);
			errorText.alpha = 0;
		}
	}

	function playStrumAnim(?name:String, noteData:Int)
	{
		if (noteData < 0) noteData = 0;

		var splash:NoteSplash = previewSplash;
		if (splash == null)
		{
			splash = new NoteSplash(0, 0, imageSkin);
			splash.inEditor = true;
			splashes.add(splash);
			previewSplash = splash;
		}

		splash.inEditor = true;
		splash.config = config;

		if (name != null && splash.animation.exists(name))
		{
			splash.revive();

			// ★ 越界兜底：noteData 由面板上的步进器决定（0..999），取模后必须再夹一次
			var strumIndex:Int = noteData % 4;
			if (strumIndex < 0 || strumIndex >= strums.members.length) strumIndex = 0;
			splash.babyArrow = strums.members[strumIndex];

			splash.spawnSplashNote(0, 0, noteData, null, false);
			splash.alpha = 1;
		}
		else
		{
			errorText.alpha = 1;
			errorText.text = "ERROR while playing splash";
			FlxTween.cancelTweensOf(errorText);
			FlxTween.tween(errorText, {alpha: 0}, {startDelay: 1});
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (transitioning) return;

		errorText.x = FlxG.width - errorText.width - 5;

		// 状态栏刷新
		if (menuBar != null && menuBar.statusBar != null)
		{
			menuBar.statusBar.setSkin(imageSkin);
			menuBar.statusBar.setAnim(curAnim == null || curAnim.length < 1 ? 'NONE' : curAnim);
			if (config != null && curAnim != null && config.animations.exists(curAnim))
			{
				var offs:Array<Float> = config.animations.get(curAnim).offsets;
				if (offs == null) offs = [0, 0];
				menuBar.statusBar.setOffset(offs[0] + ' / ' + offs[1]);
				menuBar.statusBar.setNote('' + config.animations.get(curAnim).noteData);
			}
			menuBar.statusBar.setScale(config != null ? Std.string(config.scale) : '1');
		}

		// 输入弹层打字时屏蔽编辑器热键
		var typing:Bool = false;
		try
		{
			var wi:Dynamic = w_image;
			var wn:Dynamic = w_anim_name;
			var wp:Dynamic = w_prefix;
			var wix:Dynamic = w_indices;
			typing = (wi.hasFocus == true || wn.hasFocus == true || wp.hasFocus == true || wix.hasFocus == true);
		}
		catch (e:Dynamic) {}

		if (typing) return;

		if (config != null && config.animations != null && curAnim != null && curAnim.length > 0
			&& config.animations.exists(curAnim))
		{
			var changedOffset:Bool = false;
			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.C)
				{
					copiedOffset = config.animations.get(curAnim).offsets.copy();
				}
				else if (FlxG.keys.justPressed.V)
				{
					var conf = config.animations.get(curAnim);
					conf.offsets = copiedOffset.copy();
					config.animations.set(curAnim, conf);
					changedOffset = true;
				}
				else if (FlxG.keys.justPressed.R)
				{
					var conf = config.animations.get(curAnim);
					conf.offsets = [0, 0];
					config.animations.set(curAnim, conf);
					changedOffset = true;
				}
			}

			var multiplier:Int = (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER)) ? 10 : 1;

			var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
			if (moveKeysP.contains(true))
			{
				config.animations[curAnim].offsets[0] += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * multiplier;
				config.animations[curAnim].offsets[1] += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * multiplier;
				changedOffset = true;
			}

			var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
			if (moveKeys.contains(true))
			{
				holdingArrowsTime += elapsed;
				if (holdingArrowsTime > 0.6)
				{
					holdingArrowsElapsed += elapsed;
					while (holdingArrowsElapsed > (1 / 60))
					{
						config.animations[curAnim].offsets[0] += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * multiplier;
						config.animations[curAnim].offsets[1] += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * multiplier;
						holdingArrowsElapsed -= (1 / 60);
						changedOffset = true;
					}
				}
			}
			else holdingArrowsTime = 0;

			if (changedOffset || FlxG.keys.justPressed.SPACE) splashPreview();
		}

		if (FlxG.keys.justPressed.F1) openHelpMenu();
		if (controls.BACK || FlxG.keys.justPressed.ESCAPE) exitEditor();

		// 鼠标点音符触发溅射
		if (FlxG.mouse.overlaps(strums))
		{
			strums.forEach(function(strum:StrumNote)
			{
				if (FlxG.mouse.overlaps(strum))
				{
					if (!FlxG.mouse.justPressed)
					{
						// ★ curAnim 可能为 null（构造器不会自动播动画，且皮肤缺 'static' 时
						//   playAnim 也不会建出动画）—— 旧代码直接 .name 就是空指针崩溃。
						var curName:String = (strum.animation.curAnim != null) ? strum.animation.curAnim.name : null;
						if (curName != 'pressed' && curName != 'confirm')
							strum.playAnim('pressed');
					}
					else
					{
						strum.playAnim('confirm', true);

						// ★ 用 recycle 复用已死亡的对象，而不是每次 new：
						//   FlxTypedGroup.add 只回收 null 槽位，反复点击会让 group 与
						//   shader 实例无上限增长（同 playStrumAnim 的说明）。
						var splash:NoteSplash = splashes.recycle(NoteSplash, () -> new NoteSplash(0, 0, imageSkin));
						if (splash == null) return;

						splash.inEditor = true;
						splash.config = config;
						splash.babyArrow = strum;
						splash.spawnSplashNote(0, 0, strum.ID % 4);
						splash.alpha = 1;
					}
				}
				else strum.playAnim('static');
			});
		}
		else
		{
			for (strum in strums)
				strum.playAnim('static');
		}
	}

	function openHelpMenu():Void
	{
		if (menuBar == null) return;
		var helpIdx:Int = -1;
		for (i in 0...menuBar.menus.length)
			if (menuBar.menus[i].key == 'help') { helpIdx = i; break; }
		if (helpIdx > -1) menuBar.openMenu(helpIdx);
	}

	override function destroy()
	{
		NoteSplash.configs.clear();
		super.destroy();

		FlxG.sound.music.volume = 1;
		FlxG.sound.muteKeys = [FlxKey.ZERO];
		FlxG.sound.volumeDownKeys = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
		FlxG.sound.volumeUpKeys = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	}

	// ============ 保存 / TXT 转换 ============
	var _file:FileReference;
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveSplash()
	{
		imageSkin = w_image.text;
		var data:String = Json.stringify(config, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, imageSkin + ".json");
		}
	}

	public function loadTxt()
	{
		var jsonFilter:FileFilter = new FileFilter('Select a note splash TXT', '*.txt');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		try
		{
			var txtLoaded:Dynamic = Json.parse(Json.stringify(_file));
			var txt:String = null;
			var file:String = "config.json";
			#if MODS_ALLOWED
			if (txtLoaded.__path != null)
			{
				try txt = File.getContent(txtLoaded.__path) catch (e) txt = null;
				file = txtLoaded.__path;
				file = file.substring(0, file.length - 4) + ".json";
			}

			var conf = parseTxt(txt);
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(Json.stringify(conf, "\t"), file);
			#end
		}
		catch (e)
		{
			trace(e.stack);
		}
	}

	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	public static function parseTxt(content:String):NoteSplashConfig
	{
		var config = NoteSplash.createConfig();
		if (content == null)
			return config;

		var trim:String = content.trim();
		if (trim.length < 1) // empty txt
			return config;

		var configs = content.split('\n');
		// checks for empty txts
		if (configs.length < 2 || configs[0].trim() == "")
			return config;

		var animation:String = configs[0].rtrim();
		var fps:Array<Null<Int>> = [22, 26];
		if (configs[1] != null && configs[1].trim() != "")
		{
			var newFps = configs[1].trim().split(" ");
			fps = [Std.parseInt(newFps[0]), Std.parseInt(newFps[1])];
			if (fps[0] == null) fps[0] = 22;
			if (fps[1] == null) fps[1] = 26;
		}

		var offsets:Array<Array<Null<Float>>> = [[0, 0]];
		if (configs.length > 2)
		{
			offsets = [];
			for (i in 2...configs.length)
			{
				var offset = configs[i].trim();
				if (offset != "")
				{
					var offset:Array<String> = offset.split(" ");
					var x:Float = Std.parseFloat(offset[0]);
					var y:Float = Std.parseFloat(offset[1]);
					if (Math.isNaN(x)) x = 0;
					if (Math.isNaN(y)) y = 0;
					offsets.push([x, y]);
				}
			}
		}

		// NovaFlare: keep the same per-lane layout the runtime engine uses for legacy txts
		if (offsets.length < 1)
			offsets = [[0, 0]];

		var lanes:Array<String> = NoteSplash.laneNoteNames();
		var laneAmt:Int = lanes.length;
		var sets:Int = 1;
		if (offsets.length > 0)
			sets = Math.ceil(offsets.length / Note.colArray.length);
		if (sets < 1) sets = 1;

		for (k in 1...sets + 1)
		{
			for (lane in 0...laneAmt)
			{
				var offset:Array<Null<Float>> = offsets[FlxMath.wrap(lane + ((k - 1) * Note.colArray.length), 0, Std.int(offsets.length - 1))];
				var data:Int = lane + ((k - 1) * laneAmt);
				config = NoteSplash.addAnimationToConfig(config, 1, 'note$lane-$k', '$animation ${lanes[lane]} $k', fps, offset, [], data);
			}
		}

		return config;
	}
}
