package options.objects.backend;

import openfl.display.Shape;
import openfl.display.BitmapData;

class NumButton extends FlxSpriteGroup {

    var follow:Option;

    var innerX:Float; //该摁键在option的x
    var innerY:Float; //该摁键在option的y

    public var deleteButton:FlxSprite;
    public var addButton:FlxSprite;

    public var moveBG:Rect;
    public var moveDis:Rect;
    public var rod:Rect;

    /**
     * 条的**满宽**（= 底槽宽度）。
     * ★ 计算填充宽度/杆位置一律用它，不要用 `moveDis.width` / `moveBG.width` 反推
     *   （`moveDis` 是靠 scale.x 缩着显示的，`.width` 不反映"亮到哪"）。
     */
    var barFullW:Float = 0;
	
    var max:Float;
    var min:Float;

    public function new(X:Float, Y:Float, width:Float, height:Float, follow:Option) {
        super(X, Y);

        this.follow = follow;
        this.min = follow.minValue;
        this.max = follow.maxValue;
        innerX = X;
        innerY = Y;

        deleteButton = new FlxSprite();
        deleteButton.loadGraphic(createButton(height * 0.75, 0xFF6363, '-'));
        deleteButton.antialiasing = ClientPrefs.data.antialiasing;
        deleteButton.y += (height - deleteButton.height) / 2;
        add(deleteButton);

        addButton = new FlxSprite();
        addButton.loadGraphic(createButton(height * 0.75, 0x63FF75, '+'));
        addButton.antialiasing = ClientPrefs.data.antialiasing;
        addButton.x += width - addButton.width;
        addButton.y += (height - addButton.height) / 2;
        add(addButton);

        /** 条的起点（相对本组）与满宽 —— 底槽和填充共用同一份几何 */
        var barX:Float = deleteButton.width * 1.2;
        barFullW = width - (deleteButton.width + addButton.width) * 1.2;

        moveBG = new Rect(barX, 
                         0, 
                         barFullW, 
                         deleteButton.height * 0.5, 
                         deleteButton.height * 0.5 * 0.5, 
                         deleteButton.height * 0.5 * 0.5,
                         0xFF000000,
                         0.4
                         );
        moveBG.y += (height - moveBG.height) / 2;
        add(moveBG);

        moveDis = new Rect(barX, 
                         0, 
                         barFullW, 
                         deleteButton.height * 0.5, 
                         deleteButton.height * 0.5 * 0.5, 
                         deleteButton.height * 0.5 * 0.5,
                         EngineSet.mainColor,
                         1.0,
                         0,
                         0xFFFFFFFF,
                         // ★ noCache = true 是【必需】的：rectUpdate 会改这张帧的宽度来
                         //   取"左边一段"当填充，绝不能用 Cache 里那份被所有同尺寸条
                         //   共用的帧（否则一条改宽、全都跟着变 —— 详见 Rect 构造函数注释）
                         true
                         );
        moveDis.y += (height - moveDis.height) / 2;
        // ★ flixel 的 `origin` 默认是【中心】（见 FlxSprite.hx 里 centerOrigin 的注释），
        //   所以直接改 scale.x 是"绕中心缩" —— 左边缘会右移 origin.x*(1-scale)，
        //   填充会飘到条的中间去（实测 p=1/3 时落在 887~998，而不是 769~884）。
        //   → 把原点挪到左上角，缩放才会从左边缘起算。
        moveDis.origin.set(0, 0);
        add(moveDis);

        rod = new Rect(deleteButton.width * 1.2, 
                        0, 
                        height / 10, 
                        deleteButton.height, 
                        height / 10, 
                        height / 10, 
                        0xffffff,
                        1.0
                        );
        rod.y += (height - rod.height) / 2;
        add(rod);

        initData();
    }

    public function initData() {
        var percent = (follow.defaultValue - min) / (max - min);
        rectUpdate(percent);
    }

    public var onFocus:Bool = false;

    var focusAdd:Bool = false;
    var addHoldTime:Float = 0;

    var focusDelete:Bool = false;
    var deleteHoldTime:Float = 0;

