package options.objects.backend;

import flixel.math.FlxRect;

class StringSelect extends FlxSpriteGroup
{
    public var follow:Option;

    public var bg:Rect;
    public var slider:Rect;

    public var options:Array<String>;
    public var optionSprites:Array<ChooseRect>;

    var mainX:Float = 0;
    var mainY:Float = 0;

    public var specX:Float = 0;

    public var currentSelection:Int = 0;
    public var posiData:Float = 0;
    var optionMove:MouseMove;

    public var isOpend:Bool = false;


    public function new(X:Float, Y:Float, width:Float, height:Float, follow:Option)
    {
        super(X, Y);

        mainX = X;
        mainY = Y;

        this.follow = follow;
        this.options = follow.strGroup;

        //这些alpha会在后面出现的时候设置（具体去看stringrect）

        var calcHeight:Float = height;
        if (follow.strGroup.length < 5) calcHeight = calcHeight * (follow.strGroup.length / 5);

        // 展开列表的底板：必须是**接近不透明的深色**，否则列表看起来就是一堆
        // 白字浮在设置面板上（原来这里是 0xffffff + alpha 0.1，淡到几乎看不见，
        // 对照 HTML 原型 .selmenu{background:rgba(20,19,27,.97)}）。
        // alpha 由 StringRect.change() 在展开/收起时补间。
        bg = new Rect(0, 0, width, calcHeight, width / 75, width / 75, 0x14131D, 0);
        add(bg);

        var init = 80;

        var calcWidth = width * (init - 2) / init;
        optionSprites = [];
        var displayNames = follow.strDisplayGroup;
        for (i in 0...options.length)
        {
            var disName:String = (displayNames != null && i < displayNames.length) ? displayNames[i] : options[i];
            var option = new ChooseRect(width / 80, 0, calcWidth, height / 5, options[i], disName, i, this);
            add(option);
            optionSprites.push(option);
            option.y = follow.followY + follow.innerY + mainY + i * height / 5; //初始化在state的y
        }

        // 创建滑块
        var calcWidth = width / init;
        var calcHeight = bg.height * 5 / options.length;
        if (calcHeight > bg.height) calcHeight = bg.height;
        slider = new Rect(width - calcWidth, 0, calcWidth, calcHeight, calcWidth, calcWidth, 0xffffff, 0);
        add(slider);

        var calc = -1 * (height / 5) * (options.length - 5);
        if (optionSprites.length < 5) calc = 0;

        optionMove = new MouseMove(this, 'posiData',
								[calc , 0],
								[
									[follow.followX + follow.innerX + mainX - specX, follow.followX + follow.innerX + mainX - specX + bg.width],
									[follow.y + mainY, follow.y + mainY + bg.height]
								]
								);
		OptionsState.instance.addMove(optionMove);
        //optionMove.mouseWheelSensitivity = 10;
    }

