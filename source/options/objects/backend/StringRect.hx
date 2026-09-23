package options.objects.backend;

import openfl.display.Shape;
import openfl.display.BitmapData;

class StringRect extends FlxSpriteGroup{
    public var bg:Rect;
    public var dis:FlxSprite;
    public var disText:FlxText;

    var follow:Option;

    var innerX:Float; //该摁键在option的x
    var innerY:Float; //该摁键在option的y

    public var isOpend:Bool = false;

    public function new(X:Float, Y:Float, width:Float, height:Float, follow:Option) {
        super(X, Y);

        this.follow = follow;
        innerX = X;
        innerY = Y;

        // web 原型 .selbtn：background:rgba(255,255,255,.06) + border:1px solid rgba(255,255,255,.11)
        // ★ 原来是 0x000000 / 0.3 —— 在深色面板上就是一块黑砖，和设置项卡片一起
        //   被用户当成"选项卡变黑了"。这里统一改成极淡的白。
        bg = new Rect(0, 0, width, height, width / 20, width / 20, 0xFFFFFF, 0.10);
        bg.antialiasing = ClientPrefs.data.antialiasing;
        add(bg);

        disText = new FlxText(0, 0, 0, 'Tap to choose', Std.int(bg.width / 20 / 2));
		disText.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(bg.height / 2), 0xffffff, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        disText.antialiasing = ClientPrefs.data.antialiasing;
		disText.borderStyle = NONE;
		disText.x += bg.mainRound;
		disText.alpha = 0.3;
        disText.y += (bg.height - disText.height) / 2;
		add(disText);

        dis = new FlxSprite();
        dis.loadGraphic(createButton(height * 0.75, 0xffffff));
        dis.antialiasing = ClientPrefs.data.antialiasing;
        dis.x += bg.width - dis.width - (bg.height - dis.height) / 2; 
        dis.y += (bg.height - dis.height) / 2;
        dis.flipY = true;
        add(dis);
    }

    public var allowUpdate:Bool = true;
    var timeCalc:Float;
    override function update(elapsed:Float) {
        super.update(elapsed);

        timeCalc += elapsed;

        if (!follow.allowUpdate) {
            timeCalc = 0;
            return;
        }
        
        if (!allowUpdate) return;

        if (timeCalc < 0.6) return;

        if (OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.specBG) || OptionsState.instance.mouseEvent.overlaps(OptionsState.instance.downBG)) return;
        
        var mouse = OptionsState.instance.mouseEvent;

