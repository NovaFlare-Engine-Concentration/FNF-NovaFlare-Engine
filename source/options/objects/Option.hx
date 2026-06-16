package options.objects;

import openfl.filters.GlowFilter;

import flixel.graphics.frames.FlxFilterFrames;

enum OptionType
{
	BOOL;

	INT;
	FLOAT;
	PERCENT;

	STRING;

	STATE;

	TITLE;
	TEXT;
	
	COLOR;

	NONE;
}

class Option extends FlxSpriteGroup
{
	public var onChange:Void->Void = null;
	public var experMode(default, set):Bool; //实验性设置

	//STRING
	public var strGroup:Array<String> = null;
	public var strDisplayGroup:Array<String> = null;

	public var nationalFlag:FlxSprite;

	//INT FLOAT PERCENT;
	public var minValue:Float = 0;
	public var maxValue:Float = 0;
	public var decimals:Int = 0; //数据需要精确到小数点几位
	public var extraDisplay:String = '';

	public var variable:String = null; // Variable from ClientPrefs.hx
	public var defaultValue:Dynamic = null; //获取出来的数值
	public var resetValue:Dynamic = null; //重置时候赋予的数值（脚本专用）
	public var description:String = ''; //简短的描述
	public var tips:String; //真正的解释

	public var saveHeight:Float = 0; //仅仅用作最开始设置的时候使用
	public var inter:Float = 10; //设置与设置间的y轴间隔

	public var follow:OptionCata;
	public var modsData:Map<String, Dynamic> = []; //mod数据
	public var modAdd:Bool;

	/////////////////////////////////////////////

	public var type:OptionType = BOOL;

	/////////////////////////////////////////////

	public function new(follow:OptionCata, variable:String = '', type:OptionType = BOOL, ?data:Dynamic)
	{
		super();

		this.follow = follow;
		this.modAdd = follow.modAdd;
		if (modAdd){
			if (ClientPrefs.modsData.get(follow.modsName) == null) {
				ClientPrefs.modsData.set(follow.modsName, []);
			}
			modsData = ClientPrefs.modsData.get(follow.modsName);
		}

		this.variable = variable;
		this.type = type;
		this.description = Language.get(variable, 'options');
		this.tips = Language.get(variable, 'optionTips');

		///////////////////////////////////////////////////////////////////////////////////////////////////

		if (this.type != STATE && variable != '')
			if (!modAdd)
				this.defaultValue = Reflect.getProperty(ClientPrefs.data, variable);
			else
				this.defaultValue = modsData.get(variable);

		///////////////////////////////////////////////////////////////////////////////////////////////////

		switch (type)
		{
			case BOOL:
				//bool没有特殊需要加的

			case INT:
				this.minValue = data[0];
				this.maxValue = data[1];
				if (data[2] != null) this.extraDisplay = data[2];

			case FLOAT:
				this.minValue = data[0];
				this.maxValue = data[1];
				this.decimals = data[2];
				if (data[3] != null) this.extraDisplay = data[3];

			case PERCENT:
				this.minValue = data[0];
				this.maxValue = data[1];
				this.decimals = data[2];
				this.extraDisplay = '%';
				
			case STRING:
				if (Std.isOfType(data, Array) && data.length == 2 && Std.isOfType(data[0], Array)) {
					this.strGroup = data[0];
					this.strDisplayGroup = data[1];
				} else {
					this.strGroup = data;
				}
			default:
		}

		defaultDataCheck();

		switch (type)
		{
			case BOOL:
				addBool();
			case INT, FLOAT, PERCENT:
				addNum();
			case STRING:
				addString();
			case TEXT:
				addTip();
			case TITLE:
				addTitle();
			case STATE:
				addState();
			default:
		}
	}

	///////////////////////////////////////////////

	public function change()
	{
		if (onChange != null)
			onChange();
	}

	dynamic public function getValue():Dynamic
	{
		var value;
		if (!modAdd) {
			value = Reflect.getProperty(ClientPrefs.data, variable);
		} else {
			value = modsData.get(variable);
		}
		return value;
	}