    public var allowUpdate:Bool = true;
    override public function update(elapsed:Float):Void
    {
        // ★ 下拉列表的「可见」只能由 isOpend 决定。
        //   父级 Option / OptionCata 每次显隐都会把 visible 向下传播（FlxSpriteGroup
        //   的 visibleTransform），收起状态的下拉列表会被父级重新点亮 —— 它那层
        //   深色底板（0x14131D）就会在内容区里显形，看起来像"下拉列表默认展开"。
        //   淡出/淡入也曾经把它的 alpha 放大到 0.96，同样会显形。
        //   这里在每帧开头把它重新绑回 isOpend；关闭补间还没跑完时（bg 还亮着）
        //   不打断，等淡到 0 再由补间自己 onComplete 关掉。
        if (!isOpend && visible && bg.alpha <= 0.02) visible = false;

        optionMove.mouseLimit[0] = [follow.followX + follow.innerX + mainX - specX, follow.followX + follow.innerX + mainX - specX + bg.width];
        optionMove.mouseLimit[1] = [follow.y + mainY, follow.y + mainY + bg.height];
        super.update(elapsed);

        if (!allowUpdate) return;

        if (OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.specBG) || OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.downBG)) return;

         for (i in 0...options.length)
        {
            var option = optionSprites[i];
            var calcHeight = bg.height / 5;
            if (options.length < 5) calcHeight = bg.height / options.length;
            option.y = follow.y + mainY + i * calcHeight + posiData; //初始化在state的y
        }

        var mouse = FlxG.mouse;

        var startY:Float = follow.y + mainY;
        var overY:Float  = follow.y + mainY + bg.height;

        for (str in optionSprites) {
            changeRect(str, startY, overY);
        }

        if (options.length > 5) { //对的其实我是真懒得兼容了
            var data = posiData;
            if (data > 0) data = 0;
            if (data < optionMove.moveLimit[0]) data = optionMove.moveLimit[0];
            data = Math.abs(data);
            slider.y = follow.y + mainY + (data / Math.abs(optionMove.moveLimit[0])) * (bg.height - slider.height);
        }
    }

    function changeRect(str:ChooseRect, startY:Float, overY:Float) { //ai真的太好用了喵 --狐月影
        // 获取选项矩形的顶部和底部坐标（相对于父容器）
        var optionTop = str.y;
        var optionBottom = str.y + str.height;

        // 计算实际可见区域
        var visibleTop = Math.max(optionTop, startY);    // 可见顶部取两者最大值
        var visibleBottom = Math.min(optionBottom, overY); // 可见底部取两者最小值

        // 完全不可见的情况（在背景上方或下方）
        if (visibleBottom <= startY || visibleTop >= overY) {
            str.visible = false;
            str.allowChoose = false;
            return;
        }

        // 设置可见性
        str.visible = true;
        str.allowChoose = true;

        // 计算裁剪参数（基于局部坐标系）
        var clipY = Math.max(0, startY - optionTop);  // 裁剪上边距
        var clipHeight = visibleBottom - visibleTop;  // 可见高度

        // 创建/更新裁剪矩形
        var swagRect = str.clipRect;
        if (swagRect == null) {
            swagRect = new FlxRect(0, clipY, str.width, clipHeight);
        } else {
            swagRect.set(0, clipY, str.width, clipHeight);
        }

        // 应用裁剪
        str.clipRect = swagRect;
    }

    public function updateSelection(index:Int):Void
    {
        for (i in 0...optionSprites.length) {
            if (i == index) optionSprites[i].setAlpha = 0.1;
            else optionSprites[i].setAlpha = 0;
        }
    }
}


class ChooseRect extends FlxSpriteGroup {
    public var bg:Rect;
    public var textDis:FlxText;

    public var optionSort:Int;

    var follow:StringSelect;

    var name:String;
    var displayName:String;

    public var setAlpha:Float = 0;

    ///////////////////////////////////////////////////////////////////////////////

    public function new(X:Float, Y:Float, width:Float, height:Float, name:String, displayName:String, sort:Int, follow:StringSelect) {
        super(X, Y);
        this.follow = follow;
        this.name = name;
        this.displayName = displayName;

        optionSort = sort;

        bg = new Rect(0, 0, width, height, height / 5, height / 5, 0x96B5FF, 0);
        add(bg);

        textDis = new FlxText(0, 0, 0, displayName, Std.int(height * 0.15));
		textDis.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(height * 0.45), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        textDis.borderStyle = NONE;
		textDis.antialiasing = ClientPrefs.data.antialiasing;
        textDis.y += (height - textDis.height) * 0.5;
		add(textDis);
        textDis.alpha = 0;

        if (name == follow.follow.getValue()) setAlpha = 0.1; //标亮之前的设置
    }

    public var onFocus:Bool = false;
    public var onPress:Bool = false;
    public var onChoose:Bool = false;
    public var allowUpdate:Bool = false;
    public var allowChoose:Bool = false;
    override function update(elapsed:Float) {
        super.update(elapsed);

        if (!follow.allowUpdate) {
            return;
        }

        var mouse = OptionsState.instance.mouseEvent;

		onFocus = mouse.overlaps(this);

		if (onFocus) {
            if (bg.alpha < 1) bg.alpha += EngineSet.FPSfix(0.09);

            if (mouse.justPressed) {

            }

            if (mouse.pressed) {
                onChoose = true;
            }

            if (mouse.justReleased && allowUpdate && allowChoose) {
                follow.follow.setValue(name);
                follow.follow.updateDisText();
                follow.follow.change();
                follow.updateSelection(optionSort);
                follow.follow.stringRect.change(); //关闭设置了喵
            }
        } else {
            if (bg.alpha > setAlpha) bg.alpha -= EngineSet.FPSfix(0.09);
            if (setAlpha > bg.alpha) bg.alpha = setAlpha;
        }

        bg.alpha = bg.alpha * textDis.alpha;

        if (!mouse.pressed)
        {

        }
	}
}
