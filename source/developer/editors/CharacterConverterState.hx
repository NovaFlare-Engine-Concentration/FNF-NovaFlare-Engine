package developer.editors;

// NF Character Converter — CNE / VSlice / PE character format conversion
// Ported from V-Stuff (convertCodenameCharacter, convertVSliceToPsychCharacter,
// convertCodenameToPsychCharacter). Output goes to saves/.

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIInputText;

import general.backend.MusicBeatState;
import general.objects.Alphabet;
import general.backend.Paths;

import haxe.Json;
import sys.io.File;
import sys.FileSystem;

using StringTools;

class CharacterConverterState extends MusicBeatState
{
	var bg:FlxSprite;
	var txtGroup:FlxTypedGroup<Alphabet>;
	var descriptionBG:FlxSprite;
	var description:FlxText;
	var pathBG:FlxSprite;
	var pathLabel:FlxText;
	var pathInput:FlxUIInputText;
	var scanButton:Alphabet;
	var titleText:Alphabet;
	var bgColour:FlxColor = 0xFF3D5A40;

	var curSelection:Int = 0;
	var canSelect:Bool = true;
	var phase:Int = 0;

	static final MODES:Array<String> = ['CNE XML → PE json', 'CNE XML → VSlice', 'VSlice → PE json'];

	override function create()
	{
		super.create();

		persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF2D4A30;
		add(bg);

		titleText = new Alphabet(60, 40, 'Character Converter', true);
		titleText.alpha = 0.4;
		add(titleText);

		txtGroup = new FlxTypedGroup<Alphabet>();
		add(txtGroup);

		for (i in 0...MODES.length)
		{
			var txt = new Alphabet(50, 170, MODES[i], true);
			txt.isMenuItem = true;
			txt.targetY = i;
			txtGroup.add(txt);
		}

		descriptionBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descriptionBG.alpha = 0.6;
		add(descriptionBG);

		description = new FlxText(25, 0, FlxG.width - 50, '', 26);
		description.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, CENTER);
		description.borderSize = 2.4;
		add(description);

		pathBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		pathBG.alpha = 0.7;
		pathBG.visible = false;
		add(pathBG);

