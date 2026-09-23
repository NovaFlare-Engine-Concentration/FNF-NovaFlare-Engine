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
	var languageDescriptionOverride:Null<String>;
	var languageTipsOverride:Null<String>;

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

		// 描述的"两行窗口"是**懒量**的：文本画过几帧、textHeight 有效之后再收窄。
		// （为什么不能在创建时量：见 fitDescWindow 的注释 —— 会把描述永久裁没）
		if (descNeedFit && baseDesc != null)
		{
			if (descFitDelay > 0) descFitDelay--;
			else fitDescWindow();
		}

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

		// ★ 描述超过两行时，滚轮落在描述上就滚描述。
		//   同时 OptionsState.descUnderMouse() 会把内容区的滚动让开，
		//   否则一滚就变成"整页翻走 + 描述自己也动"，两件事一起发生。
		if (descMaxScroll > 0 && baseDesc != null && mouse.wheel != 0 && mouse.overlaps(baseDesc))
			scrollDesc(descScrollV - Std.int(mouse.wheel));
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
		if (valueText == null)
			return;
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

	/**
	 * 设置项的「卡片底」（web 原型 `.opt`：background:rgba(255,255,255,.035) +
	 * border:1px solid rgba(255,255,255,.05)）。
	 * ★ 原来是 0x000000 / alpha 0.3 —— 纯黑卡片压在深色面板上就是一块块黑砖，
	 *   用户报的「二级菜单里面的选项卡变黑色」除了组 alpha 会把 alpha 放大到 1
	 *   之外，这个底色的起点本身也是黑的。这里改成极淡的白（0.05），和原型一致。
	 */
	inline static var CARD_ALPHA:Float = 0.05;
	/** 卡片里「变量名」下面那条 1px 分隔线（原型是 border，这里用线代替） */
	inline static var CARD_LINE_ALPHA:Float = 0.10;

	public var baseBG:Rect;
	var baseTar:FlxText;
	var baseLine:Rect;
	/** 描述文本（public：OptionsState 要在它上面做滚轮命中判定，见 descUnderMouse） */
	public var baseDesc:FlxText;
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

		baseBG = new Rect(0, 0, calcWidth, calcHeight, calcWidth / 75 / mult, calcWidth / 75 / mult, 0xFFFFFF, CARD_ALPHA);
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

		baseLine = new Rect(0, baseTar.height, baseBG.width, baseBG.width / 400 / mult, 0, 0, 0xFFFFFF, CARD_LINE_ALPHA);
		baseLine.active = false;
		add(baseLine);

		var calcWidth = baseBG.width * 0.58;
		if (double) calcWidth = baseBG.width * 0.5;
		baseDesc = new FlxText(0, baseTar.height + baseLine.height, calcWidth, description, Std.int(follow.width / 10));
		baseDesc.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(baseBG.width / 25 / mult), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        baseDesc.antialiasing = ClientPrefs.data.antialiasing;
		baseDesc.borderStyle = NONE;
		baseDesc.active = false;
		add(baseDesc);
		baseDesc.x += baseBG.mainRound;
		// ★ 这里**不能**立刻去量文本、更不能写 fieldHeight —— 文本此时还没排版，
		//   `textField.textHeight` 还是 0，一写就会把文本永久裁没（见 fitDescWindow）。
		//   改成交给 update() 里的"懒量一次"。
		descZoneTop = baseTar.height + baseLine.height;

		saveHeight = baseBG.height + inter;
	}

	////////////////////////////////////////////////////////////////////////////
	// 描述文本：最多两行，放不下就在描述上用滚轮滑动
	////////////////////////////////////////////////////////////////////////////

	/** 描述最多显示几行 */
	public static inline var DESC_LINES:Int = 2;

	/** 描述区在卡片内的起点（变量名 + 分隔线之下） */
	var descZoneTop:Float = 0;

	/** 还差几帧才够条件量描述（见 fitDescWindow 的注释），以及"还没量过"的标记 */
	var descFitDelay:Int = 2;
	var descNeedFit:Bool = true;

	/** 还藏着几行没显示（0 = 全部看得见，不需要滑） */
	public var descMaxScroll:Int = 0;

	/** 描述区当前滚到第几行（0 = 最上面） */
	public var descScrollV:Int = 0;

	/**
	 * 给描述开一个「两行高的窗口」——**只做收窄，绝不当成"默认设置"**。
	 *
	 * ── 目标 ────────────────────────────────────────────────────────────
	 *   原来是让描述自由换行、再用 `baseDesc.size /= clacHeight` 把字号硬缩进卡片，
	 *   长描述会**一路溢出卡片**（用户报的"信息直接超出窗口"）。现在：
	 *   超过两行 → 把窗口收成两行高，剩下的用 `textField.scrollV` 滚（滚轮，见 update）；
	 *   不超过两行 → **什么都不动**，保持 FlxText 的自动高度。
	 *
	 * ── ★★ 本轮最惨的一个坑：千万别在"文本还没排版"时写 fieldHeight ★★ ──
	 *   `FlxText.regenGraphic()` 里高度是这么算的：
	 *       newHeight = _autoHeight ? textField.textHeight + GUTTER : textField.height
	 *   而 `set_fieldHeight(0)` 只把 `_autoHeight` 置回 true、**不写** textField.height。
	 *   所以如果在「文本刚 set、textHeight 还是 0」的时刻触发了重绘，
	 *   高度就会被算成 `0 + GUTTER`（几像素），并且 regenGraphic 紧接着
	 *   `textField.height = newHeight` —— 文本框真的被压成几像素高，
	 *   之后再怎么排版都只剩一条缝：**整屏所有描述一起消失**（本轮实测）。
	 *   修法：① 创建/换语言时只挂一个"待量"标记，不碰 fieldHeight；
	 *        ② 等文本画过几帧、`textHeight > 1` 了再量；
	 *        ③ 量出来不超过两行就连 fieldHeight 都不写。
	 */
	public function fitDescWindow():Void
	{
		if (baseDesc == null || baseDesc.textField == null) return;

		var tf = baseDesc.textField;
		var fullH:Float = tf.textHeight;
		if (fullH <= 1) return;                 // 还没排版好，保持"待量"，下一帧再试
		descNeedFit = false;

		var lineH:Float = measureLineHeight(fullH);
		// 行数 = 总高 / 单行高，四舍五入（这里只用来判断"要不要收窄"，容错很宽）
		var est:Float = fullH / lineH;
		var lines:Int = (est > 1) ? Std.int(est + 0.5) : 1;

		// ★★ 组内子元素的 y 是「绝对屏幕坐标」，不是相对卡片的偏移 ★★
		//   FlxSpriteGroup.preAdd 里做了 `sprite.y += y`，所以 baseDesc 一旦被 add，
		//   `baseDesc.y` 就等于 `本组 y（= 卡片顶）+ descZoneTop`（实测 81.36 + 25 = 106.36）。
		//   之前这里直接把 `descZoneTop`（相对值 25）写回去，等于把描述瞬移到屏幕
		//   y=25 —— 正好在内容裁剪区**上方**，于是整屏描述全部看不见，
		//   卡片里只剩「变量名称: xxx」一行（本轮实测）。
		//   统一用 `this.y + 相对偏移` 换算：this.y 会随滚动实时变化，天然跟着走。
		var cardTop:Float = this.y;

		if (lines > DESC_LINES)
		{
			var zoneH:Float = baseBG.height - descZoneTop;
			var winH:Float = Math.min(lineH * DESC_LINES, zoneH);
			baseDesc.fieldHeight = winH + 2;
			descMaxScroll = lines - DESC_LINES;
			if (descScrollV > descMaxScroll) descScrollV = descMaxScroll;
			baseDesc.textField.scrollV = descScrollV + 1;
			baseDesc.y = cardTop + descZoneTop;
		}
		else
		{
			baseDesc.fieldHeight = 0;           // 回到自动高度（此刻 textHeight 有效，安全）
			descMaxScroll = 0;
			descScrollV = 0;
			// 垂直居中在「变量名分隔线以下」的区域里
			baseDesc.y = cardTop + descZoneTop + Math.max(0, (baseBG.height - descZoneTop - fullH) / 2);
		}
	}

	/**
	 * 单行高。
	 *
	 * 优先问 OpenFL 的 `getLineMetrics(0)`（拿到的是字体真实的 ascent/descent/行距）；
	 * 拿不到就用「字号 × 1.2」兜底 —— 只是用来把总高换算成行数，容错很宽。
	 */
	function measureLineHeight(fullH:Float):Float
	{
		try
		{
			var m = baseDesc.textField.getLineMetrics(0);
			if (m != null && m.height > 0) return m.height;
		}
		catch (e:Dynamic) {}
		return Math.max(1, baseDesc.size * 1.2);
	}

	/** 把描述滚到第 v 行（0 起） */
	public function scrollDesc(v:Int):Bool
	{
		if (descMaxScroll <= 0 || baseDesc == null || baseDesc.textField == null) return false;
		if (v < 0) v = 0;
		if (v > descMaxScroll) v = descMaxScroll;
		if (v == descScrollV) return false;
		descScrollV = v;
		baseDesc.textField.scrollV = v + 1;
		// ★ 改完 scrollV 必须让 FlxText 重新生成贴图，否则画面还是旧的
		//   （fieldHeight 的 setter 里 `_regen = true`，用它当触发器）
		baseDesc.fieldHeight = baseDesc.fieldHeight;
		return true;
	}

	////////////////////////////////////////////////////////////////////////////

	public function setLanguageOverride(description:String, tips:String):Void {
		languageDescriptionOverride = description;
		languageTipsOverride = tips;
		changeLanguage();
	}

	public function changeLanguage() {
		this.description = languageDescriptionOverride ?? Language.get(variable, 'options');
		this.tips = languageTipsOverride ?? Language.get(variable, 'optionTips');
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
		// ★ 换了语言 = 换了一段新描述，行数可能完全不同 → 重新量一次窗口。
		//   注意只挂标记，**不要**在这里写 fieldHeight：此刻文本刚 set、textHeight
		//   还没算出来，一写就会把描述永久裁没（见 fitDescWindow）。
		descNeedFit = true;
		descFitDelay = 1;
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
	// ★ 默认时长 0.5s：单条补间本身就是"一组动画"，卡在 0.5s 这条线上
	//   （规则写在 OptionsState.hx 的动画常量区）。
	public function changeX(data:Float, isMain:Bool = true, time:Float = 0.5) {
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
	public function changeAlpha(isAdd:Bool, time:Float = 0.5) { //无敌了haxeflixel，flxspritegroup你妈炸了
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
			var tween = FlxTween.tween(baseBG, {alpha: CARD_ALPHA}, time, {ease: FlxEase.expoIn});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseTar, {alpha: 0.3}, time, {ease: FlxEase.expoIn});
			alphaTween.push(tween);
			var tween = FlxTween.tween(baseLine, {alpha: CARD_LINE_ALPHA}, time, {ease: FlxEase.expoIn});
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

	/////////////////////////////////////////////////////////////////////////////////////////////
	// 「整条设置项」的安全淡入淡出
	/////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * 全组淡出/淡入的系数（1 = 常态，0 = 完全隐去）。
	 *
	 * ══════════════════════════════════════════════════════════════════════════
	 *  为什么不能直接用 FlxTween.tween(this, {alpha: v})
	 * ══════════════════════════════════════════════════════════════════════════
	 *  FlxSpriteGroup 的 alpha 不是"整体不透明度"，而是把**变化比例**乘到每个
	 *  子元素上（flixel/group/FlxSpriteGroup.hx 的 alphaTransform）：
	 *
	 *      if (Sprite.alpha != 0 || Alpha == 0) Sprite.alpha *= Alpha;
	 *      else Sprite.alpha = 1 / Alpha;      // ← "避免卡住"的暴力写法
	 *
	 *  也就是说：子元素 alpha 恰好是 0 时，flixel 会把它**写成 1/比例**（一个很大
	 *  的数）。淡出再淡入一趟之后：
	 *    · baseBG（本来 0.05 的卡片底）会被放大到 1 → 整块变纯白/纯黑
	 *    · StringSelect 的底板（本来 0，收起状态）被点亮成一块深色面板
	 *      → 看起来就像"下拉列表默认是展开的"
	 *  这正是用户报的「切换的时候二级菜单里面的选项卡变黑、下拉列表凭空展开」。
	 *
	 *  这里改成老老实实保存每个叶子的**基准 alpha**，每次写入 `基准 × 系数`：
	 *  永远不会越界，也不会把本该是 0 的东西点亮。
	 */
	var leafSprites:Array<FlxSprite> = [];
	var leafAlphas:Array<Float> = [];
	var groupFade:Float = 1;

	/**
	 * 采集所有叶子精灵各自的基准 alpha。
	 *
	 * ★★ 下拉列表（select）现在**也参与**内容的淡入淡出 ★★
	 *   以前这里是 `if (m == null || m == select) return;` —— 跳过整棵下拉子树。
	 *   当时的理由是"下拉列表的显隐/alpha 由 StringRect 自己管"，但那是给
	 *   旧版 **alphaTransform 的 `1 / Alpha` 暴力写法** 打的补丁（那个写法会把
	 *   收起状态、alpha 恰好为 0 的底板"点亮"成 1）。现在淡入淡出已经改成
	 *   安全写法（基准 alpha × 系数，永不越界，见 setFade），跳过就不再必要，
	 *   反而留下一个**真实漏洞**：
	 *     内容整体淡出管不到下拉列表 → 切竖/横侧边栏时，周围内容已经淡到
	 *     全透明，唯独展开着的下拉框 + 一列选项还亮着挂在屏幕上（0.48s 的
	 *     模式切换动画全程可见），正是用户报的
	 *     「切竖/横时 Tap to choose 和下拉的列表没有正确隐藏」。
	 *
	 * ★ 基准取「展开态目标值」而不是就地采样：
	 *   收起/展开的那条 0.45s 补间若正跑到一半时切模式，就地采样会拿到中途值
	 *   （例如 0.5）当基准，之后淡入回来就永远停在 0.5 —— 一块半透明的深色
	 *   列表底板常驻内容区。目标值取 StringRect 的三个常量。
	 */
	public function captureLeafAlpha():Void
	{
		leafSprites = [];
		leafAlphas = [];
		for (m in members) captureLeaf(m);
	}

	function captureLeaf(m:FlxSprite):Void
	{
		if (m == null) return;

		if (m == select)
		{
			captureSelectTree();
			return;
		}

		if (Std.isOfType(m, FlxSpriteGroup))
		{
			// 子控件（BoolButton / NumButton / StringRect / StateButton ...）本身也是
			// FlxSpriteGroup，要往下钻一层才能拿到真正的叶子精灵
			var g:FlxSpriteGroup = cast m;
			for (c in g.members) captureLeaf(c);
			return;
		}
		leafSprites.push(m);
		leafAlphas.push(m.alpha);
	}

	/**
	 * 下拉列表子树的基准 alpha：**展开时 = 目标值，收起时 = 0**。
	 * `ChooseRect.bg`（悬停高亮条）不纳入 —— 它每帧自己按 `textDis.alpha` 算。
	 */
	function captureSelectTree():Void
	{
		if (select == null) return;

		var open:Bool = stringRect != null && (stringRect.isOpend || select.isOpend);
		var bgA:Float = open ? StringRect.SEL_BG_ALPHA : 0;
		var slA:Float = open ? StringRect.SEL_SLIDER_ALPHA : 0;
		var txA:Float = open ? StringRect.SEL_TEXT_ALPHA : 0;

		leafSprites.push(select.bg);
		leafAlphas.push(bgA);
		leafSprites.push(select.slider);
		leafAlphas.push(slA);
		for (s in select.optionSprites)
		{
			leafSprites.push(s.textDis);
			leafAlphas.push(txA);
		}
	}

	/** 写入淡入淡出系数。从"常态"进入一次淡出时会重新采样，保证围绕当前状态做。 */
	public function setFade(v:Float):Void
	{
		if (groupFade >= 0.999) captureLeafAlpha();
		groupFade = v;
		for (i in 0...leafSprites.length) leafSprites[i].alpha = leafAlphas[i] * v;
	}

	/** OptionCata.setFade 要用，暴露出去 */
	public function currentFade():Float return groupFade;
}
