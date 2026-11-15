package codename.funkin.menus;

#if MOD_SUPPORT
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import codename.funkin.backend.assets.ModsFolder;
import haxe.io.Path;
import sys.FileSystem;

class ModSwitchMenu extends MusicBeatSubstate {
	var disableConf:Map<String, Map<String, String>>;
	var modConf:Array<Map<String, Map<String, String>>> = [];
	var mods:Array<String> = [];
	var alphabets:FlxTypedGroup<Alphabet>;
	var curSelected:Int = 0;

	var subCam:FlxCamera;

	public override function create() {
		super.create();
		disableConf = ["Common" => ["NAME" => TU.translate("mods.disableMods")]];

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		var bg = new FlxSprite(0, 0).makeSolid(FlxG.width, FlxG.height, 0xFF000000);
		bg.updateHitbox();
		bg.scrollFactor.set();
		add(bg);

		bg.alpha = 0;
		FlxTween.tween(bg, {alpha: 0.5}, 0.25, {ease: FlxEase.cubeOut});

		mods = ModsFolder.getModsList({
		    descending: false,
			mode: CLEAN,
		});
		mods.push(null);

		alphabets = new FlxTypedGroup<Alphabet>();
		for(mod in mods) {
			var conf = (mod == null || Options.legacyModMenuNames) ? disableConf : ModsFolder.getModConfig(mod);
			modConf.push(conf);

			var name = (Options.legacyModMenuNames ? (mod ?? disableConf["Common"].get("NAME")) : ((conf.exists("Common") && conf["Common"].exists("NAME")) ? conf["Common"].get("NAME") : (mod ?? disableConf["Common"].get("NAME"))));
			if (name == "YOUR MOD NAME HERE")
				name = mod;

			var a = new Alphabet(0, 0, name, "bold");
			if(mod == ModsFolder.currentModFolder) {
				a.effects = [new codename.funkin.menus.ui.effects.ColorWaveEffect(0xFFFFFFFF, 0xFF00FF00, 10)];
				a.effects[0].speed = 10;
			}
			a.isMenuItem = true;
			a.scrollFactor.set();
			alphabets.add(a);
		}
		add(alphabets);
		changeSelection(0, true);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		var scroll = controls.touchC ? 0 : FlxG.mouse.wheel;
		changeSelection((controls.DOWN_P ? 1 : 0) + (controls.UP_P ? -1 : 0) - scroll);

		if (controls.ACCEPT) {
			ModsFolder.switchMod(mods[curSelected]);
			close();
		}

		if (controls.BACK)
			close();
	}

	public function changeSelection(change:Int, force:Bool = false) {
		if (change == 0 && !force) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, alphabets.length-1);

		CoolUtil.playMenuSFX(SCROLL, 0.7);

		for(k=>alphabet in alphabets.members) {
			alphabet.alpha = 0.6;
			alphabet.targetY = k - curSelected;
		}
		alphabets.members[curSelected].alpha = 1;
	}

	override function destroy() {
		super.destroy();

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);
	}
}
#end
