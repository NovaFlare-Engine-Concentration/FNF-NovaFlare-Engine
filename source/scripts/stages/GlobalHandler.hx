package scripts.stages;

class GlobalHandler {
	private static var grp:HScriptPack;

	public static function init() {
		if(grp != null) {
			grp.destroy();
		}
		grp = new HScriptPack();

		#if MODS_ALLOWED
		var paths:Array<String> = [];

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'stageScripts/globals/'))
			if(FileSystem.exists(folder) && FileSystem.isDirectory(folder)) paths.push(folder);

		for(path in paths) {
			for(fn in FileSystem.readDirectory(path)) {
				if(Path.extension(fn) == "hx") {
					var sc:HScript = new HScript(path + fn);
					grp.add(sc);
				}
			}
		}
		#end
		grp.execute();
		grp.call("onCreate");

		globalHandler();
	}

	static var sbCallbacks:Map<String, haxe.Constraints.Function>;
	public static function dispatchScriptUpdate(name:String, elapsed:Float):Void {
		if (grp != null) grp.call(name, [elapsed]);
	}

	private static function globalHandler() {
		if(sbCallbacks != null) {
			for(k=>v in sbCallbacks) {
				switch(k) {
					case "onStateSwitch":
						FlxG.signals.preStateSwitch.remove(cast v);
					case "onStateSwitchPost":
						FlxG.signals.postStateSwitch.remove(cast v);
					case "onStateCreate":
						FlxG.signals.preStateCreate.remove(cast v);
					case "onGameResized":
						FlxG.signals.gameResized.remove(cast v);
					case "onGameReset":
						FlxG.signals.preGameReset.remove(cast v);
					case "onGameResetPost":
						FlxG.signals.postGameReset.remove(cast v);
					case "onGameStart":
						FlxG.signals.preGameStart.remove(cast v);
					case "onGameStartPost":
						FlxG.signals.postGameStart.remove(cast v);
					case "onUpdate":
						FlxG.signals.preUpdate.remove(cast v);
					case "onUpdatePost":
						FlxG.signals.postUpdate.remove(cast v);
					case "onDraw":
						FlxG.signals.preDraw.remove(cast v);
					case "onDrawPost":
						FlxG.signals.postDraw.remove(cast v);
					case "onFocusGained":
						FlxG.signals.focusGained.remove(cast v);
					case "onFocusLost":
						FlxG.signals.focusLost.remove(cast v);
					case _:
				}
			}
		}

		sbCallbacks = new Map();
		for(id in ["onStateSwitch", "onStateSwitchPost", "onStateCreate", "onGameResized", "onGameReset", "onGameResetPost", "onGameStart", "onGameStartPost", "onUpdate", "onUpdatePost", "onDraw", "onDrawPost", "onFocusGained", "onFocusLost"]) {
			switch(id) {
				case "onStateSwitch":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.preStateSwitch.add(cast sbCallbacks.get(id));
				case "onStateSwitchPost":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.postStateSwitch.add(cast sbCallbacks.get(id));
				case "onStateCreate":
					sbCallbacks.set(id, function(state:FlxState) {
						GlobalHandler.grp.call(id, [state]);
					});
					FlxG.signals.preStateCreate.add(cast sbCallbacks.get(id));
				case "onGameResized":
					sbCallbacks.set(id, function(width:Int, height:Int) {
						GlobalHandler.grp.call(id, [width, height]);
					});
					FlxG.signals.gameResized.add(cast sbCallbacks.get(id));
				case "onGameReset":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.preGameReset.add(cast sbCallbacks.get(id));
				case "onGameResetPost":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.postGameReset.add(cast sbCallbacks.get(id));
				case "onGameStart":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.preGameStart.add(cast sbCallbacks.get(id));
				case "onGameStartPost":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.postGameStart.add(cast sbCallbacks.get(id));
				case "onUpdate", "onUpdatePost":
					sbCallbacks.set(id, function() {
						final elapsed = general.backend.NovaFlareGame.scriptElapsedForUpdate(FlxG.elapsed);
						if (elapsed != null) dispatchScriptUpdate(id, elapsed);
					});
					final signal = id == "onUpdate" ? FlxG.signals.preUpdate : FlxG.signals.postUpdate;
					signal.add(cast sbCallbacks.get(id));
				case "onDraw":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.preDraw.add(cast sbCallbacks.get(id));
				case "onDrawPost":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.postDraw.add(cast sbCallbacks.get(id));
				case "onFocusGained":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.focusGained.add(cast sbCallbacks.get(id));
				case "onFocusLost":
					sbCallbacks.set(id, function() {
						GlobalHandler.grp.call(id);
					});
					FlxG.signals.focusLost.add(cast sbCallbacks.get(id));
				case _:
			}
		}
	}

}
