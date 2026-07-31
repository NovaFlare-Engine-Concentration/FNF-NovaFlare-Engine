package states.freeplayState.objects.song;

import games.objects.HealthIcon;
import flixel.graphics.FlxGraphic;
import lime._internal.graphics.ImageDataUtil;
import lime.graphics.Image as LimeImage;
import lime.math.Rectangle as LimeRectangle;
import lime.math.Vector2;

class SongRect extends FlxSpriteGroup {

    static public final fixWidth:Int = 560;
    static public final fixHeight:Int = #if mobile 80 #else 70 #end;

    public var id:Int = 0;
    
    public var onSelectChange:String->Void;

    public var bgPath:String;

    public var songNameSt:String = '';
    public var songMusican:String = '';

    /////////////////////////////////////////////////////////////////////

    public var haveDiffDis:Bool = false;
    public var _songCharter:Array<String>;
    private var _songColor:FlxColor;

    public var diffRectGroup:FlxSpriteGroup;

    static public var openRect:SongRect;

    public var searchMatch:Bool = true;
    public var searchOffset:Float = 0;

    static var openRectRequestId:Int = 0;
    var destroyDiffRequested:Bool = false;

    public var selectShow:Rect;
    private var bg:FlxSprite;
    private var light:SegmentGradientRoundRect;
    private var black:SegmentGradientRoundRect;
    private var icon:HealthIcon;
    private var songName:FlxText;
    private var musican:FlxText;
    private var selectLight:Rect;

    public function new(songNameSt:String, songIcon:String, songMusican:String, songCharter:Array<String>, songColor:Array<Int>) {
        super(0, 0);

        this.songNameSt = songNameSt;
        this.songMusican = songMusican;
        
        diffRectGroup = new FlxSpriteGroup();
        add(diffRectGroup);

        selectShow = new Rect(2, 0, fixWidth, fixHeight, fixHeight / 4, fixHeight / 4, FlxColor.WHITE, 1, 0, EngineSet.mainColor);
        selectShow.antialiasing = ClientPrefs.data.antialiasing;
		// The song thumbnail is opaque and covers this mask exactly. Keep its
		// pixels for thumbnail alpha masking without submitting an invisible
		// extra quad for every row.
		selectShow.alpha = 0;
        add(selectShow);
        
        var path:String = PreThreadLoad.bgPathCheck(Mods.currentModDirectory, 'data/${songNameSt}/bg');
        bgPath = path;

        bg = new FlxSprite();
		if (Cache.checkFrame(path))
			bg.frames = Cache.getFrame(path);
		else
		{
			// Do not decode every full-resolution song background while opening
			// Freeplay.  Some mods ship 8K PNGs (over 150 MiB decoded each), and
			// eagerly touching all of them permanently inflated the native heap.
			// Reuse the already-cached menu texture until this song becomes the
			// settled selection; that decode also produces the row thumbnail.
			bg.loadGraphic(Paths.image('menuDesat'));
		}
		bg.setGraphicSize(fixWidth, fixHeight);
		bg.updateHitbox();
		bg.antialiasing = ClientPrefs.data.antialiasing;
        if (!Cache.checkFrame(path) || path.indexOf('menuDesat') != -1)
            bg.color = FlxColor.fromRGB(songColor[0], songColor[1], songColor[2]);
		add(bg);

        _songCharter = songCharter;
        _songColor = FlxColor.fromRGB(songColor[0], songColor[1], songColor[2]);

        black = new SegmentGradientRoundRect(0, 0, Std.int(selectShow.width), Std.int(selectShow.height), fixHeight / 4, FlxColor.BLACK , [[0, 0.5, 0.3], [0.7, 0.5, 0]], 1);
        black.antialiasing = ClientPrefs.data.antialiasing;
        add(black);

        light = new SegmentGradientRoundRect(0, 0, Std.int(selectShow.width), Std.int(selectShow.height), fixHeight / 4, FlxColor.WHITE, [[0.3, 0.5, 0], [1, 0.5, 0.3]], 1);
        light.antialiasing = ClientPrefs.data.antialiasing;
        light.blend = ADD;
        light.alpha = 0;
        add(light);

        icon = new HealthIcon(songIcon, false, false);
		icon.setGraphicSize(Std.int(bg.height * 0.8));
		icon.x += bg.height / 2 - icon.height / 2;
		icon.y += bg.height / 2 - icon.height / 2;
		icon.updateHitbox();
		add(icon);

        songName = new FlxText(0, 0, 0, songNameSt, 20);
		songName.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(selectShow.height * 0.3), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        songName.borderStyle = NONE;
		songName.antialiasing = ClientPrefs.data.antialiasing;
		songName.x += bg.height / 2 - icon.height / 2 + icon.width * 1.1;
		add(songName);

        musican = new FlxText(0, 0, 0, songMusican, 20);
		musican.setFormat(Paths.font(Language.get('fontName', 'main') + '.ttf'), Std.int(selectShow.height * 0.2), 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFFFFFFFF);
        musican.borderStyle = NONE;
		musican.antialiasing = ClientPrefs.data.antialiasing;
		musican.x += bg.height / 2 - icon.height / 2 + icon.width * 1.1;
		musican.y += songName.textField.textHeight;
		add(musican);

        selectLight = new Rect(0, 0, Std.int(selectShow.width + 50), Std.int(selectShow.height), fixHeight / 4, fixHeight / 4, 0xFFFFFF, 0);
        selectLight.antialiasing = ClientPrefs.data.antialiasing;
        selectLight.blend = ADD;
        selectLight.alpha = 0;
		add(selectLight);
    }

