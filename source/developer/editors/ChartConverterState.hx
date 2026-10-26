package developer.editors;

// NF Stage Converter — CNE / VSlice / PE stage format conversion
// Ported from V-Stuff (convertCodenameStage, convertVSliceToPsychStage,
// convertPsychStage). Output goes to saves/.

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

class StageConverterState extends MusicBeatState
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

	static final MODES:Array<String> = ['CNE XML → PE json', 'CNE XML → VSlice', 'VSlice → PE json', 'PE json → VSlice'];

	override function create()
	{
		super.create();

		persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF2D4A30;
		add(bg);

		titleText = new Alphabet(60, 40, 'Stage Converter', true);
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
			case 1: 0xFF6B5A4A;
			case 2: 0xFF5A3D5A;
			case 3: 0xFF4A5A6B;
			default: 0xFF5A4A3D;
		}

		var desc = switch (curSelection)
		{
			case 0: 'CNE stage XML → PE stage json + Lua props script.\nSprites, scroll factors and character layers are converted.';
			case 1: 'CNE stage XML → VSlice stage json.\nProps, characters and cameraZoom are converted.';
			case 2: 'VSlice stage json → PE stage json + Lua props.\nCharacter positions, camera offsets and props carry over.';
			case 3: 'PE stage json → VSlice stage json.\nCharacter positions and camera offsets carry over.';
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
			case 0: 'CNE→PE: full path of the stage XML.\nExample: /storage/emulated/0/Download/clubhouse.xml';
			case 1: 'CNE→VSlice: full path of the stage XML.\nExample: /storage/emulated/0/Download/clubhouse.xml';
			case 2: 'VSlice→PE: full path of the stage json.\nExample: /storage/emulated/0/Download/stage.json';
			case 3: 'PE→VSlice: full path of the PE stage json.\nExample: /storage/emulated/0/Download/stage.json';
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
			case 3: convertPEToVSlice(paths[0]);
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
	// Stage conversions (ported from V-Stuff)
	// ------------------------------------------------------------------

	function convertCNEToPE(path:String)
	{
		if (!readable(path)) { showUnreadable(path); return; }
		try
		{
			var xmlText = File.getContent(path);
			var root = Xml.parse(xmlText).firstElement();
			if (root == null || root.nodeName != 'stage')
				throw 'Not a CNE stage XML (root element is not <stage>).';

			var zoom = Std.parseFloat(root.get('zoom'));
			if (Math.isNaN(zoom)) zoom = 1;
			var folder = root.get('folder');
			if (folder == null) folder = '';

			var props:Array<Dynamic> = parseStageProps(root, folder);
			var charZ = parseCharZ(root);

			var maxCharZ = Std.int(Math.max(Math.max(charZ.bf > 0 ? charZ.bf : 0, charZ.dad > 0 ? charZ.dad : 0), charZ.gf > 0 ? charZ.gf : 0));

			var stageOut = {
				directory: 'shared',
				defaultZoom: zoom,
				isPixelStage: false,
				boyfriend: [0, 0],
				girlfriend: [0, 0],
				opponent: [0, 0],
				hide_girlfriend: charZ.gf < 0,
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};

			var lua = buildLua(props, maxCharZ);

			var base = newPathBase(path);
			var jsonSaved = saveJson('saves/' + base + '-stage.json', stageOut);
			var luaSaved = 'saves/' + base + '-stage-props.lua.txt';
			File.saveContent(luaSaved, lua);
			showSuccess('Stage CNE→PE done! (' + props.length + ' props)\nSaved:\n' + jsonSaved + '\n' + luaSaved);
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert stage.\n' + Std.string(e));
		}
	}

	function convertCNEToVSlice(path:String)
	{
		if (!readable(path)) { showUnreadable(path); return; }
		try
		{
			var xmlText = File.getContent(path);
			var root = Xml.parse(xmlText).firstElement();
			if (root == null || root.nodeName != 'stage')
				throw 'Not a CNE stage XML.';

			var zoom = Std.parseFloat(root.get('zoom'));
			if (Math.isNaN(zoom)) zoom = 1;
			var folder = root.get('folder');
			if (folder == null) folder = '';

			var props:Array<Dynamic> = parseStageProps(root, folder);
			var charZ = parseCharZ(root);

			var gfEntry:Dynamic = { position: [0, 0], cameraOffsets: [0, 0], zIndex: charZ.gf > 0 ? charZ.gf : 100 };
			if (charZ.gf < 0) gfEntry.alpha = 0;

			var out = {
				version: '1.0.2',
				name: root.get('name') != null ? root.get('name') : 'stage',
				props: props,
				characters: {
					bf: { position: [0, 0], cameraOffsets: [0, 0], zIndex: charZ.bf > 0 ? charZ.bf : 300 },
					dad: { position: [0, 0], cameraOffsets: [0, 0], zIndex: charZ.dad > 0 ? charZ.dad : 200 },
					gf: gfEntry
				},
				cameraZoom: zoom,
				directory: 'shared'
			};

			var saved = saveJson('saves/' + newPathBase(path) + '-vslice.json', out);
			showSuccess('Stage CNE→VSlice done! (' + props.length + ' props)\nSaved to:\n$saved');
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert stage.\n' + Std.string(e));
		}
	}

	function convertVSliceToPE(path:String)
	{
		if (!readable(path)) { showUnreadable(path); return; }
		try
		{
			var vJson:Dynamic = Json.parse(File.getContent(path));

			var chars:Dynamic = Reflect.hasField(vJson, 'characters') ? vJson.characters : {};
			var maxCharZ:Float = 0;
			if (Reflect.hasField(chars, 'bf') && chars.bf.zIndex > maxCharZ) maxCharZ = chars.bf.zIndex;
			if (Reflect.hasField(chars, 'dad') && chars.dad.zIndex > maxCharZ) maxCharZ = chars.dad.zIndex;
			if (Reflect.hasField(chars, 'gf') && chars.gf.zIndex > maxCharZ) maxCharZ = chars.gf.zIndex;

			var gfHidden = !Reflect.hasField(chars, 'gf') || (Reflect.hasField(chars.gf, 'alpha') && chars.gf.alpha == 0);


			var out = {
				directory: Reflect.hasField(vJson, 'directory') ? Std.string(vJson.directory) : '',
				defaultZoom: Reflect.hasField(vJson, 'cameraZoom') ? vJson.cameraZoom : 1,
				isPixelStage: false,
				boyfriend: charPosOf(chars, 'bf'),
				girlfriend: charPosOf(chars, 'gf'),
				opponent: charPosOf(chars, 'dad'),
				hide_girlfriend: gfHidden,
				camera_boyfriend: charCamOf(chars, 'bf'),
				camera_opponent: charCamOf(chars, 'dad'),
				camera_girlfriend: charCamOf(chars, 'gf'),
				camera_speed: 1
			};

			var props:Array<Dynamic> = Reflect.hasField(vJson, 'props') ? vJson.props : [];
			var lua = buildLua(props, maxCharZ);

			var base = newPathBase(path);
			var jsonSaved = saveJson('saves/' + base + '-stage.json', out);
			var luaSaved = 'saves/' + base + '-stage-props.lua.txt';
			File.saveContent(luaSaved, lua);
			showSuccess('Stage VSlice→PE done!\nSaved:\n' + jsonSaved + '\n' + luaSaved);
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert stage.\n' + Std.string(e));
		}
	}

	function convertPEToVSlice(path:String)
	{
		if (!readable(path)) { showUnreadable(path); return; }
		try
		{
			var peJson:Dynamic = Json.parse(File.getContent(path));

			var characters:Dynamic = {};
			if (Reflect.hasField(peJson, 'boyfriend'))
				Reflect.setField(characters, 'bf', { zIndex: 300, position: peJson.boyfriend, cameraOffsets: Reflect.hasField(peJson, 'camera_boyfriend') ? peJson.camera_boyfriend : [0, 0] });
			if (Reflect.hasField(peJson, 'opponent'))
				Reflect.setField(characters, 'dad', { zIndex: 200, position: peJson.opponent, cameraOffsets: Reflect.hasField(peJson, 'camera_opponent') ? peJson.camera_opponent : [0, 0] });
			if (!Reflect.hasField(peJson, 'hide_girlfriend') || !peJson.hide_girlfriend)
			{
				if (Reflect.hasField(peJson, 'girlfriend'))
					Reflect.setField(characters, 'gf', { zIndex: 100, position: peJson.girlfriend, cameraOffsets: Reflect.hasField(peJson, 'camera_girlfriend') ? peJson.camera_girlfriend : [0, 0] });
			}

			var out = {
				props: [],
				cameraZoom: Reflect.hasField(peJson, 'defaultZoom') ? peJson.defaultZoom : 1,
				version: '1.0.0',
				characters: characters,
				name: Reflect.hasField(peJson, 'directory') ? Std.string(peJson.directory) : 'stage',
				directory: Reflect.hasField(peJson, 'directory') ? Std.string(peJson.directory) : ''
			};

			var saved = saveJson('saves/' + newPathBase(path) + '-vslice.json', out);
			showSuccess('Stage PE→VSlice done!\nNote: PE stage props live in Lua — copy them manually if needed.\nSaved to:\n$saved');
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert stage.\n' + Std.string(e));
		}
	}


	static function charPosOf(chars:Dynamic, key:String):Array<Dynamic>
	{
		if (Reflect.hasField(chars, key) && Reflect.hasField(Reflect.field(chars, key), 'position'))
			return Reflect.field(Reflect.field(chars, key), 'position');
		return [0, 0];
	}

	static function charCamOf(chars:Dynamic, key:String):Array<Dynamic>
	{
		if (Reflect.hasField(chars, key) && Reflect.hasField(Reflect.field(chars, key), 'cameraOffsets'))
			return Reflect.field(Reflect.field(chars, key), 'cameraOffsets');
		return [0, 0];
	}

	// ---- shared helpers ----

	function parseStageProps(root:Xml, folder:String):Array<Dynamic>
	{
		var props:Array<Dynamic> = [];
		var z:Int = 10;
		for (node in root.elements())
		{
			var tag = node.nodeName.toLowerCase();
			if (tag != 'sprite') continue;
			var name = node.get('name');
			if (name == null) name = 'prop' + props.length;
			var spriteName = node.get('sprite');
			if (spriteName == null) spriteName = name;
			var x = Std.parseFloat(node.get('x'));
			if (Math.isNaN(x)) x = 0;
			var y = Std.parseFloat(node.get('y'));
			if (Math.isNaN(y)) y = 0;
			var scroll = Std.parseFloat(node.get('scroll'));
			if (Math.isNaN(scroll)) scroll = 1;

			var entry:Dynamic = {
				name: name,
				assetPath: folder + spriteName,
				position: [x, y],
				scroll: [scroll, scroll],
				zIndex: z
			};
			props.push(entry);
			z += 10;
		}
		return props;
	}

	function parseCharZ(root:Xml):{bf:Int, dad:Int, gf:Int}
	{
		var bf:Int = -1, dad:Int = -1, gf:Int = -1;
		var z:Int = 10;
		for (node in root.elements())
		{
			var tag = node.nodeName.toLowerCase();
			if (tag == 'sprite') z += 10;
			else if (tag == 'girlfriend' || tag == 'gf') { gf = z; z += 10; }
			else if (tag == 'dad' || tag == 'opponent') { dad = z; z += 10; }
			else if (tag == 'boyfriend' || tag == 'bf') { bf = z; z += 10; }
		}
		return { bf: bf, dad: dad, gf: gf };
	}

	function buildLua(props:Array<Dynamic>, maxCharZ:Float):String
	{
		var lua = new StringBuf();
		lua.add('function onCreate()\n');
		for (prop in props)
		{
			var pos:Array<Dynamic> = prop.position;
			lua.add('\tmakeLuaSprite(\'' + prop.name + '\', \'' + prop.assetPath + '\', ' + pos[0] + ', ' + pos[1] + ')\n');
			var sc:Array<Dynamic> = prop.scroll;
			if (sc[0] != 1 || sc[1] != 1)
				lua.add('\tsetScrollFactor(\'' + prop.name + '\', ' + sc[0] + ', ' + sc[1] + ')\n');
			var fg:Bool = prop.zIndex > maxCharZ;
			lua.add('\taddLuaSprite(\'' + prop.name + '\'' + (fg ? ', true' : '') + ')\n\n');
		}
		lua.add('end\n');
		return lua.toString();
	}

}