		pathLabel = new FlxText(25, 0, FlxG.width - 50, '', 22);
		pathLabel.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, LEFT);
		pathLabel.visible = false;
		add(pathLabel);

		pathInput = new FlxUIInputText(25, 0, FlxG.width - 60, '', 20);
		pathInput.visible = false;
		add(pathInput);

		scanButton = new Alphabet(25, 0, 'SCAN STORAGE', true);
		scanButton.visible = false;
		scanButton.alpha = 0.8;
		add(scanButton);

		#if mobile
		addVirtualPad(LEFT_FULL, A_B);
		addVirtualPadCamera();
		#end

		changeSel();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (phase == 1)
		{
			updatePathPhase();
			return;
		}

		if (canSelect)
		{
			if (controls.UI_DOWN_P || controls.UI_UP_P)
				changeSel(controls.UI_DOWN_P ? 1 : -1);
			if (controls.ACCEPT)
				openPathInput();
			if (controls.BACK)
			{
				canSelect = false;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
		}

		for (k => i in txtGroup.members)
		{
			var target = (k == curSelection) ? 1.0 : 0.5;
			i.alpha = FlxMath.lerp(i.alpha, target, 0.15);
		}

		bg.color = FlxColor.interpolate(bg.color, bgColour, 0.1);
	}

	function changeSel(diff:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelection = FlxMath.wrap(curSelection + diff, 0, MODES.length - 1);

		for (k => i in txtGroup.members)
			i.targetY = k - curSelection;

		bgColour = switch (curSelection)
		{
			case 1: 0xFF4A6B4E;
			case 2: 0xFF3D5A5A;
			default: 0xFF3D5A40;
		}

		var desc = switch (curSelection)
		{
			case 0: 'CNE character XML → PE/NF character json.\nAnimations, offsets, icon, flip and healthbar color are converted.';
			case 1: 'CNE character XML → VSlice character json.\nAtlas format, camera offsets and death block are handled.';
			case 2: 'VSlice character json → PE character json.\nAnimations, scale, singTime and icon are converted.';
			default: '';
		}
		description.text = desc;
		layoutDescription();
	}

	function layoutDescription()
	{
		description.y = FlxG.height - description.height - 40;
		descriptionBG.setPosition(description.x - 10, description.y - 10);
		descriptionBG.scale.set(description.width + 20, description.height + 25);
		descriptionBG.updateHitbox();
	}

	function openPathInput()
	{
		phase = 1;
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		txtGroup.visible = false;
		titleText.visible = false;

		var prompt = switch (curSelection)
		{
			case 0: 'CNE→PE: full path of the character XML.\nExample: /storage/emulated/0/Download/dad.xml';
			case 1: 'CNE→VSlice: full path of the character XML.\nExample: /storage/emulated/0/Download/dad.xml';
			case 2: 'VSlice→PE: full path of the character json.\nExample: /storage/emulated/0/Download/dad.json';
			default: '';
		}
		pathLabel.text = prompt;
		pathLabel.setPosition(25, 150);
		pathLabel.visible = true;

		pathBG.setPosition(15, 260);
		pathBG.scale.set(FlxG.width - 30, 80);
		pathBG.updateHitbox();
		pathBG.visible = true;

		pathInput.setPosition(25, 282);
		pathInput.visible = true;

		scanButton.setPosition(25, 390);
		scanButton.visible = true;

		description.text = 'Tap the box to type/paste. BACK to cancel.\nA button (or ENTER) to convert. SCAN lists files on storage.';
		layoutDescription();
	}

	function closePathInput()
	{
		phase = 0;
		txtGroup.visible = true;
		titleText.visible = true;
		pathInput.visible = false;
		pathInput.text = '';
		pathLabel.visible = false;
		pathBG.visible = false;
		scanButton.visible = false;
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
		changeSel();
	}

	function updatePathPhase()
	{
		if (controls.BACK)
		{
			if (pathInput.hasFocus)
				pathInput.hasFocus = false;
			else
				closePathInput();
			return;
		}

		#if mobile
		for (t in FlxG.touches.list)
		{
			if (t.justPressed && t.x >= scanButton.x && t.x <= scanButton.x + scanButton.width
				&& t.y >= scanButton.y && t.y <= scanButton.y + scanButton.height)
			{
				runScan();
				return;
			}
		}
		#end
		if (FlxG.mouse.justPressed && FlxG.mouse.x >= scanButton.x && FlxG.mouse.x <= scanButton.x + scanButton.width
			&& FlxG.mouse.y >= scanButton.y && FlxG.mouse.y <= scanButton.y + scanButton.height)
		{
			runScan();
			return;
		}

		var pressedEnter = FlxG.keys.justPressed.ENTER;
		if ((pressedEnter && !pathInput.hasFocus) || (controls.ACCEPT && !pathInput.hasFocus))
		{
			runConvert(pathInput.text);
		}
	}

	function runScan()
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		var found = scanStorage();
		if (found.length == 0)
		{
			description.text = 'SCAN: no xml/json files found in common folders.\nType the full path manually.';
		}
		else
		{
			var list = '';
			for (i in 0...Std.int(Math.min(12, found.length)))
				list += found[i] + '\n';
			description.text = 'SCAN found ${found.length} files (newest first):\n$list'
				+ (found.length > 12 ? '(and ${found.length - 12} more...)\n' : '');
		}
		layoutDescription();
	}

	function scanStorage():Array<String>
	{
		var results:Array<String> = [];

		#if android
		var roots:Array<String> = [
			'/storage/emulated/0/Download',
			'/storage/emulated/0/Documents',
			'/storage/emulated/0'
		];
		for (root in roots)
			scanDir(root, results, 0);
		#end

		results.sort(function(a, b)
		{
			try
			{
				return Std.int(FileSystem.stat(b).mtime.getTime() - FileSystem.stat(a).mtime.getTime());
			}
			catch (e:Dynamic) return 0;
		});
		return results;
	}

	function scanDir(dir:String, out:Array<String>, depth:Int)
	{
		if (depth > 2 || out.length > 200) return;
		try
		{
			for (name in FileSystem.readDirectory(dir))
			{
				var p = (dir == '/' ? '' : dir) + '/' + name;
				try
				{
					if (FileSystem.isDirectory(p))
					{
						var n = name.toLowerCase();
						if (n == 'android' || n == 'dcim' || n == 'pictures' || n == 'movies'
							|| n == 'music' || n == 'ringtones' || n == 'alarms' || n == 'notifications'
							|| n == 'audiobooks' || n == 'podcasts' || n == 'recordings')
							continue;
						scanDir(p, out, depth + 1);
					}
					else if ((name.toLowerCase().endsWith('.xml') || name.toLowerCase().endsWith('.json')) && !name.startsWith('.'))
					{
						try
						{
							if (FileSystem.stat(p).size < 1048576)
								out.push(p);
						}
						catch (e:Dynamic) {}
					}
				}
				catch (e:Dynamic) {}
			}
		}
		catch (e:Dynamic) {}
	}

	function runConvert(rawText:String)
	{
		var paths:Array<String> = [];
		for (p in rawText.split(','))
		{
			p = StringTools.trim(p);
			if (p != '') paths.push(p);
		}
		if (paths.length == 0)
		{
			showError('No path given. Type the full path of the file.');
			return;
		}

		switch (curSelection)
		{
			case 0: convertCNEToPE(paths[0]);
			case 1: convertCNEToVSlice(paths[0]);
			case 2: convertVSliceToPE(paths[0]);
		}
	}

	function readable(p:String):Bool
	{
		try
		{
			return FileSystem.exists(p) && !FileSystem.isDirectory(p);
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	function showUnreadable(p:String)
	{
		showError('Cannot read file:\n$p\nCheck the path for typos and make sure the file exists.');
	}

	function showError(msg:String)
	{
		description.text = msg;
		layoutDescription();
		FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);
	}

	function showSuccess(msg:String)
	{
		description.text = msg;
		layoutDescription();
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
	}

	function newPathBase(path:String):String
	{
		var base = path;
		var slash = base.lastIndexOf('/');
		if (slash != -1) base = base.substr(slash + 1);
		var dot = base.lastIndexOf('.');
		if (dot != -1) base = base.substr(0, dot);
		return Paths.formatToSongPath(base);
	}

	function saveJson(target:String, data:Dynamic):String
	{
		File.saveContent(target, Json.stringify(data, null, '\t'));
		return target;
	}

	// ------------------------------------------------------------------
	// Conversions (ported from V-Stuff)
	// ------------------------------------------------------------------

	function convertCNEToPE(path:String)
	{
		if (!readable(path)) { showUnreadable(path); return; }
		try
		{
			var xmlText = File.getContent(path);
			var root = Xml.parse(xmlText).firstElement();
			if (root == null || root.nodeName != 'character')
				throw 'Not a CNE character XML (root element is not <character>).';

			var offsetX = Std.parseFloat(root.get('x'));
			if (Math.isNaN(offsetX)) offsetX = 0;
			var offsetY = Std.parseFloat(root.get('y'));
			if (Math.isNaN(offsetY)) offsetY = 0;
			var spriteName = root.get('sprite');
			if (spriteName == null) spriteName = '';
			var flipX = root.get('flipX') == 'true';
			var icon = root.get('icon');
			if (icon == null) icon = '';
			var isPlayer = root.get('isPlayer') == 'true';
			var colorHex = root.get('color');
			if (colorHex == null) colorHex = '';

			var anims:Array<Dynamic> = [];
			for (el in root.elements())
			{
				if (el.nodeName != 'anim') continue;
				var ax = Std.parseFloat(el.get('x'));
				if (Math.isNaN(ax)) ax = 0;
				var ay = Std.parseFloat(el.get('y'));
				if (Math.isNaN(ay)) ay = 0;
				var fps = Std.parseFloat(el.get('fps'));
				if (Math.isNaN(fps)) fps = 24;
				var animName = el.get('name');
				if (animName == null) animName = el.get('anim');
				if (animName == null) animName = '';
				var prefix = el.get('anim');
				if (prefix == null) prefix = animName;
				anims.push({
					loop: el.get('loop') == 'true',
					offsets: [ax, ay],
					anim: animName,
					fps: Std.int(fps),
					name: prefix,
					indices: []
				});
			}

			var out = {
				animations: anims,
				vocals_file: '',
				no_antialiasing: false,
				image: 'characters/' + spriteName,
				position: [offsetX, offsetY],
				healthicon: icon,
				flip_x: flipX,
				healthbar_colors: hexToRgb(colorHex),
				sing_duration: 4,
				scale: 1,
				_editor_isPlayer: isPlayer
			};

			var saved = saveJson('saves/' + newPathBase(path) + '-character.json', out);
			showSuccess('Character CNE→PE done!\nSaved to:\n$saved');
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert character.\n' + Std.string(e));
		}
	}

	function convertCNEToVSlice(path:String)
	{
		if (!readable(path)) { showUnreadable(path); return; }
		try
		{
			var xmlText = File.getContent(path);
			var root = Xml.parse(xmlText).firstElement();
			if (root == null || root.nodeName != 'character')
				throw 'Not a CNE character XML.';

			var offsetX = Std.parseFloat(root.get('x'));
			if (Math.isNaN(offsetX)) offsetX = 0;
			var offsetY = Std.parseFloat(root.get('y'));
			if (Math.isNaN(offsetY)) offsetY = 0;
			var spriteName = root.get('sprite');
			if (spriteName == null) spriteName = '';
			var flipX = root.get('flipX') == 'true';
			var icon = root.get('icon');
			if (icon == null) icon = '';

			var anims:Array<Dynamic> = [];
			var startingAnimation:String = null;
			for (el in root.elements())
			{
				if (el.nodeName != 'anim') continue;
				var ax = Std.parseFloat(el.get('x'));
				if (Math.isNaN(ax)) ax = 0;
				var ay = Std.parseFloat(el.get('y'));
				if (Math.isNaN(ay)) ay = 0;
				var fps = Std.parseFloat(el.get('fps'));
				if (Math.isNaN(fps)) fps = 24;
				var animName = el.get('name');
				if (animName == null) animName = '';
				var prefix = el.get('anim');
				if (prefix == null) prefix = animName;
				if (startingAnimation == null) startingAnimation = animName;
				var entry:Dynamic = {
					name: animName,
					prefix: prefix,
					offsets: [ax, ay],
					frameRate: Std.int(fps),
					looped: el.get('loop') == 'true',
					animType: 'framelabel',
					flipX: false,
					flipY: false
				};
				anims.push(entry);
			}

			var out:Dynamic = {
				version: '1.0.0',
				name: guessDisplayName(spriteName),
				renderType: 'multianimateatlas',
				assetPath: 'shared:characters/' + spriteName.toLowerCase(),
				scale: 1,
				singTime: 4,
				startingAnimation: startingAnimation,
				flipX: flipX,
				offsets: [offsetX, offsetY],
				cameraOffsets: [0, 0],
				animations: anims
			};
			if (icon != '') out.healthIcon = { id: icon };

			var saved = saveJson('saves/' + newPathBase(path) + '-vslice.json', out);
			showSuccess('Character CNE→VSlice done!\nSaved to:\n$saved');
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert character.\n' + Std.string(e));
		}
	}

	function convertVSliceToPE(path:String)
	{
		if (!readable(path)) { showUnreadable(path); return; }
		try
		{
			var vJson:Dynamic = Json.parse(File.getContent(path));

			var outAnims:Array<Dynamic> = [];
			var anims:Array<Dynamic> = vJson.animations;
			if (anims != null)
			{
				for (a in anims)
				{
					var offs:Array<Dynamic> = Reflect.hasField(a, 'offsets') ? a.offsets : [0, 0];
					var prefix:String = Reflect.hasField(a, 'prefix') ? Std.string(a.prefix) : Std.string(Reflect.field(a, 'name'));
					var fps:Float = Reflect.hasField(a, 'frameRate') ? a.frameRate : 24;
					outAnims.push({
						loop: Reflect.hasField(a, 'looped') && a.looped,
						offsets: [offs[0], offs[1]],
						anim: Reflect.field(a, 'name'),
						fps: Std.int(fps),
						name: prefix,
						indices: []
					});
				}
			}

			var assetPath:String = Reflect.hasField(vJson, 'assetPath') ? Std.string(vJson.assetPath) : '';
			var image = assetPath;
			if (image.startsWith('shared:')) image = image.substr('shared:'.length);

			var healthicon:String = '';
			if (Reflect.hasField(vJson, 'healthIcon'))
				healthicon = Std.string(Reflect.field(Reflect.field(vJson, 'healthIcon'), 'id'));

			var out = {
				animations: outAnims,
				vocals_file: '',
				no_antialiasing: false,
				image: image,
				position: [0, 0],
				healthicon: healthicon,
				flip_x: Reflect.hasField(vJson, 'flipX') && vJson.flipX,
				healthbar_colors: [0, 0, 0],
				sing_duration: Reflect.hasField(vJson, 'singTime') ? vJson.singTime : 4,
				scale: Reflect.hasField(vJson, 'scale') ? vJson.scale : 1,
				_editor_isPlayer: false
			};

			var saved = saveJson('saves/' + newPathBase(path) + '-character.json', out);
			showSuccess('Character VSlice→PE done!\nSaved to:\n$saved');
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert character.\n' + Std.string(e));
		}
	}

	function guessDisplayName(spriteName:String):String
	{
		if (spriteName == null || spriteName == '') return 'Character';
		var base = spriteName;
		var slash = base.lastIndexOf('/');
		if (slash != -1) base = base.substr(slash + 1);
		base = base.charAt(0).toUpperCase() + base.substr(1);
		return base;
	}

	function hexToRgb(hex:String):Array<Int>
	{
		if (hex == null || hex == '') return [0, 0, 0];
		var h = hex;
		if (h.charAt(0) == '#') h = h.substr(1);
		if (h.length == 6)
		{
			var r = Std.parseInt('0x' + h.substr(0, 2));
			var g = Std.parseInt('0x' + h.substr(2, 2));
			var b = Std.parseInt('0x' + h.substr(4, 2));
			if (r == null || g == null || b == null) return [0, 0, 0];
			return [r, g, b];
		}
		return [0, 0, 0];
	}
}