	/** Keep row identity stable while scrolling; hiding either label or icon
	 * produces a visible flash and makes the chart author appear to vanish. */
	public function setScrollRendering(scrolling:Bool):Void {
		if (icon != null && !icon.visible)
			icon.visible = true;
		if (musican != null && !musican.visible)
			musican.visible = true;
	}

    /**
     * Decodes and prepares a selected background without touching OpenFL
     * display objects. This function is safe to run on BackendThread because
     * every operation below owns its Lime pixel buffer; OpenFL's renderer
     * object pools are intentionally confined to the main thread.
     */
    public static function createBackgroundImages(file:String, viewportWidth:Int, viewportHeight:Int):{
        background:LimeImage,
        thumbnail:LimeImage
    } {
        try {
            if (!FileSystem.exists(file))
                return null;

            var source:LimeImage = LimeImage.fromFile(file);
            if (source == null || source.width <= 0 || source.height <= 0)
                return null;

            // Take ownership of the decoded buffer and shrink it before making
            // any copies. This keeps even an 8K mod background from being cloned
            // at full resolution.
            var resizedBackground:LimeImage = coverBackgroundImage(
                source, viewportWidth, viewportHeight);
            if (resizedBackground == null)
                return null;

            // Song rows intentionally use a centered cover crop. Their aspect
            // ratio is much wider than the source, so displaying the whole image
            // here would squash it instead of filling the available card area.
            var thumbnail:LimeImage = coverBackgroundImage(
                resizedBackground.clone(), fixWidth, fixHeight);

            var backgroundWidth:Int = Std.int(Math.max(1, viewportWidth / 4));
            var backgroundHeight:Int = Std.int(Math.max(1, viewportHeight / 4));
            resizedBackground.resize(backgroundWidth, backgroundHeight);

            // This is the same Lime blur implementation used by OpenFL's
            // BlurFilter, but it runs directly on private Lime images instead
            // of sharing BitmapData/Matrix pools with the renderer.
            var blurredBackground:LimeImage = new LimeImage(
                null, 0, 0, backgroundWidth, backgroundHeight, 0x00000000);
            ImageDataUtil.gaussianBlur(
                blurredBackground,
                resizedBackground,
                new LimeRectangle(0, 0, backgroundWidth, backgroundHeight),
                new Vector2(),
                6,
                6,
                2);

            return {
                background: blurredBackground,
                thumbnail: thumbnail
            };
        } catch (e:Dynamic) {
            trace('FREEPLAY BG: failed to prepare $file because $e');
            return null;
        }
    }

    static function coverBackgroundImage(source:LimeImage, width:Int, height:Int):LimeImage {
        if (source == null || source.width <= 0 || source.height <= 0 || width <= 0 || height <= 0)
            return null;

        var scale:Float = Math.max(width / source.width, height / source.height);
        var scaledWidth:Int = Std.int(Math.ceil(source.width * scale));
        var scaledHeight:Int = Std.int(Math.ceil(source.height * scale));
        source.resize(scaledWidth, scaledHeight);

        if (scaledWidth == width && scaledHeight == height)
            return source;

        var result:LimeImage = new LimeImage(null, 0, 0, width, height, 0x00000000);
        result.copyPixels(
            source,
            new LimeRectangle(
                Std.int((scaledWidth - width) * 0.5),
                Std.int((scaledHeight - height) * 0.5),
                width,
                height),
            new Vector2());
        return result;
    }

    public function applyThumbnailGraphic(graphic:FlxGraphic):Void {
        if (graphic == null || graphic.imageFrame == null)
            return;
        bg.frames = graphic.imageFrame;
        bg.setGraphicSize(fixWidth, fixHeight);
        bg.updateHitbox();
        bg.color = bgPath != null && bgPath.indexOf('menuDesat') != -1 ? _songColor : FlxColor.WHITE;
    }

