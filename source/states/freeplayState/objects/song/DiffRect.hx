package states.freeplayState.objects.song;

import flixel.math.FlxRect;

class DiffRect extends FlxSpriteGroup {
    static public final fixWidth:Int = SongRect.fixWidth - 50;
    static public final fixHeight:Int = #if mobile 50 #else 45 #end;

    public var id:Int = 0;

    public var onFocus(default, set):Bool = true;
    public var allowDestroy:Bool = false;
    public var allowSelect:Bool = false;

    /////////////////////////////////////////////////

    public var background:Rect;
    private var overlay:Rect;
    private var triangles:FlxSpriteGroup;
    private var light:SegmentGradientRoundRect;
    private var selectLight:Rect;

    private var diffName:FlxText;
    private var charterName:FlxText;

    var follow:SongRect;

    public function new(follow:SongRect, name:String, color:FlxColor, charter:String) {
        super();

        var w:Float = follow.selectShow.width;
        var h:Float = fixHeight;
        var r:Float = h / 3;

        background = new Rect(0, 0, w, h, r, r, color);
        add(background);

        overlay = new Rect(20, 1, w - 40, h - 2, r, r, FlxColor.BLACK, 0.4);
        add(overlay);

        triangles = new FlxSpriteGroup();
        add(triangles);

        for (i in 0...10) {
            var size:Float = FlxG.random.float(40, 80);
            var tri:Triangle = new Triangle(FlxG.random.float(20, w - 20), FlxG.random.float(h * 0.2, h - size), size, size - 5);
            tri.velocity.y = -FlxG.random.float(5, 15);
            tri.y = this.y + h + FlxG.random.float(0, h);
            tri.color = color;
            updateRect(tri);
            triangles.add(tri);
        }

        light = new SegmentGradientRoundRect(0, 0, Std.int(w), Std.int(h), Std.int(r), FlxColor.WHITE, [[0.3, 0.5, 0], [1, 0.5, 0.3]], 1);
        light.antialiasing = ClientPrefs.data.antialiasing;
        light.blend = ADD;
        light.alpha = 0;
        add(light);

        diffName = new FlxText(20 + 10, 0, 0, name, Std.int(fixHeight * 0.4));
        diffName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(fixHeight * 0.4), FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0x00FFFFFF);
        diffName.borderSize = 0;
        diffName.x -= (diffName.width - diffName.textField.textWidth) / 2;
        diffName.antialiasing = ClientPrefs.data.antialiasing;
        diffName.active = false;
        add(diffName);

