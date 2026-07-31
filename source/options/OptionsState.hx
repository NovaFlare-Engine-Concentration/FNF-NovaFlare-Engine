package options;

import states.mainMenuState.MainMenuState;
import states.freeplayState.FreeplayState;

import options.base.NewControlsSubState;

import mobile.substates.MobileControlSelectSubState;
import mobile.substates.MobileExtraControl;
import mobile.states.CopyState;

import games.backend.StageData;
import general.backend.ui.PsychUIInputText;

class OptionsState extends MusicBeatState
{
	public static var instance:OptionsState;

	var filePath:String = 'menuExtend/OptionsState/';

	var naviArray:Array<NaviData> = [];

	////////////////////////////////////////////////////////////////////////////////////////////

	public var baseColor = 0x302E3A;
	public var mainColor = 0x24232C;

	////////////////////////////////////////////////////////////////////////////////////////////

	public var mouseEvent:MouseEvent;

	var naviBG:Rect;
	var naviGroup:Array<NaviGroup> = [];
	var naviMove:MouseMove;

	public var cataGroup:Array<OptionCata> = [];
	public var cataMove:MouseMove;
	public var stringCount:Array<StringSelect> = []; //string开启的检测

	public var downBG:Rect;
	var tipButton:TipButton;
	var specButton:FuncButton;

	public var specBG:Rect;
	var searchButton:SearchButton;
	var resetButton:ResetButton;
	var backButton:GeneralBack;