    public var onFocus(default, set):Bool = true; //是当前这个歌曲被选择
    override function update(elapsed:Float)
	{
        if (FreeplayState.curSelected != this.id) onFocus = false;
        else {
            if (diffAdded) {
                if (FreeplayState.curDifficulty == -1) onFocus = true;
                else onFocus = false;
            } else {
                onFocus = true;
            }
        }

        selectLight.alpha -= elapsed;

        if (FlxG.mouse.y < FlxG.height - 65 && FlxG.mouse.y > 70 && !FreeplayState.instance.stopAll && searchMatch) {
            var mouse = FreeplayState.instance.mouseEvent;

            if (mouse.overlaps(this.black)) {
                if (FreeplayState.curSelected != this.id) selectLight.alpha = 0.1;
                if (mouse.justReleased) {
                    changeSelectAll();
                }
            }
        }
        
        if (onFocus) selectLight.alpha = 0.1;

        super.update(elapsed);

        if (destroyDiffRequested) {
            destroyDiffRequested = false;
            destroyDiff();
        }

        if (light.alpha > 0) {
            light.alpha -= elapsed / (Conductor.crochet * 2 / 1000);
        }
	}

    public function beatHit() {
        light.alpha = 1;
        if (diffRectGroup.members[FreeplayState.curDifficulty] != null) {
            var diffRect = cast(diffRectGroup.members[FreeplayState.curDifficulty], DiffRect);
            diffRect.beatHit();
        }
    }

    public function changeSelectAll(imme:Bool = false) {
        openRect = this;
        var requestId:Int = ++openRectRequestId;
        selectLight.alpha = 0.6;
	    FreeplayState.curSelected = this.id;
        FreeplayState.instance.changeSelection();

        Difficulty.loadFromWeek();
        FreeplayState.curDifficulty = 0;

        FlxTimer.wait(0.001, () -> {
            if (exists && FreeplayState.instance != null && openRect == this
                && requestId == openRectRequestId)
                createDiff(imme);
        });
        FreeplayState.instance.songsMove.tweenData = FlxG.height * 0.5 - SongRect.fixHeight * 0.5 - FreeplayState.instance.getEffectiveId(FreeplayState.curSelected) * SongRect.fixHeight * FreeplayState.instance.rectInter - (FreeplayState.curDifficulty+1) * DiffRect.fixHeight * 1.05;
        FreeplayState.instance.initSongsData();
    }
	
    //////////////////////////////////////////////////////////////////////////////////////////////

    private function set_onFocus(value:Bool):Bool
	{
		if (onFocus == value)
			return onFocus;
		onFocus = value;
		return value;
	}

    //////////////////////////////////////////////////////////////////////////////////////////////

    public var diffAdded:Bool = false;
    public function createDiff(imme:Bool = false) {
        if (diffAdded) return;

        for (mem in FreeplayState.instance.songGroup) {
            if (mem.id >= openRect.id) mem.addInterY(fixHeight * 0.1, imme);
            else mem.addInterY(0, imme);
            if (mem.id > openRect.id) mem.addDiffY(true, imme);
            else mem.addDiffY(false, imme);
            if (mem != openRect) mem.signDesDiff();
            mem.diffAdded = false;
        }

        if (diffRectGroup.members.length != Difficulty.list.length) {
            if (diffRectGroup.members.length != 0) {
                destroyDiff();
            }
            for (diff in 0...Difficulty.list.length)
            {
                var chart:String = _songCharter[diff];
                if (_songCharter[diff] == null)
                    chart = _songCharter[0];
                var rect = new DiffRect(this, Difficulty.list[diff], _songColor, chart);
                diffRectGroup.add(rect);
                rect.id = diff;
                rect.startTarY = bg.height + fixHeight / 10 + diff * DiffRect.fixHeight * 1.05;
                if (imme) {
                    rect.startY = rect.startTarY;
                    rect.allowSelect = true;
                } else {
                    FlxTimer.wait(0.1, () -> {
                        if (rect != null && rect.exists && !rect.allowDestroy)
                            rect.allowSelect = true;
                    });
                }
            }
            diffFouceUpdate();
        } else {
            for (member in diffRectGroup.members)
            {
                var rect = cast(member, DiffRect);
                rect.allowDestroy = false;
                FlxTimer.wait(0.1, () -> {
                    if (rect != null && rect.exists && !rect.allowDestroy)
                        rect.allowSelect = true;
                });
                rect.startTarY = bg.height + fixHeight / 10 + rect.id * DiffRect.fixHeight * 1.05;
            }
            diffFouceUpdate();
        }

        diffAdded = true;
        FlxTimer.wait(0.001, () -> {
            if (exists && FreeplayState.instance != null && openRect == this)
                FreeplayState.instance.updateSongLayerOrder();
        });
    }
    
