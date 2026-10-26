package developer.editors;

// NF Chart Converter — ported from Impostor Legacy's ChartConverterState
// Uses vendored moonchart (source/moonchart_vendored/moonchart, MIT license, v0.5.1)
// Android adaptation: system SAF picker returns content:// URIs which cannot be read
// as filesystem paths. NF has no FileUtil browser on mobile, so this port uses a
// text-input flow (paste path) + a built-in scanner that auto-discovers chart/meta/
// other json files under common storage folders.

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxUIInputText;

import general.backend.MusicBeatState;
import general.objects.Alphabet;
import general.backend.Paths;

import moonchart.formats.fnf.legacy.FNFPsych;
import moonchart.formats.BasicFormat.DynamicFormat;
import moonchart.backend.Util.OneOfArray;
import moonchart.formats.BasicFormat.FormatDifficulty;


using StringTools;

class ChartConverterState extends MusicBeatState
{
	public static var goToFreeplay:Bool = false;

	var bg:FlxSprite;
	var txtGroup:FlxTypedGroup<Alphabet>;
	var descriptionBG:FlxSprite;
	var description:FlxText;
	var pathBG:FlxSprite;
	var pathLabel:FlxText;
	var pathInput:FlxUIInputText;
	var scanButton:Alphabet;
	var bgColour:FlxColor = 0xFF674B6C;

	var titleText:Alphabet;
	var curSelection:Int = 0;
	var canSelect:Bool = true;
	var phase:Int = 0; // 0 = mode select, 1 = path input

	static final MODES:Array<String> = ['From VSlice', 'From CNE', 'From Psych 1.0', 'From Vs. Impostor Extra'];

	override function create()
	{
		super.create();

		persistentUpdate = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF4D3551;
		add(bg);

		var titleText = new Alphabet(60, 40, 'Chart Converter', true);
		titleText.alpha = 0.4;
		add(titleText);
		this.titleText = titleText;

		txtGroup = new FlxTypedGroup<Alphabet>();
		add(txtGroup);

		for (i in 0...MODES.length)
		{
			var txt = new Alphabet(50, 170, MODES[i], true);
			txt.isMenuItem = true;
			txt.targetY = i;
			txtGroup.add(txt);
			txt.snapToPosition();
		}

		descriptionBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descriptionBG.alpha = 0.6;
		add(descriptionBG);

		description = new FlxText(25, 0, FlxG.width - 50, '', 26);
		description.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		description.borderSize = 2.4;
		add(description);

		// ---- path input phase UI ----
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

		// Mobile virtual pad (same style as MasterEditorMenu)
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
			updatePathPhase(elapsed);
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
			case 1: 0xFF4D2454;
			case 2: 0xFF354465;
			case 3: 0xFF674242;
			default: 0xFF674B6C;
		}