        charterName = new FlxText(20 + 10 + 10 + diffName.textField.textWidth, 0, 0, 'Charter: ' + charter, Std.int(fixHeight * 0.4));
        charterName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(fixHeight * 0.4), FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, 0x00393939);
        charterName.borderSize = 0;
        charterName.x -= (charterName.width - charterName.textField.textWidth) / 2;
        charterName.antialiasing = ClientPrefs.data.antialiasing;
        charterName.active = false;
        add(charterName);

        selectLight = new Rect(0, 0, w, h, r, r, 0xFFFFFF, 0);
        selectLight.antialiasing = ClientPrefs.data.antialiasing;
        selectLight.blend = ADD;
        selectLight.alpha = 0;
        add(selectLight);

        this.follow = follow;
    }

    override function update(elapsed:Float) {
        if (allowSelect && !FreeplayState.instance.stopAll && follow.searchMatch) {
            var mouse = FreeplayState.instance.mouseEvent;

            if (FlxG.mouse.y < FlxG.height - 65 && FlxG.mouse.y > 70) {
                if (mouse.overlaps(this.background)) {
                    if (!onFocus) selectLight.alpha = 0.1;
                    if (mouse.justReleased) {
                        if (!this.onFocus) {
                            changeSelectAll();
                            selectLight.alpha = 0.6;
                        } else {
                            FreeplayState.instance.startGame();
                        }
                    }
                }
            }
        }

        super.update(elapsed);

        if (allowDestroy && startY == 0) {
            allowDestroy = false;
            follow.requestDestroyDiff();
        }
    }

    override function drawUpdate(elapsed:Float) {

        for (member in triangles.members) {
            var tri:Triangle = cast(member, Triangle);
            if (tri == null) continue;
            tri.y += tri.velocity.y * elapsed;
            if (tri.y + tri.height < this.y) {
                var w = background.width;
                var h = background.height;
                var s = FlxG.random.float(5, 15);
                tri.x = this.x + FlxG.random.float(20, w - 20);
                tri.y = this.y + h + FlxG.random.float(0, h);
                tri.velocity.y = -FlxG.random.float(4, 20);
                tri.scale.set(1, 1);
            }
            updateRect(tri);
        }

        selectLight.alpha -= elapsed;

        if (light.alpha > 0) {
            light.alpha -= elapsed / (Conductor.crochet * 2 / 1000);
        }

        super.drawUpdate(elapsed);
    }

    private function updateRect(tri:Triangle) {
        var optionTop = tri.y;
        var optionBottom = tri.y + tri.height;
        var startY = this.y;
        var overY = this.y + background.height;
        var visibleTop = Math.max(optionTop, startY);
        var visibleBottom = Math.min(optionBottom, overY);
        if (visibleBottom <= startY || visibleTop >= overY) {
            tri.visible = false;
            return;
        }
        tri.visible = true;

        var clipY = Math.max(0, startY - optionTop);
        var clipHeight = visibleBottom - visibleTop;
        var swagRect = tri.clipRect;
        if (swagRect == null) {
            swagRect = new FlxRect(0, clipY, tri.width, clipHeight);
        } else {
            swagRect.set(0, clipY, tri.width, clipHeight);
        }
        tri.clipRect = swagRect;
    }

    private function set_onFocus(value:Bool):Bool {
        if (onFocus == value) return onFocus;
        onFocus = value;
        
        return value;
    }

    public function beatHit() {
        if (!onFocus) return;
        light.alpha = 1;
    }

    public function changeSelectAll() {
        FreeplayState.curDifficulty = this.id;
        follow.diffFouceUpdate();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        FreeplayState.instance.songsMove.tweenData = FlxG.height * 0.5 - SongRect.fixHeight * 0.5 - FreeplayState.instance.getEffectiveId(FreeplayState.curSelected) * SongRect.fixHeight * FreeplayState.instance.rectInter - (FreeplayState.curDifficulty+1) * DiffRect.fixHeight * 1.05;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    public var realX:Float = 0;
    public var startX:Float = 0;
    public var chooseX:Float = 0;

    public function calcX() {
        startX = Math.pow(Math.abs(realY + this.background.height / 2 - FlxG.height / 2) / (FlxG.height / 2) * 10, 1.8);

        var chooseTar = onFocus ? -fixWidth * 0.125 : 0;
        if (Math.abs(chooseX - chooseTar) > 0.01) chooseX = FlxMath.lerp(chooseTar, chooseX, Math.exp(-FreeplayState.instance.songsMove.saveElapsed * FreeplayState.instance.songsMove.lerpSmooth));
        else chooseX = chooseTar;
        
        realX = FlxG.width - fixWidth * 0.85 + startX + chooseX + follow.searchOffset;
    }

    public var realY:Float = 0;

    public var startTarY:Float = 0;
    public var startY:Float = 0;
    public function calcY() {
        if (Math.abs(startY - startTarY) > 0.01)
            startY = FlxMath.lerp(startTarY, startY, Math.exp(-FreeplayState.instance.songsMove.saveElapsed * FreeplayState.instance.songsMove.lerpSmooth));
        else
            startY = startTarY;

        realY = follow.realY + startY;
    }

    override function draw() {
        this.x = realX;
        this.y = realY;

        super.draw();
    }
}