	dynamic public function setValue(value:Dynamic)
	{
		defaultValue = value;
		if (!modAdd) {
			return Reflect.setProperty(ClientPrefs.data, variable, value);
		} else {
			return modsData.set(variable, defaultValue);
		}
		return Reflect.setProperty(ClientPrefs.data, variable, value);
	}

	public function resetData()
	{
		if (variable == '' || type == STATE ||  type == TEXT || type == TITLE)
			return;
		try {
			if (!modAdd) {
				Reflect.setProperty(ClientPrefs.data, variable, Reflect.getProperty(ClientPrefs.defaultData, variable));
				defaultValue = Reflect.getProperty(ClientPrefs.defaultData, variable);
			} else {
				this.defaultValue = resetValue; 
				defaultDataCheck();
				modsData.set(variable, defaultValue);
			}
		}

		switch (type)
		{
			case BOOL:
				boolButton.updateDisplay();
			case INT, FLOAT, PERCENT:
				numButton.initData();
				updateDisText();
			case STRING:
				updateDisText();
			default:
		}
		change();
	}

	function defaultDataCheck() {
		switch (type)
		{
			case BOOL:
				if (defaultValue == null)
					defaultValue = false;
			case INT, FLOAT, PERCENT:
				if (defaultValue == null)
					defaultValue = minValue;
			case STRING:
				if (strGroup.indexOf(defaultValue) == -1) {
					if (strGroup.length > 0)
						defaultValue = strGroup[0];
					if (defaultValue == null)
						defaultValue = '';
				}
			default:
		}
	}

	var overlopCheck:Float;
	var alreadyShowTip:Bool = false;
	public var allowUpdate:Bool = true; //仅仅用于搜索全局禁止更新(代码作用于option的其他子类)
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		followX = follow.mainX;
		followY = follow.mainY;

		if (!allowUpdate) return;

		var mouse = FlxG.mouse;
       
        if (mouse.overlaps(this)) {
			overlopCheck += elapsed;
		} else {
			overlopCheck = 0;
			alreadyShowTip = false;
		}

		if (overlopCheck >= 0.2 && !alreadyShowTip) {
			OptionsState.instance.changeTip(tips);
			alreadyShowTip = true;
		}