		var desc = switch (curSelection)
		{
			case 0: 'VSlice: chart.json + metadata.json → psych_v1 (one file per difficulty).\nProvide BOTH paths, comma separated.\nOutput: saves folder, named <song>-converted.json (-easy/-hard variants).';
			case 1: 'CNE: chart.json + meta.json → psych_v1.\nProvide BOTH paths, comma separated.\nOutput: saves folder, named <song>-converted.json.';
			case 2: 'Psych 1.0: normalize a chart for NovaFlare.\nProvide the chart json path.\nOutput: saves folder, named <song>-converted.json.';
			case 3: 'Impostor merge: main + other json → one psych_v1 chart (extra notes on lanes 8+).\nProvide BOTH paths, comma separated.\nOutput: saves folder, named after the MAIN chart.';
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
			case 0: 'VSlice mode: full path of chart json and metadata json, comma separated.\nExample: /storage/emulated/0/Download/Example-chart.json,/storage/emulated/0/Download/Example-metadata.json';
			case 1: 'CNE mode: full path of chart json and meta json, comma separated.\nExample: /storage/emulated/0/Download/Example.json,/storage/emulated/0/Download/Example-meta.json';
			case 2: 'Psych 1.0 mode: full path of the chart json.\nExample: /storage/emulated/0/Download/Example.json';
			case 3: 'Impostor merge: full path of main json and other json, comma separated.\nExample: /storage/emulated/0/Download/Song.json,/storage/emulated/0/Download/Song-other.json';
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

		description.text = 'Tap the box to type/paste. BACK to cancel.\nA button (or ENTER) to convert. SCAN lists chart jsons on storage.';
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

	function updatePathPhase(elapsed:Float)
	{
		if (controls.BACK)
		{
			if (pathInput.hasFocus)
				pathInput.hasFocus = false;
			else
				closePathInput();
			return;
		}

		var pressedEnter = FlxG.keys.justPressed.ENTER;

		// touch / mouse on SCAN
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
			description.text = 'SCAN: no chart jsons found in Download/Documents/storage root.\nType the full path manually.';
		}
		else
		{
			var list = '';
			for (i in 0...Std.int(Math.min(12, found.length)))
				list += found[i] + '\n';
			description.text = 'SCAN found ${found.length} chart jsons (newest first):\n$list'
				+ (found.length > 12 ? '(and ${found.length - 12} more...)\n' : '')
				+ 'Type one or two of them above.';
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
		#if sys
		try scanDir(Sys.getCwd(), results, 0) catch (e:Dynamic) {}
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
					else if (name.toLowerCase().endsWith('.json') && !name.startsWith('.'))
					{
						try
						{
							if (FileSystem.stat(p).size < 4194304)
							{
								var head = File.getContent(p);
								if (head.indexOf('"notes"') != -1
									|| head.indexOf('"strumLines"') != -1
									|| head.indexOf('"scrollSpeed"') != -1)
									out.push(p);
							}
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
			showError('No path given. Type the full path of the json file(s).');
			return;
		}

		for (i in 0...paths.length)
			paths[i] = normalizePath(paths[i]);

		switch (curSelection)
		{
			case 0: convertVSlice(paths);
			case 1: convertCNE(paths);
			case 2: convertPsych(paths);
			case 3: convertImpostor(paths);
		}
	}

	function normalizePath(p:String):String
	{
		if (p == null) return '';
		p = StringTools.trim(p);
		if (p.startsWith('content://'))
		{
			var marker = '/document/';
			var idx = p.indexOf(marker);
			if (idx != -1)
			{
				var docId = p.substr(idx + marker.length);
				try docId = StringTools.urlDecode(docId) catch (e:Dynamic) {}
				if (docId.startsWith('primary:'))
					return '/storage/emulated/0/' + docId.substr('primary:'.length);
				if (docId.startsWith('raw:'))
					return docId.substr('raw:'.length);
			}
			return p;
		}
		return p;
	}

	// ------------------------------------------------------------------
	// Converters
	// ------------------------------------------------------------------

	function convertVSlice(paths:Array<String>)
	{
		var pathToChart:String = null;
		var pathToMeta:String = null;
		for (f in paths)
		{
			var fl = f.toLowerCase();
			if (pathToChart == null && fl.indexOf('chart') != -1) pathToChart = f;
			if (pathToMeta == null && fl.indexOf('metadata') != -1) pathToMeta = f;
		}

		if (pathToChart == null || pathToMeta == null)
		{
			showError('VSlice needs BOTH a *chart* json and a *metadata* json.\nGot: ' + paths.join(', '));
			return;
		}
		if (!readable(pathToChart) || !readable(pathToMeta))
		{
			showUnreadable(pathToChart, pathToMeta);
			return;
		}

		try
		{
			var vSliceChart = new moonchart.formats.fnf.FNFVSlice().fromFile(pathToChart, pathToMeta);

			for (diff in vSliceChart.diffs)
			{
				var formattedPath = pathToChart.substr(0, pathToChart.length - 5);
				if (formattedPath.contains('-chart'))
					formattedPath = formattedPath.replace('-chart', '');
				var formattedDiff = diff == 'normal' ? '' : '-$diff';
				saveFromFormat(formattedPath + formattedDiff, vSliceChart, diff);
			}
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert VSlice chart.\n' + Std.string(e));
		}
	}

	function convertCNE(paths:Array<String>)
	{
		var pathToChart:String = null;
		var pathToMeta:String = null;
		for (f in paths)
		{
			var fl = f.toLowerCase();
			if (pathToChart == null && fl.indexOf('meta') == -1) pathToChart = f;
			if (pathToMeta == null && fl.indexOf('meta') != -1) pathToMeta = f;
		}

		if (pathToChart == null || pathToMeta == null)
		{
			showError('CNE needs BOTH a chart json and a *meta* json.\nGot: ' + paths.join(', '));
			return;
		}
		if (!readable(pathToChart) || !readable(pathToMeta))
		{
			showUnreadable(pathToChart, pathToMeta);
			return;
		}

		try
		{
			var cneChart = new moonchart.formats.fnf.FNFCodename().fromFile(pathToChart, pathToMeta);
			saveFromFormat(pathToChart, cneChart);
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert CNE chart.\n' + Std.string(e));
		}
	}

	function convertPsych(paths:Array<String>)
	{
		var path = paths[0];
		if (!readable(path))
		{
			showUnreadable(path);
			return;
		}
		try
		{
			if (!path.endsWith('.json'))
				throw 'Did not receive a json!';

			var p1Chart = new FNFPsych().fromFile(path);
			saveFromFormat(path, p1Chart);
		}
		catch (e:Dynamic)
		{
			showError('Failed to convert Psych chart.\n' + Std.string(e));
		}
	}

	function convertImpostor(paths:Array<String>)
	{
		var pathToMain:String = null;
		var pathToExtra:String = null;
		for (f in paths)
		{
			var fl = f.toLowerCase();
			if (pathToMain == null && fl.indexOf('other') == -1) pathToMain = f;
			if (pathToExtra == null && fl.indexOf('other') != -1) pathToExtra = f;
		}

		if (pathToMain == null || pathToExtra == null)
		{
			showError('Impostor merge needs BOTH a main json and an *other* json.\nGot: ' + paths.join(', '));
			return;
		}
		if (!readable(pathToMain) || !readable(pathToExtra))
		{
			showUnreadable(pathToMain, pathToExtra);
			return;
		}

		try
		{
			var mainChart = new FNFPsych().fromFile(pathToMain);
			var extraChart = new FNFPsych().fromFile(pathToExtra);

			var mainNotes:Array<Dynamic> = mainChart.data.song.notes;
			var extraNotes:Array<Dynamic> = extraChart.data.song.notes;
			if (mainNotes == null || extraNotes == null)
				throw 'One of the charts has no notes array.';

			var extraMustHits:Bool = false;
			for (s in extraNotes)
			{
				if (Reflect.hasField(s, 'mustHitSection') && s.mustHitSection)
				{
					extraMustHits = true;
					break;
				}
			}

			Reflect.setField(mainChart.data.song, 'lanes', 4);

			for (i => section in extraNotes)
			{
				var mainSection = mainNotes[i];
				if (mainSection != null)
				{
					for (noteDatas in (section.sectionNotes:Array<Dynamic>))
					{
						if (extraMustHits && section.mustHitSection)
							noteDatas[1] = ((noteDatas[1] + 4) % 8);
						noteDatas[1] += 8;
						mainSection.sectionNotes.push(noteDatas);
					}
				}
				else if (section.sectionNotes.length > 0)
				{
					mainNotes[i] = section;
				}
			}

			saveFromFormat(pathToMain, mainChart, null, false);
		}
		catch (e:Dynamic)
		{
			showError('Failed to merge Impostor charts.\n' + Std.string(e));
		}
	}

	// ------------------------------------------------------------------
	// Save & messages
	// ------------------------------------------------------------------

	function saveFromFormat(path:String, format:OneOfArray<DynamicFormat>, ?diff:FormatDifficulty, convert:Bool = true)
	{
		var nmvChart:DynamicFormat;
		if (convert)
		{
			nmvChart = new FNFPsych().fromFormat(format, diff);
			cast(nmvChart, FNFPsych).beautify = true;
		}
		else
		{
			nmvChart = format;
		}

		// Default output: NF saves folder (always writable, one fixed place).
		// If saves is somehow unavailable, fall back next to the source file.
		var safeName = newPathBase(path) + '-converted.json';
		var result = trySave('saves/' + safeName, nmvChart);
		if (result == null)
		{
			var target = path.replace('.json', '-converted.json');
			result = trySave(target, nmvChart);
		}

		if (result == null)
			throw 'failed to save.';

		showSuccess('Converted successfully!\nSaved to:\n$result');
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

	function trySave(target:String, chart:DynamicFormat):String
	{
		try
		{
			var r = chart.save(target);
			if (r == null) return null;
			return target;
		}
		catch (e:Dynamic)
		{
			return null;
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

	function showUnreadable(p:String, ?p2:String)
	{
		var msg = 'Cannot read file:\n$p' + (p2 != null ? '\n$p2' : '');
		if (p != null && p.startsWith('content://'))
		{
			msg += '\n\nThat is an Android content URI - the real file path is needed.\n'
				+ 'Open your file manager, find the file, copy its full path\n'
				+ '(starts with /storage/...) and paste it here.';
		}
		else
		{
			msg += '\nCheck the path for typos and make sure the file exists.';
		}
		showError(msg);
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
}