    private function signDesDiff() {
        if (!diffAdded) return;
        if (diffRectGroup.members.length > 0) {
            for (member in diffRectGroup.members)
            {
                if (member == null)
                    continue;
                var diffRect = cast(member, DiffRect);
                if (diffRect == null) continue;
                diffRect.startTarY = 0;
                diffRect.allowDestroy = true;
                diffRect.allowSelect = false;
                diffRect.onFocus = false;
            }
        }
    }

    public function requestDestroyDiff():Void {
        destroyDiffRequested = true;
    }

    public function destroyDiff() {
        destroyDiffRequested = false;
        // remove(..., true) splices the live group array. Iterate a snapshot so
        // every difficulty is removed instead of skipping every second member.
        var members = diffRectGroup.members.copy();
        for (member in members)
        {
            if (member == null)
                continue;
            diffRectGroup.remove(member, true);
            member.destroy();
        }
    }

    public function diffFouceUpdate() {
        if (diffRectGroup.members.length > 0) {
            for (diff in diffRectGroup.members) {
                var diffRect = cast(diff, DiffRect);
                if (diffRect == null) continue;
                diffRect.onFocus = diffRect.id == FreeplayState.curDifficulty;
            }
        }
        FreeplayState.instance.initSongsData();
    }

    //////////////////////////////////////////////////////////////////////////////////////////////

    public var realX:Float = 0;
    
    public var moveX:Float = 0;
    public var chooseX:Float = 0;
    public var diffX:Float = 0;
    public function calcX() {
        moveX = Math.pow(Math.abs(realY + this.selectShow.height / 2 - FlxG.height / 2) / (FlxG.height / 2) * 10, 1.8);

        var chooseTar = onFocus ? -20 : 0;
        if (Math.abs(chooseX - chooseTar) > 1) chooseX = FlxMath.lerp(chooseTar, chooseX, Math.exp(-FreeplayState.instance.songsMove.saveElapsed * FreeplayState.instance.songsMove.lerpSmooth));
        else chooseX = chooseTar;

        var diffTar = diffAdded ? -50 : 0;
        if (Math.abs(diffX - diffTar) > 1) diffX = FlxMath.lerp(diffTar, diffX, Math.exp(-FreeplayState.instance.songsMove.saveElapsed * FreeplayState.instance.songsMove.lerpSmooth));
        else diffX = diffTar;

        var searchTar = searchMatch ? 0 : FlxG.width;
        if (Math.abs(searchOffset - searchTar) > 1) searchOffset = FlxMath.lerp(searchTar, searchOffset, Math.exp(-FreeplayState.instance.songsMove.saveElapsed * FreeplayState.instance.songsMove.lerpSmooth));
        else searchOffset = searchTar;
        
        realX = FlxG.width - this.selectShow.width + 80 + moveX + chooseX + diffX + searchOffset;
        diffCalcX();
    }

    private function diffCalcX() {
        if (diffRectGroup.members.length > 0) {
            for (diff in diffRectGroup.members) {
                var diffRect = cast(diff, DiffRect);
                if (diffRect == null) continue;
                diffRect.calcX();
            }
        }
    }

    public var realY:Float = 0;

    public var interY:Float = 0;
    public var diffY:Float = 0;    
    public function moveY(startY:Float) {        
        if (Math.abs(interY - interYTar) > 0.01)
            interY = FlxMath.lerp(interYTar, interY, Math.exp(-FreeplayState.instance.songsMove.saveElapsed * FreeplayState.instance.songsMove.lerpSmooth));
        else 
            interY = interYTar;
        
        if (Math.abs(diffY - diffYTar) > 0.01)
            diffY = FlxMath.lerp(diffYTar, diffY, Math.exp(-FreeplayState.instance.songsMove.saveElapsed * FreeplayState.instance.songsMove.lerpSmooth));
        else 
            diffY = diffYTar;

        realY = startY + interY + diffY;
        diffCalcY();
    }

    private function diffCalcY() {
        if (diffRectGroup.members.length > 0) {
            for (diff in diffRectGroup.members) {
                var diffRect = cast(diff, DiffRect);
                if (diffRect == null) continue;
                diffRect.calcY();
            }
        }
    }
    
    private var interYTar:Float = 0;
    public function addInterY(target:Float, imme:Bool = false) {
        interYTar = target;
        if (imme) interY = target;
    }
    
    private var diffYTar:Float = 0;
    public function addDiffY(isAdd:Bool = true, imme:Bool = false) {
        diffYTar = isAdd ? fixHeight / 10 * 2 + Difficulty.list.length * DiffRect.fixHeight * 1.05 : 0;
        if (imme) diffY = diffYTar;
    }

    override function draw() {
        this.x = realX;
        this.y = realY;
        super.draw();
    }
}