    override function update(elapsed:Float)
	{
		super.update(elapsed);

        if (!follow.allowUpdate) return;

        if (OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.specBG) || OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.downBG)) return;

        var mouse = FlxG.mouse;

		if (mouse.y > rod.y && mouse.y < (rod.y + rod.height) && mouse.x > (rod.x - rod.width * 4) && mouse.x < (rod.x + rod.width * 4) && mouse.justPressed)
		{
			onFocus = true;
            lastMouseX = mouse.x;
		}

        var inputAllow:Bool = true;

        if (Math.abs(OptionsState.instance.cataMove.velocity) > 2) inputAllow = false;

        if (inputAllow) {
            if (onFocus && mouse.pressed)
                onHold();

            if (mouse.justReleased)
            {
                onFocus = false;
            }

            if (mouse.overlaps(addButton))
            {
                if (mouse.justPressed) {  
                    changeData(true);
                    focusAdd = true;
                }

                if (mouse.pressed && focusAdd) {  
                    OptionsState.instance.cataMove.inputAllow = false;
                    if (addHoldTime > 0.3) {
                        addHoldTime -= 0.01;
                        changeData(true);
                    } else {
                        addHoldTime += elapsed;
                    }

                    if (addButton.scale.x > 0.8)
                        addButton.scale.x = addButton.scale.y -= ((addButton.scale.x - 0.8) * (addButton.scale.x - 0.8) * 0.75);
                } else {
                    addHoldTime = 0;
                    focusAdd = false;
                }
            } else {
                addHoldTime = 0;
                focusAdd = false;
            }

            if (mouse.overlaps(deleteButton))
            {
                if (mouse.justPressed) {  
                    changeData(false);
                    focusDelete = true;
                }

                if (mouse.pressed && focusDelete) {  
                    OptionsState.instance.cataMove.inputAllow = false;
                    if (deleteHoldTime > 0.3) {
                        deleteHoldTime -= 0.01;
                        changeData(false);
                    } else {
                        deleteHoldTime += elapsed;
                    }

                    if (deleteButton.scale.x > 0.8)
                        deleteButton.scale.x = deleteButton.scale.y -= ((deleteButton.scale.x - 0.8) * (deleteButton.scale.x - 0.8) * 0.75);
                } else {
                    deleteHoldTime = 0;
                    focusDelete = false;
                }
            } else {
                deleteHoldTime = 0;
                focusDelete = false;
            }
        }

        if (addButton.scale.x < 1 && !focusAdd)
            addButton.scale.x = addButton.scale.y += ((1 - addButton.scale.x) * (1 - addButton.scale.x) * 0.5);
        if (deleteButton.scale.x < 1 && !focusDelete)
            deleteButton.scale.x = deleteButton.scale.y += ((1 - deleteButton.scale.x) * (1 - deleteButton.scale.x) * 0.5);
	}

    var lastMouseX = 0;
    function onHold()
	{
        OptionsState.instance.cataMove.inputAllow = false;
        var deltaX:Float = FlxG.mouse.x - lastMouseX;
        lastMouseX = FlxG.mouse.x;
        if (deltaX == 0) return;

		rod.x += deltaX;

        var startX = follow.followX + follow.innerX + innerX + deleteButton.width * 1.2;
		if (rod.x < startX)
			rod.x = startX;
		if (rod.x + rod.width > startX + moveBG.width)
			rod.x = startX + moveBG.width - rod.width;

		var percent = (rod.x - moveBG.x) / (moveBG.width - rod.width);
        var outputData = FlxMath.roundDecimal(min + (max - min) * percent, follow.decimals);
        rectUpdate(percent, outputData);
	}

    function changeData(isAdd:Bool)
	{
		var outputData:Float = follow.getValue();
		if (isAdd)
			outputData += Math.pow(0.1, follow.decimals);
		else
			outputData -= Math.pow(0.1, follow.decimals);

		if (outputData < min)
			outputData = min;
		if (outputData > max)
			outputData = max;

		outputData = FlxMath.roundDecimal(outputData, follow.decimals);
		var percent = (outputData - min) / (max - min);

		rectUpdate(percent, outputData);
	}

    function rectUpdate(percent:Float, ?outputData)
	{
		if (percent < 0) percent = 0;
		if (percent > 1) percent = 1;

		// ★★ 踩坑记录（下面两条都是实测踩出来的，别再走回头路）：
		//   ① 只改 `_frame.frame.width` 不够：它管的是【源矩形】，而 Sprite 的
		//      【目标宽】是建好时定死的整条宽（= frameWidth × scale.x，跟源无关），
		//      于是"115px 的源"被横向【拉伸】回 345px，画面上依旧是一条满的 ——
		//      这正是用户报的"显示的与实际上不符"（p=1/3 时整条全亮，只有杆在 1/3）。
		//   ② 改用 clipRect 也不行：`clipRect.width` 只改、不重新赋值的话根本不生效
		//      （setter 才干活，见 Bar.hx 那句 `// flixel is retarded`）；
		//      而走了 setter 之后 `frame.clipTo()` 是在【原帧上累积】缩减的，
		//      一旦被裁到 1px 就再也回不到满宽（实测滚到最大时整条反而全灭）。
		//   → 正解：**源和目标按同一比例一起缩** —— 源只取纹理最左边 fillW，
		//     同时用 scale.x 把目标宽也缩到 fillW，两者 1:1，既不拉伸也不累积。
		// ★ 一律用 barFullW 算 —— 不能用 moveDis.width / moveBG.width 反推。
		var fillW:Float = barFullW * percent;
		if (fillW < 1)
			fillW = 1;
		moveDis._frame.frame.width = fillW;     // 源：只取纹理最左边 fillW
		moveDis.scale.x = fillW / barFullW;     // 目标：跟着缩，否则会被拉伸回满宽
		// 杆跨在填充右缘上（左右各半个杆宽）：percent=1 时杆的右缘正好贴住条的右缘
		rod.x = follow.followX + follow.innerX + innerX + deleteButton.width * 1.2 + (barFullW - rod.width) * percent;

        if (outputData == null) return;
        follow.setValue(outputData);
		follow.change();
        follow.updateDisText();
	}
    
    /** 绘制圆角方块按钮位图（+/- 符号白线）。其它控件可复用同一样式。 */
    public static function createButton(size:Float, color:Int, symbol:String) {
        // 绘制按钮背景
        var button = new Shape();
        button.graphics.beginFill(color);
        button.graphics.drawRoundRect(0, 0, size, size, size / 4, size / 4);
        button.graphics.endFill();
        
        // 绘制符号
        button.graphics.lineStyle(3, 0xffffff); // 白色线条，3像素粗
        
        if (symbol == "+") {
            // 绘制加号：横线
            button.graphics.moveTo(size * 0.2, size * 0.5);
            button.graphics.lineTo(size * 0.8, size * 0.5);
            // 绘制加号：竖线
            button.graphics.moveTo(size * 0.5, size * 0.2);
            button.graphics.lineTo(size * 0.5, size * 0.8);
        } else if (symbol == "-") {
            // 绘制减号：横线
            button.graphics.moveTo(size * 0.2, size * 0.5);
            button.graphics.lineTo(size * 0.8, size * 0.5);
        }
        var bitmap:BitmapData = new BitmapData(Std.int(size), Std.int(size), true, 0);
		bitmap.draw(button);
		return bitmap;
    }
}