	override function create()
	{
		if (stateType != 2) {
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
		}

		FlxG.mouse.visible = !ClientPrefs.data.needMobileControl;
		
		persistentUpdate = persistentDraw = true;
		instance = this;

		naviArray = [
			new NaviData('NovaFlare Engine', ['Language','General','User Interface','GamePlay','Game UI','Skin','Input','Audio','Graphics','Maintenance'])
		];
		
		var path = Paths.mods('stageScripts/options/');
		if (FileSystem.exists(path) && FileSystem.isDirectory(path)){
			var naviData = new NaviData('Global mod', []);
			
			var group:Array<String> = [];
			for (file in FileSystem.readDirectory(path))
			{
				if (file.toLowerCase().endsWith('.hx'))
					group.push(StringTools.replace(file, ".hx", ""));
			}
			naviData.group = group;
			naviData.extraPath = path;
			naviArray.push(naviData);
		}

		for (mod in Mods.parseList().enabled)
		{
			var path = Paths.mods(mod + '/stageScripts/options/');
			if (FileSystem.exists(path) && FileSystem.isDirectory(path)){
				var naviData = new NaviData(mod, []);
			
				var group:Array<String> = [];
				for (file in FileSystem.readDirectory(path))
				{
					if (file.toLowerCase().endsWith('.hx'))
						group.push(StringTools.replace(file, ".hx", ""));
				}
				naviData.group = group;
				naviData.extraPath = path;
				naviArray.push(naviData);
			}
		}

		mouseEvent = new MouseEvent();
		add(mouseEvent);

		var background = new ChangeSprite(0, 0).load(Paths.image('menuDesat'), 1.05);
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		naviBG = new Rect(0, 0, FlxG.width * 0.2, FlxG.height, 0, 0,  mainColor, 0.75);
		add(naviBG);

		for (i in 0...naviArray.length)
		{
			var naviSprite = new NaviGroup(FlxG.width * 0.005, FlxG.height * 0.005 + i * FlxG.height * 0.1, FlxG.width * 0.19, FlxG.height * 0.09, naviArray[i], i, false);
			naviSprite.antialiasing = ClientPrefs.data.antialiasing;
			add(naviSprite);
			naviGroup.push(naviSprite);
		}
		naviMoveEvent();

		naviMove = new MouseMove(OptionsState, 'naviPosiData', 
								[-1 * Math.max(0, (naviGroup.length - 9)) * FlxG.height * 0.1, FlxG.height * 0.005],
								[	
									[FlxG.width * 0.005, FlxG.width * 0.19], 
									[0, FlxG.height]
								],
								naviMoveEvent);
		add(naviMove);

		naviGroup[0].moveParent(0.01);

		/////////////////////////////////////////////////////////////////

		for (data in 0...naviArray.length) {
			var naviData:NaviData = naviArray[data];
			for (mem in 0...naviData.group.length) {
				if (naviData.extraPath != '') addCata(naviData.group[mem], naviGroup[data], naviGroup[data].parent[mem], naviData.extraPath);
				else addCata(naviData.group[mem], naviGroup[data], naviGroup[data].parent[mem]);
			}
		}

		var moveHeight:Float = 100;
		for (num in cataGroup) {
			if (num != cataGroup[cataGroup.length - 1]) {
				moveHeight -= num.bg.realHeight;
				moveHeight -= FlxG.width * (0.8 / 40);
			}
		}
		cataMove = new MouseMove(OptionsState, 'cataPosiData', 
								[moveHeight, 100],
								[ 
									[FlxG.width * 0.2, FlxG.width], 
									[0, FlxG.height - Std.int(FlxG.height * 0.1)]
								],
								cataMoveEvent);
		add(cataMove);
		cataMove.forceUpdateEvent = true;
		cataMove.useLerp = false;
		cataMove.tweenTime = 0.45;
		cataMove.tweenType = 'expoInOut';
		cataMoveEvent();
			
		/////////////////////////////////////////////////////////////

		downBG = new Rect(0, FlxG.height - Std.int(FlxG.height * 0.1), FlxG.width, Std.int(FlxG.height * 0.1), 0, 0, mainColor, 0.75);
		add(downBG);

		tipButton = new TipButton(
			FlxG.width * 0.2 + FlxG.height * 0.01, 
			downBG.y + Std.int(FlxG.height * 0.01),
			FlxG.width - FlxG.width * 0.2 - FlxG.height * 0.01 - Std.int(FlxG.width * 0.15) - Std.int(FlxG.height * 0.01 * 2), 
			Std.int(FlxG.height * 0.08)
		);
		add(tipButton);

		specButton = new FuncButton(
			FlxG.width - Std.int(FlxG.width * 0.15) - Std.int(FlxG.height * 0.01), 
			downBG.y + Std.int(FlxG.height * 0.01),
			Std.int(FlxG.width * 0.15), 
			Std.int(FlxG.height * 0.08),
			specChange
		);
		specButton.alpha = 0.5;
		add(specButton);

		//////////////////////////////////////////////////////////////////////

		specBG = new Rect(FlxG.width * 0.2, 0, FlxG.width - FlxG.width * 0.2, Std.int(FlxG.height * 0.1), 0, 0, mainColor, 0.75);
		add(specBG);

		searchButton = new SearchButton(specBG.x + specBG.height * 0.2, specBG.height * 0.2, specBG.width * 0.5, specBG.height * 0.6);
		add(searchButton);

		resetButton = new ResetButton(specBG.x + specBG.height * 0.2 * 2 + searchButton.width, specBG.height * 0.2, specBG.width - (specBG.height * 0.2 * 3 + searchButton.width), specBG.height * 0.6);
		add(resetButton);

		backButton = new GeneralBack(0, 720 - 72, FlxG.width * 0.2, FlxG.height * 0.1, Language.get('back', 'main'), EngineSet.mainColor, backMenu);
		add(backButton);

		super.create();
	}

	public var ignoreCheck:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		cataMove.inputAllow = true;
		for (cata in stringCount) {
			if (!cata.isOpend) continue;
			else {
				if (OptionsState.instance.mouseEvent.overlaps(cata.bg)){
					cataMove.inputAllow = false;
					break;
				}
			}
		}

		for (navi in naviGroup) navi.cataChoose = false;
		for (cata in cataGroup){
			if (cata.checkPoint()) {
				cata.follow.cataChoose = true;
				break;
			}
		}

		if (controls.BACK)
		{
			if (PsychUIInputText.focusOn != null)
			{
				PsychUIInputText.focusOn = null;
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else
				backMenu();
		}
	}

	private function updateCataVisibility():Void
	{
		var cam = FlxG.camera;
		var l = cam.scroll.x;
		var t = cam.scroll.y;
		var r = l + cam.width;
		var b = t + cam.height;
		for (cata in cataGroup)
		{
			var cl = cata.x;
			var ct = cata.y;
			var cr = cl + cata.bg.width;
			var cb = ct + cata.bg.realHeight;
			var inView = (cr > l && cl < r && cb > t && ct < b);
			cata.visible = inView;
			cata.active = inView;
		}
	}