		if (this.variable == 'language')
		{
			var hue = (Date.now().getTime() / 10) % 360;
			baseBG.color = FlxColor.fromHSB(hue, 1, 1);
		}
	}

	private function set_experMode(value:Bool):Bool {
		experMode = value;
		if (value) {
			if (baseTar != null)
				baseTar.text += '  (experimentMode)';
		}
		return value;
	}

	////////////////////////////////////////////////////////

	var boolButton:BoolButton;
	function addBool()
	{
		baseBGAdd();

		var clacHeight = baseBG.height - (baseTar.height + baseLine.height) - baseBG.mainRound * 2;
		var clacWidth = baseBG.width * 0.4 - baseBG.mainRound;
		boolButton = new BoolButton(baseBG.width * 0.6, baseTar.height + baseLine.height + baseBG.mainRound, clacWidth, clacHeight, this);
		add(boolButton);
	}

	public var valueText:FlxText;
	var numButton:NumButton;
	function addNum()
	{
		baseBGAdd(true);

		valueText = new FlxText(0, 0, 0, defaultValue + ' ' + extraDisplay, Std.int(baseBG.width / 20 / 2));
		valueText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(baseBG.width / 30 / 2), 0xffffff, RIGHT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        valueText.antialiasing = ClientPrefs.data.antialiasing;
		valueText.borderStyle = NONE;
		valueText.x += baseBG.width - valueText.textField.textWidth - baseBG.mainRound;
		valueText.alpha = 0.3;
		//valueText.blend = ADD;
		add(valueText);
		

		var clacHeight = baseBG.height - (baseTar.height + baseLine.height) - baseBG.mainRound * 2;
		var clacWidth = baseBG.width * 0.5 - baseBG.mainRound * 2;
		numButton = new NumButton(baseBG.width * 0.5 + baseBG.mainRound, baseTar.height + baseLine.height + baseBG.mainRound, clacWidth, clacHeight, this);
		add(numButton);
	}

	public function updateDisText() {
		var text:String = Std.string(defaultValue) + ' ' + extraDisplay;
		if (type == STRING && strDisplayGroup != null) {
			var index:Int = strGroup.indexOf(defaultValue);
			if (index != -1 && index < strDisplayGroup.length)
				text = strDisplayGroup[index] + ' ' + extraDisplay;
		}
		valueText.text = text;
		valueText.x = followX + innerX + baseBG.width - valueText.textField.textWidth - baseBG.mainRound;
	}

	public var stringRect:StringRect;
	public var select:StringSelect;
	function addString()
	{
		baseBGAdd();

		valueText = new FlxText(0, 0, 0, defaultValue + ' ' + extraDisplay, Std.int(baseBG.width / 20 / 2));
		valueText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(baseBG.width / 30), 0xffffff, RIGHT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        valueText.antialiasing = ClientPrefs.data.antialiasing;
		valueText.borderStyle = NONE;
		valueText.x += baseBG.width - valueText.textField.textWidth - baseBG.mainRound;
		valueText.alpha = 0.3;
		//valueText.blend = ADD;
		add(valueText);

		var clacHeight = baseBG.height - (baseTar.height + baseLine.height) - baseBG.mainRound * 2;
		var clacWidth = baseBG.width * 0.4 - baseBG.mainRound;
		stringRect = new StringRect(baseBG.width * 0.6, baseTar.height + baseLine.height + baseBG.mainRound, clacWidth, clacHeight, this);
		add(stringRect);

		select = new StringSelect(0, baseBG.height + inter, follow.bg.realWidth * (1 - (1 / 2 / 50 * 2)), follow.bg.width * 0.2, this);
		select.visible = false;
		add(select);

		if (this.variable == 'language' && this.type == STRING) {
			nationalFlag = new FlxSprite().loadGraphic(Paths.image("menuExtendHide/option/nation/" + defaultValue));
			nationalFlag.origin.set(0, 0);
			var scaleX = baseBG.width / nationalFlag.width;
			var scaleY = baseBG.height / nationalFlag.height;
			var scale = Math.min(scaleX, scaleY);
			nationalFlag.scale.set(scale, scale);
			nationalFlag.setPosition(
				baseBG.x + baseBG.width + 20,
				baseBG.y + baseBG.height - (nationalFlag.height * scale)
			);
			add(nationalFlag);

			if (Paths.image("menuExtendHide/option/nation/" + defaultValue) == null)
			{
				nationalFlag.visible = false;
			} else {
				nationalFlag.visible = true;
			}
		}
	}

	public function changeLangNation()
	{
		if (nationalFlag != null)
		{ 
			if (Paths.image("menuExtendHide/option/nation/" + defaultValue) == null)
			{
				nationalFlag.visible = false;
				return;
			}

			nationalFlag.loadGraphic(Paths.image("menuExtendHide/option/nation/" + defaultValue));
			nationalFlag.origin.set(0, 0);
			var scaleX = baseBG.width / nationalFlag.width;
			var scaleY = baseBG.height / nationalFlag.height;
			var scale = Math.min(scaleX, scaleY);
			nationalFlag.scale.set(scale, scale);
			nationalFlag.setPosition(
				baseBG.x + baseBG.width + 20,
				baseBG.y + baseBG.height - (nationalFlag.height * scale)
			);
			nationalFlag.visible = true;
		}
	}

	var tipsLight:Rect;
	var tipsText:FlxText;
	function addTip()
	{
		tipsText = new FlxText(0, 0, 0, description, Std.int(follow.width / 10));
		tipsText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(follow.bg.realWidth / 45), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        tipsText.antialiasing = ClientPrefs.data.antialiasing;
		tipsText.borderStyle = NONE;
		tipsText.color = EngineSet.minorColor;
		tipsText.active = false;
		add(tipsText);

		var data = tipsText.height * 0.5;
		tipsLight = new Rect(0, 0,  data / 6, data, data / 4, data / 4, EngineSet.mainColor);
		add(tipsLight);

		tipsLight.y += (tipsText.height - tipsLight.height) / 2;

		tipsText.x += tipsLight.width * 2;

		var glowFilter:GlowFilter = new GlowFilter(EngineSet.mainColor, 0.75, tipsLight.width * 2, tipsLight.width * 2);
		var filterFrames = FlxFilterFrames.fromFrames(tipsLight.frames, Std.int(tipsLight.width * 10), Std.int(tipsLight.height), [glowFilter]);
		filterFrames.applyToSprite(tipsLight, false, true);

		saveHeight = tipsText.height + inter;
	}

	var titleLight:Rect;
	var title:FlxText;
	var titLine:Rect;
	function addTitle()
	{
		title = new FlxText(0, 0, 0, description, Std.int(follow.width / 10));
		title.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(follow.bg.realWidth / 30), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        title.antialiasing = ClientPrefs.data.antialiasing;
		title.borderStyle = NONE;
		title.x += follow.bg.mainRound;
		title.color = EngineSet.minorColor;
		title.active = false;
		add(title);

		var data = title.height * 0.5;
		titleLight = new Rect(follow.bg.mainRound, 0,  data / 6, data, data / 4, data / 4, EngineSet.mainColor);
		add(titleLight);

		titleLight.x -= titleLight.width / 2;
		titleLight.y += (title.height - titleLight.height) / 2;

		title.x += titleLight.width * 2;

		var glowFilter:GlowFilter = new GlowFilter(EngineSet.mainColor, 0.75, titleLight.width * 2, titleLight.width * 2);
		var filterFrames = FlxFilterFrames.fromFrames(titleLight.frames, Std.int(titleLight.width * 10), Std.int(titleLight.height), [glowFilter]);
		filterFrames.applyToSprite(titleLight, false, true);

		titLine = new Rect(0, title.height, follow.bg.mainWidth, follow.width / 400, 0, 0, 0xFFFFFF, 0.3);
		titLine.active = false;
		add(titLine);

		saveHeight = title.height + titLine.height + inter;
	}

	var stateButton:StateButton;
	function addState()
	{
		var double = false; //还是小的比较好看

		var calcWidth:Float = 0;
		var calcHeight:Float = 0;

		if (!double) calcWidth = follow.bg.realWidth * ((1 - (1 / 2 / 50 * 3)) / 2);
		else calcWidth = follow.bg.realWidth * (1 - (1 / 2 / 50 * 2));

		var calcHeight:Float = 0;
		if (!double) calcHeight = calcWidth * 0.16;
		else calcHeight = calcWidth * 0.1;

		stateButton = new StateButton(calcWidth, calcHeight, this);
		add(stateButton);

		saveHeight = stateButton.bg.height + inter;
	}

	public var baseBG:Rect;
	var baseTar:FlxText;
	var baseLine:Rect;
	var baseDesc:FlxText;
	var mult:Float = 1; //一些数据需要保持一致
	function baseBGAdd(double:Bool = false)
	{
		if (double) mult = 2;
		else mult = 1;

		var calcWidth:Float = 0;
		if (!double) calcWidth = follow.bg.realWidth * ((1 - (1 / 2 / 50 * 3)) / 2);
		else calcWidth = follow.bg.realWidth * (1 - (1 / 2 / 50 * 2));

		var calcHeight:Float = 0;
		if (!double) calcHeight = calcWidth * 0.16;
		else calcHeight = calcWidth * 0.1;

		baseBG = new Rect(0, 0, calcWidth, calcHeight, calcWidth / 75 / mult, calcWidth / 75 / mult, 0x000000, 0.3);
		add(baseBG);

		baseTar = new FlxText(0, 0, 0, Language.get('Target', 'options') + ': ' + variable, Std.int(baseBG.width / 20 / mult));
		baseTar.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(baseBG.width / 30 / mult), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        baseTar.antialiasing = ClientPrefs.data.antialiasing;
		baseTar.borderStyle = NONE;
		baseTar.x += baseBG.mainRound;
		baseTar.alpha = 0.3;
		//baseTar.blend = ADD;
		baseTar.active = false;
		add(baseTar);

		baseLine = new Rect(0, baseTar.height, baseBG.width, baseBG.width / 400 / mult, 0, 0, 0xFFFFFF, 0.3);
		baseLine.active = false;
		add(baseLine);

		var calcWidth = baseBG.width * 0.58;
		if (double) calcWidth = baseBG.width * 0.5;
		baseDesc = new FlxText(0, baseTar.height + baseLine.height, calcWidth, description, Std.int(follow.width / 10));
		baseDesc.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(baseBG.width / 25 / mult), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        baseDesc.antialiasing = ClientPrefs.data.antialiasing;
		baseDesc.borderStyle = NONE;
		baseDesc.active = false;
		
		baseDesc.y -= (baseDesc.height - baseDesc.textField.textHeight) / 2;

		var clacHeight = baseDesc.textField.textHeight / (baseBG.height - baseTar.height + baseLine.height);
		if (clacHeight > 1) baseDesc.size = Std.int(baseDesc.size / clacHeight / 1.05); //原理来讲不应该超过这个高度的，这个玩意纯粹的防止蠢人

		baseDesc.x += baseBG.mainRound;
		baseDesc.y += (baseBG.height - baseTar.height + baseLine.height - baseDesc.textField.textHeight) / 2;
		add(baseDesc);

		saveHeight = baseBG.height + inter;
	}

	////////////////////////////////////////////////////////////////////////////

	public function changeLanguage() {
		this.description = Language.get(variable, 'options');
		this.tips = Language.get(variable, 'optionTips');
		alreadyShowTip = false;
		switch (type)
		{
			case BOOL:
				baseChangeLanguage();
			case INT, FLOAT, PERCENT:
				baseChangeLanguage();
			case STRING:
				baseChangeLanguage();
			case TITLE:
				title.text = description;
				title.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(follow.bg.realWidth / 30), EngineSet.minorColor, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
				title.borderStyle = NONE;
			case TEXT:
				tipsText.text = description;
				tipsText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(follow.bg.realWidth / 45), EngineSet.minorColor, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
				tipsText.borderStyle = NONE;
				
			case STATE:
				stateButton.stateName.text = description;
				stateButton.stateName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(stateButton.bg.width / 20), 0xffffff, CENTER, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
				stateButton.stateName.borderStyle = NONE;
			default:
		}
	}

	function baseChangeLanguage() {
		baseTar.text = Language.get('Target', 'options') + ': ' + variable;
		baseTar.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(baseBG.width / 30 / mult), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
		baseTar.borderStyle = NONE;

		baseDesc.text = description;
		baseDesc.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(baseBG.width / 25 / mult), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
		baseDesc.borderStyle = NONE;
	}

	public function startSearch(text:String):Bool {
		if (variable.indexOf(text) != -1) return true;
		if (description.indexOf(text) != -1) return true;
		if (tips.indexOf(text) != -1) return true;
		return false;
	}



	/////////////////////////////////////////////////////////////////////////////////////////////

	public var followX:Float = 0;  //optioncata位置
	public var innerX:Float = 0; //这个option在optioncata内部位置
	public var xOff:Float = 0; //用于图形在cata内部位移
	var xTween:FlxTween = null;
	public function changeX(data:Float, isMain:Bool = true, time:Float = 0.6) {
		var output = isMain ? followX : xOff;
		output += data;

		if (xTween != null) xTween.cancel();
		xTween = FlxTween.tween(this, {x: followX + innerX + xOff}, time, {ease: FlxEase.expoInOut});
	}

	public function initX(data:Float, innerData:Float, ?specData:Float = 0) {
		followX = data;
		innerX = innerData;
		if (type == TITLE) return;
		this.x = followX + innerX;
		if (specData != 0) { 
			this.select.x -= specData;
			this.select.specX = specData;
		}
	}

	public var followY:Float = 0;  //optioncata在主体的位置
	public var innerY:Float = 0; //optioncata内部位置
	public var yOff:Float = 0; //用于图形在cata内部位移
	public var waitYOff:Float = 0; //用于图形在cata内部位移
	public var sameY:Bool = false; //用于string展开兼容
	public var yTween:FlxTween = null;
	public function changeOffY(data:Float, time:Float) {
		waitYOff += data;

		if (yTween != null) yTween.cancel();
		yTween = FlxTween.num(yOff, waitYOff, time, {ease: FlxEase.expoInOut}, function(v){this.y = followY + innerY + yOff; yOff = v;});
	}

	public function initY(data:Float, innerData:Float) {
		followY = data;
		innerY = innerData;
		this.y = followY + innerY;
	}

	////////////////////////////////////////////////////////////////////

	public var alphaTween:Array<FlxTween> = [];
	public function changeAlpha(isAdd:Bool, time:Float = 0.6) { //无敌了haxeflixel，flxspritegroup你妈炸了
		if (alphaTween.length > 0) {
			for (tween in alphaTween) {
				if (tween != null) tween.cancel();
			}
		}

		if (isAdd) {
			switch (type)
			{
				case BOOL:
					baseChangeAlpha(isAdd, time);
					var tween = FlxTween.tween(boolButton, {alpha: 1}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
				case INT, FLOAT, PERCENT:
					baseChangeAlpha(isAdd, time);
					var tween = FlxTween.tween(valueText, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.addButton, {alpha: 1}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.deleteButton, {alpha: 1}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.moveBG, {alpha: 0.4}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.moveDis, {alpha: 1}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.rod, {alpha: 1}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
				case STRING:
					baseChangeAlpha(isAdd, time);
					var tween = FlxTween.tween(valueText, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stringRect.bg, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stringRect.dis, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stringRect.disText, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
				case STATE:
					var tween = FlxTween.tween(stateButton.bg, {alpha: 0.5}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stateButton.stateName, {alpha: 0.8}, time, {ease: FlxEase.expoIn});
					alphaTween.push(tween);
				default:
			}
		} else {
			switch (type)
			{
				case BOOL:
					baseChangeAlpha(isAdd, time);
					var tween = FlxTween.tween(boolButton, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
				case INT, FLOAT, PERCENT:
					baseChangeAlpha(isAdd, time);
					var tween = FlxTween.tween(valueText, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.addButton, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.deleteButton, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.moveBG, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.moveDis, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(numButton.rod, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
				case STRING:
					baseChangeAlpha(isAdd, time);
					var tween = FlxTween.tween(valueText, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stringRect.bg, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stringRect.dis, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stringRect.disText, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
				case STATE:
					var tween = FlxTween.tween(stateButton.bg, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
					var tween = FlxTween.tween(stateButton.stateName, {alpha: 0}, time, {ease: FlxEase.expoOut});
					alphaTween.push(tween);
				default:
			}
		}
	}

	public function baseChangeAlpha(isAdd:Bool, time) {
		if (isAdd) {
			var tween = FlxTween.tween(baseBG, {alpha: 0.1}, time, {ease: FlxEase.expoIn});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseTar, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseLine, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseDesc, {alpha: 1}, time, {ease: FlxEase.expoIn});
			alphaTween.push(tween);
			
		} else {
			var tween = FlxTween.tween(baseBG, {alpha: 0}, time, {ease: FlxEase.expoOut});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseTar, {alpha: 0}, time, {ease: FlxEase.expoOut});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseLine, {alpha: 0}, time, {ease: FlxEase.expoOut});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseDesc, {alpha: 0}, time, {ease: FlxEase.expoOut});
			alphaTween.push(tween);
		}
	}
}
