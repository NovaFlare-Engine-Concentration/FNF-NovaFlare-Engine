package options.objects;

import options.objects.Option.OptionType;

class OptionCata extends FlxSpriteGroup
{
	public var mainX:Float;
	public var mainY:Float;

	public var heightSet:Float = 0;
	public var heightSetOffset:Float = 0; //用于特殊的高度处理

	public var modAdd:Bool = false;
	public var modsName:String;

	public var optionArray:Array<Option> = [];
	public var saveArray:Array<Option> = []; //用于保存最初所有的option

	public var bg:RoundRect;
	public var follow:NaviGroup;
	public var mem:NaviMember;
	/** 分类的原始名称（语言 key），用于面板标题与计数显示 */
	public var cataName:String = '';

	/**
	 * 本分类里被隐藏的旧版大标题（TITLE 项）的高度，**每个分类自己记**。
	 *
	 * ★ 以前 OptionsState 用一个全局的 `cataTitleH` 取"所有分类里最高的那个 TITLE"，
	 *   再拿它去上移**每一个**分类的内容起点。只要有一个分类的 TITLE 比别的分类高
	 *   （mod 分类、长分类名换行……），其它分类就会被上移过头 ——
	 *   第一个设置项直接钻进面板标题栏里，就是用户报的"最上面被遮挡"。
	 */
	public var titleH:Float = 0;

	public function new(X:Float, Y:Float, width:Float, height:Float)
	{
		super(X, Y);

		mainX = X;
		mainY = Y;

		bg = new RoundRect(0, 0, width, height, width / 75, LEFT_UP, OptionsState.instance.mainColor);
		bg.alpha = 0.75;
		bg.mainX = mainX;
		bg.mainY = mainY;
		add(bg);
	}

	public function addOption(tar:Option) {
		var putX:Float = this.width / 2 / 50;
		var putY:Float = heightSet;
		var sameY = posCheck(tar);
		if (sameY) {
			putX += (this.width - this.width / 2 / 50) / 2;
			putY -= optionArray[optionArray.length - 1].saveHeight;
		}
		tar.sameY = sameY; //用于string展开的时候兼容
		add(tar);

		var specX:Float = 0;
		switch (tar.type)
		{
			case STRING:
				if (sameY)
					specX = (this.width - this.width / 2 / 50) / 2;
			default:
		}

		tar.initX(mainX, putX, specX);
		tar.initY(mainY, putY);

		optionArray.push(tar);
		saveArray.push(tar);

		if (!sameY) heightSet += tar.saveHeight;
	}

	var lastAdd:Option;
	var shouldSame:Bool = false;
	function posCheck(tar):Bool 
	{
		var output:Bool;

		if (lastAdd != null && (lastAdd.type == TEXT || lastAdd.type == TITLE || lastAdd.type == INT || lastAdd.type == FLOAT || lastAdd.type == PERCENT)) {
			output = false;
		} else if (tar.type == TEXT || tar.type == TITLE || tar.type == INT || tar.type == FLOAT || tar.type == PERCENT){
			output = false;
		} else {
			output = !lastAdd.sameY;
		}

		lastAdd = tar;
		
		return output;
	}

	override function update(elapsed:Float)
	{
		mainX = this.x;
		mainY = this.y;
		bg.mainX = mainX;
		bg.mainY = mainY;

		super.update(elapsed);

	}

	public function resetData() {
		for (option in optionArray)
			option.resetData();
	}

	public function changeLanguage() {
		for (option in optionArray) {
			option.changeLanguage();
		}
	}

	/**
	 * 整块分类内容的淡入淡出（1 = 常态，0 = 完全隐去）。
	 *
	 * ★ 不能让 OptionsState 直接补间本组的 alpha —— FlxSpriteGroup 的 alpha 会把
	 *   「变化比例」乘到每个子元素上，而且对 alpha==0 的子元素会写 1/比例，
	 *   一趟淡出淡入就能把设置项的卡片底、下拉列表底板全部放大到不透明
	 *   （用户报的"选项卡变黑 / 下拉列表凭空展开"）。详见 Option.setFade。
	 */
	public function setFade(v:Float):Void
	{
		// 分类自带的底一直保持在"几乎不可见"（面板底由面板自己的磨砂板统一画）
		bg.alpha = 0.0000001 * v;
		for (op in optionArray) op.setFade(v);
	}

	/** 当前淡入淡出系数（以第一个设置项为准，它们始终同步） */
	public function currentFade():Float
	{
		return optionArray.length > 0 ? optionArray[0].currentFade() : 1;
	}

	var addOptions:Array<Option> = [];
	var removeOptions:Array<Option> = [];
	// 默认时长 0.5s：与 OptionsState 的"动画组 ≤ 0.5s"规则一致
	public function startSearch(text:String, time = 0.5) {
		addOptions = [];
		removeOptions = [];
		for (i in 0...saveArray.length) {
			addOptions.push(saveArray[i]);
		}
		if (text != "") {
			for (option in saveArray) {
				if (!option.startSearch(text)) {
					addOptions.remove(option);
					removeOptions.push(option);
				}
			}
		}
		changeOption(time);
	}

	function changeOption(time = 0.5) {
		for (option in addOptions) {
			option.allowUpdate = true;
			option.changeAlpha(true, time);
		}
		for (option in removeOptions) {
			option.allowUpdate = false;
			option.changeAlpha(false, time);
		}
	}

	public function optionAdjust(str:Option, outputData:Float, time:Float = 0.45) {
		var start:Int = -1;
		for (op in 0...optionArray.length) {
			if (str == optionArray[op]) {
				start = op;
				if (start != (optionArray.length - 1) && str.type == STRING && !str.sameY && optionArray[start + 1].sameY)
					start++;
			}

			if (start != -1 && op > start) { 
				optionArray[op].changeOffY(outputData, time);
			}
		}
		heightSetOffset += outputData;

		changeHeight(time);
		OptionsState.instance.cataMoveChange();
	}

	public function peerCheck(str:Option):Bool {
		for (op in 0...optionArray.length) {
			if (str == optionArray[op]) {
				if (optionArray[op].sameY) {
					if (optionArray[op - 1].type == STRING && optionArray[op - 1].select.isOpend) {
						return false;
						break;
					}
				} else {
					if (op != optionArray.length - 1 && optionArray[op + 1].type == STRING && optionArray[op + 1].select.isOpend) {
						return false;
						break;
					}
				}
			}
		}

		return true;
	}

	public function changeHeight(time:Float = 0.5) {
		bg.changeHeight(heightSet + heightSetOffset, time, 'expoInOut');
	}

	public function checkPoint():Bool {
		if (this.y < FlxG.height / 2 && this.y + bg.realHeight > FlxG.height / 2) return true;
		return false;
	}
}