	override function closeSubState()
	{
		super.closeSubState();
		persistentUpdate = true;
	}

	public function startSearch(text:String, time = 0.6) {
		for (cata in cataGroup) {
			cata.startSearch(text, time);
		}
	}

	public function changeCata(cataSort:Int, memSort:Int) {
		var outputData:Float = 100;

		var realSort:Int = memSort;
		for (navi in 0...naviGroup.length) {
			if (navi < cataSort) realSort += naviGroup[navi].parent.length;
			else break;
		}

		for (cata in 0...realSort) {
			outputData -= cataGroup[cata].bg.realHeight;
			outputData -= FlxG.width * (0.8 / 40);
		}
		outputData = Math.max(outputData, cataMove.moveLimit[0]);
		cataMove.tweenData = outputData;
	}

	public function changeTip(str:String) {
		tipButton.changeText(str);
	}

	public function addCata(type:String, follow:NaviGroup, mem:NaviMember, extraPath:String = '') {
		var obj:OptionCata = null;

		var outputX:Float = naviBG.width + FlxG.width * (0.8 / 40); //已被初始化
		var outputWidth:Float = FlxG.width * (0.8 - (0.8 / 40 * 2)); //已被初始化
		var outputY:Float = 100; //等待被初始化
		var outputHeight:Float = 200; //等待被初始化

		switch (type) 
		{
			case 'General':
				obj = new GeneralGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Language':
				obj = new LanguageGroup(outputX, outputY, outputWidth, outputHeight);
			case 'User Interface':
				obj = new InterfaceGroup(outputX, outputY, outputWidth, outputHeight);
			case 'GamePlay':
				obj = new GamePlayGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Game UI':
				obj = new UIGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Skin':
				obj = new SkinGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Input':
				obj = new InputGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Audio':
				obj = new AudioGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Graphics':
				obj = new GraphicsGroup(outputX, outputY, outputWidth, outputHeight);
			case 'Maintenance':
				obj = new MaintenanceGroup(outputX, outputY, outputWidth, outputHeight);
			default:
				obj = new HScriptGroup(outputX, outputY, outputWidth, outputHeight, type, extraPath, type);
		}
		cataGroup.push(obj);
		obj.follow = follow;
		obj.mem = mem;
		add(obj);
	}

	public function addMove(tar:MouseMove) {
		add(tar);
	}

	static public var cataPosiData:Float = 100;
	public function cataMoveEvent(){
		for (i in 0...cataGroup.length) {
			if (i == 0) cataGroup[i].y = cataPosiData;
			else cataGroup[i].y = cataGroup[i - 1].y + cataGroup[i - 1].bg.realHeight + FlxG.width * (0.8 / 40);
		}
		updateCataVisibility();
	}

	public function cataMoveChange()
	{
		var moveHeight:Float = 100;
		for (num in cataGroup) {
			if (num != cataGroup[cataGroup.length - 1]) {
				moveHeight -= num.bg.waitHeight;
				moveHeight -= FlxG.width * (0.8 / 40);
			}
		}
		cataMove.moveLimit[0] = moveHeight;
	}

	static public var naviPosiData:Float = 0;
	public function naviMoveEvent(){
		for (i in 0...naviGroup.length) {
			naviGroup[i].y = naviPosiData + i * FlxG.height * 0.1 + naviGroup[i].offsetY;
		}
	}

	var naviTween:Array<FlxTween> = [];
	var alreadyDetele:Bool = false;
	public function changeNavi(navi:NaviGroup, isOpened:Bool, naviTime:Float = 0.45) {
		for (tween in naviTween) {
			if (tween != null) tween.cancel();
		}

		for (i in 0...naviGroup.length) {
			if (i <= navi.optionSort) continue;
			else {
				naviGroup[i].offsetWaitY += (navi.parent.length * 50 + 15) * (isOpened? -1 : 1);
				var tween = FlxTween.num(naviGroup[i].offsetY, naviGroup[i].offsetWaitY, naviTime, {ease: FlxEase.expoInOut}, function(v){naviGroup[i].offsetY = v;});
				naviTween.push(tween);
			}
		}
		
		var moveHeight:Float = 0;
		for (i in 0...naviGroup.length) {
			if (naviGroup[i] == navi) continue;
			else {
				if (naviGroup[i].isOpened) moveHeight += naviGroup[i].parent.length * 50 + 15;
			}
		}
		if (!isOpened) moveHeight += (navi.parent.length * 50 + 15);
		naviMove.moveLimit[0] = -1 * Math.max(0, ((naviGroup.length - 9)) * FlxG.height * 0.1 + moveHeight);
	}

