package scripts.stages;

/**
 * @see 自个查
 * 总之就是先这样再那样最后那样就没了（
 */
class HScriptSubstate extends MusicBeatSubstate {
	public static final sign:String = "substates";

	public var scriptName:String;
	public var scriptData:Null<Dynamic>;

	private var stateScripts:HScriptPack;

	public function new(name:String, ?data:Null<Dynamic>) {
		stateScripts = new HScriptPack();

		this.scriptName = name;
		this.scriptData = data;
		#if MODS_ALLOWED
		var paths:Array<String> = [];

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), "stageScripts/" + sign + "/"))
			if(FileSystem.exists(folder) && FileSystem.isDirectory(folder)) paths.push(folder);

		for(path in paths) {
			for(fn in FileSystem.readDirectory(path)) {
				if(Path.extension(fn) == "hx") {
					var sc:HScript = new HScript(path + fn, this);
					sc.set("MusicBeatState", MusicBeatState);
					sc.set("MusicBeatSubstate", MusicBeatSubstate);
					stateScripts.add(sc);
				}
			}
		}
		#end
		stateScripts.execute();

		super();
	}

	override function create() {
		stateScripts.call("onCreate");
		super.create();
		stateScripts.call("onCreatePost");
	}

	override function update(elapsed:Float) {
		final scriptElapsed = general.backend.NovaFlareGame.scriptElapsedForUpdate(elapsed);
		if (scriptElapsed != null) stateScripts.call("onUpdate", [scriptElapsed]);
		super.update(elapsed);
		if (scriptElapsed != null) stateScripts.call("onUpdatePost");
	}

	override public function drawUpdate(elapsed:Float):Void {
		final runScriptUpdate = general.backend.NovaFlareGame.scriptUpdateActive;
		if (runScriptUpdate) stateScripts.call("onUpdate", [general.backend.NovaFlareGame.scriptUpdateElapsed]);
		super.drawUpdate(elapsed);
		if (runScriptUpdate) stateScripts.call("onUpdatePost");
	}

	override function draw() {
		stateScripts.call("onDraw");
		super.draw();
		stateScripts.call("onDrawPost");
	}

	override function openSubState(SubState:FlxSubState) {
		stateScripts.call("onOpenSubState", [SubState]);
		super.openSubState(SubState);
		stateScripts.call("onOpenSubStatePost", [SubState]);
	}

	override function closeSubState() {
		stateScripts.call("onCloseSubState");
		super.closeSubState();
		stateScripts.call("onCloseSubStatePost");
	}

	override function close() {
		stateScripts.call("onClose");
		super.close();
		stateScripts.call("onClosePost");
	}

	override function onFocusLost() {
		stateScripts.call("onFocusLost");
		super.onFocusLost();
	}

	override function onFocus() {
		stateScripts.call("onFocus");
		super.onFocus();
	}

	override function onResize(Width:Int, Height:Int) {
		stateScripts.call("onResize", [Width, Height]);
		super.onResize(Width, Height);
	}

	override function stepHit() {
		stateScripts.call("onStepHit");
		super.stepHit();
	}

	override function beatHit() {
		stateScripts.call("onBeatHit");
		super.beatHit();
	}

	override function sectionHit() {
		stateScripts.call("onSectionHit");
		super.beatHit();
	}

	override function destroy() {
		stateScripts.destroy(true);
		super.destroy();
	}
}