        if (mouse.overlaps(bg)) {

            bg.color = 0x96B5FF;
            bg.alpha = 0.16;

            disText.color = 0xFFFFFF;
            disText.alpha = 1;

            dis.color = 0xFFFFFF;
            dis.alpha = 1;

            if (mouse.justReleased) {
                change();
            }
        } else {
            bg.color = 0xFFFFFF;
            bg.alpha = 0.10;

            disText.color = 0xE8EAF6;
            disText.alpha = 0.55;

            dis.color = 0xFFFFFF;
            dis.alpha = 0.35;
        }
    }

    var alphaTween:Array<FlxTween> = [];
    var changeTimer:Float = 0.45;

    // ── 下拉列表「展开态」的目标 alpha ──────────────────────────────────
    // ★ 提成常量不是为了好看：内容的整体淡入淡出（Option.setFade）现在**也要
    //   管到下拉列表**（见 Option.captureLeaf），而它必须知道"展开时该是多少"。
    //   如果改成"就地采样当前 alpha"，那么在收起/展开补间正好跑到一半时切模式，
    //   采样到的是中途值（比如 0.5），之后淡入回来就永远停在 0.5 ——
    //   一块半透明的深色列表底板常驻在内容区，也就是用户报的
    //   「切竖/横时 Tap to choose 和下拉列表没有正确隐藏」。
    public static inline var SEL_BG_ALPHA:Float = 0.96;
    public static inline var SEL_SLIDER_ALPHA:Float = 0.8;
    public static inline var SEL_TEXT_ALPHA:Float = 1.0;

    public function change() {
        for (tween in alphaTween) {
            tween.cancel();
        }

        if (!follow.follow.peerCheck(follow)) return;

        if (isOpend) { //关闭
            disText.text = 'Tap to choose';
            dis.flipY = true;
            
            var tween = FlxTween.tween(follow.select.bg, {alpha: 0}, changeTimer, {ease: FlxEase.expoOut, onComplete: function(twn:FlxTween){follow.select.active = follow.select.visible = false; if (OptionsState.instance.stringCount.contains(follow.select)) OptionsState.instance.stringCount.remove(follow.select);} });
            alphaTween.push(tween);
            var tween = FlxTween.tween(follow.select.slider, {alpha: 0}, changeTimer, {ease: FlxEase.expoOut});
            alphaTween.push(tween);
            
            for (i in 0...follow.select.optionSprites.length) {
                follow.select.optionSprites[i].allowUpdate = false;
                var tween = FlxTween.tween(follow.select.optionSprites[i].textDis, {alpha: 0}, changeTimer, {ease: FlxEase.expoOut});
                alphaTween.push(tween);
            }

            follow.follow.optionAdjust(follow, -1 * (follow.select.bg.height + follow.inter));
            isOpend = !isOpend;
            follow.select.isOpend = isOpend;
        } else { //开启 
            if (!OptionsState.instance.stringCount.contains(follow.select)) OptionsState.instance.stringCount.push(follow.select);
            disText.text = 'Tap to close';
            dis.flipY = false;

            follow.select.active = follow.select.visible = true;
            var tween = FlxTween.tween(follow.select.bg, {alpha: SEL_BG_ALPHA}, changeTimer, {ease: FlxEase.expoIn});
            alphaTween.push(tween);
            var tween = FlxTween.tween(follow.select.slider, {alpha: SEL_SLIDER_ALPHA}, changeTimer, {ease: FlxEase.expoIn});
            alphaTween.push(tween);
            for (i in 0...follow.select.optionSprites.length) {
                var tween = FlxTween.tween(follow.select.optionSprites[i].textDis, {alpha: SEL_TEXT_ALPHA}, changeTimer, {ease: FlxEase.expoIn, onComplete: function(twn:FlxTween){ follow.select.optionSprites[i].allowUpdate = true;} });
                alphaTween.push(tween);
            }

            follow.follow.optionAdjust(follow, follow.select.bg.height + follow.inter);
            isOpend = !isOpend;
            follow.select.isOpend = isOpend;
        }
    }

    /**
     * 立刻把下拉列表收起来（不走补间）。**幂等**，可以无条件反复调用。
     *
     * ★ 为什么不能只靠 change() ★
     *   change() 收起走的是 0.45s 补间：`bg.alpha → 0`，**要等 onComplete
     *   才把 `select.visible` 置 false**；而 `isOpend` 是立刻置 false 的。
     *   切竖/横侧边栏时面板会整体重排、内容重算一次，那条补间要么还没跑完、
     *   要么被 cancel 掉 → 一块深色底板 + 一列选项行就停在展开态浮在新面板上
     *   （用户报的"切模式时 Tap to choose 和下拉列表没正确隐藏"）。
     *   这里直接落位、绕开补间，并把 `disText` 从 "Tap to close" 复位。
     */
    public function forceClose():Void
    {
        for (t in alphaTween) t.cancel();
        alphaTween = [];

        // ★ "确实开着"的判据：两个 isOpend 任一为真都算。
        //   它们正常是同步的，但**收起补间进行中**时 `isOpend` 会先变 false、
        //   `select.isOpend` 也同步变 false，而 select.visible 还亮着 ——
        //   所以这里再看一眼 visible / alpha，避免"已经收一半"的下拉被漏判。
        var wasOpen:Bool = isOpend;

        if (follow.select != null)
        {
            if (follow.select.isOpend || follow.select.visible || follow.select.bg.alpha > 0.01) wasOpen = true;
            follow.select.bg.alpha = 0;
            follow.select.slider.alpha = 0;
            for (s in follow.select.optionSprites)
            {
                s.textDis.alpha = 0;
                s.allowUpdate = false;
            }
            follow.select.isOpend = false;
            follow.select.active = follow.select.visible = false;
            if (OptionsState.instance.stringCount.contains(follow.select))
                OptionsState.instance.stringCount.remove(follow.select);
        }

        // ★★ 无条件复位文本 ★★
        //   收起走的是补间（0.45s），期间用户如果切模式，上面那句
        //   `t.cancel()` 会把补间掐掉 —— 原本靠 onComplete 复位的东西就全留下了。
        //   "Tap to close" 留在框上正是用户说的"没有正确隐藏"的一部分。
        //   这里直接写回占位文本（幂等，本来就是这个值时也不亏）。
        disText.text = 'Tap to choose';
        dis.flipY = true;

        isOpend = false;

        if (wasOpen && follow.select != null)
            // 把展开时占走的版面还回去（会重算分类总高 —— 时间给到最小，等价于立即）
            follow.follow.optionAdjust(follow, -1 * (follow.select.bg.height + follow.inter), 0.001);
    }

    private function createButton(size:Float, color:Int) {
        var button = new Shape();
        button.graphics.beginFill(color);
        
        // 2. 设置符号绘制样式
        button.graphics.lineStyle(3, 0xffffff); // 白色线条，3像素粗
        
        // 3. 计算符号位置（保留30%边距）
        var margin = size * 0.3;
        var centerX = size / 2;
        var symbolHeight = size * 0.4; // 符号高度占40%
        
        // 4. 绘制"^"符号
        button.graphics.moveTo(centerX, margin); // 起点：顶部中心
        button.graphics.lineTo(size * 0.22, margin + symbolHeight); // 向左下画线
        button.graphics.moveTo(centerX, margin); // 回到起点
        button.graphics.lineTo(size * 0.78, margin + symbolHeight); // 向右下画线
        
        // 5. 转换为BitmapData
        var bitmap = new BitmapData(Std.int(size), Std.int(size), true, 0);
        bitmap.draw(button);
        return bitmap;
    }
}