	var specOpen:Bool = false;
	var specTween:Array<FlxTween> = [];
	var specTime = 0.6;
	public function specChange() {
		for (tween in specTween) {
			if (tween != null) tween.cancel();
		}

		var newPoint:Float = 0;
		if (!specOpen) {
			newPoint = FlxG.width;
			cataMove.moveLimit[1] = 30;
		} else {
			newPoint = FlxG.width * 0.2;
			cataMove.moveLimit[1] = 100;
		}

		var tween = FlxTween.tween(specBG, {x: newPoint}, specTime, {ease: FlxEase.expoInOut});
		specTween.push(tween);
		var tween = FlxTween.tween(searchButton, {x: newPoint + specBG.height * 0.2}, specTime, {ease: FlxEase.expoInOut});
		specTween.push(tween);
		var tween = FlxTween.tween(resetButton, {x: newPoint + specBG.height * 0.2 + searchButton.width + specBG.height * 0.2}, specTime, {ease: FlxEase.expoInOut});
		specTween.push(tween);
		
	
		specOpen = !specOpen;
	}

	public function moveState(type:Int)
	{
		switch (type)
		{
			case 1: // NoteOffsetState
				MusicBeatState.switchState(new NoteOffsetState());
			case 2: // NotesSubState
				persistentUpdate = false;
				openSubState(new NotesSubState());
			case 3: // ControlsSubState
				persistentUpdate = false;
				openSubState(new ControlsSubState()); // 我会想你的，NewControlsSubState -- chh
			case 4: // MobileControlSelectSubState
				persistentUpdate = false;
				openSubState(new MobileControlSelectSubState());
			case 5: // MobileExtraControl
				persistentUpdate = false;
				openSubState(new MobileExtraControl());
			case 6: // CopyStates
				MusicBeatState.switchState(new CopyState(true));
			case 7: // NotesSubStateLegacy
				persistentUpdate = false;
				openSubState(new NotesSubStateLegacy());
		}
	}

	public function resetData()
	{
		for (cata in cataGroup) {
			if (cata.checkPoint()) {
				cata.resetData();
				break;
			}
		}
	}

	public function changeLanguage() {
		for (spr in 0...naviGroup.length) {
			naviGroup[spr].changeLanguage();

			for (mem in naviGroup[spr].parent) mem.changeLanguage();
		}

		for (cata in cataGroup) cata.changeLanguage();

		tipButton.changeLanguage();
		resetButton.changeLanguage();
		searchButton.changeLanguage();
		backButton.changeLanguage();

	}

	public static var stateType:Int = 0; //检测到底退回到哪个界面
	var backCheck:Bool = false;
	function backMenu()
	{
		if (!backCheck)
		{
			backCheck = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			ClientPrefs.saveSettings();
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
			Main.fpsVar.scaleX = Main.fpsVar.scaleY = ClientPrefs.data.fpsScale;
			//Main.fpsVar.change();
			if (Main.watermark != null)
			{
				Main.watermark.scaleX = Main.watermark.scaleY = ClientPrefs.data.watermarkScale;
				Main.watermark.y += (1 - ClientPrefs.data.watermarkScale) * Main.watermark.bitmapData.height;
				Main.watermark.visible = ClientPrefs.data.showWatermark;
			}
			switch (stateType)
			{
				case 0:
					MusicBeatState.switchState(new MainMenuState());
				case 1:
						MusicBeatState.switchState(new FreeplayState());
				case 2:
					MusicBeatState.switchState(new PlayState());
					FlxG.mouse.visible = false;
			}
			stateType = 0;
		}
	}
}

