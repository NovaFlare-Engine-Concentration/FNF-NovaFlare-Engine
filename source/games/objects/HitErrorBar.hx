package games.objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxTween;
//import backend.ClientPrefs;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
//import backend.Paths;
//import backend.Language;

class HitErrorBar extends FlxSpriteGroup
{
    public var timingBar:FlxSprite;
    public var pointer:FlxSprite;
    public var middleLine:FlxSprite;
    public var hitBars:FlxTypedSpriteGroup<FlxSprite>;
    
    // 打击note竖线相关
    public var hitNotes:FlxTypedSpriteGroup<FlxSprite>;
    var hitNoteTimers:Array<Float> = [];
    var maxHitNotes:Int = ClientPrefs.data.hitBarLines;
    var hitNoteDuration:Float = ClientPrefs.data.hitBarLineTime;
    
    // 新增：ms显示文本（独立对象，每次生成新的，旧的立即销毁）
    var currentMsText:FlxText = null;
    
    var currentMS:Float = 0;
    var targetMS:Float = 0;
    var maxTiming:Float = 0;
    
    var returnTimer:Float = 0;
    var shouldReturn:Bool = false;
    var returning:Bool = false;
    
    var barWidth:Float = 300;
    var barHeight:Float = 5;
    
    var ratingColors:Map<String, FlxColor> = [
        'marvelous' => FlxColor.fromRGB(255, 215, 0),
        'sick'      => FlxColor.fromRGB(135, 206, 235),
        'good'      => FlxColor.fromRGB(0, 255, 0),
        'bad'       => FlxColor.fromRGB(255, 0, 0),
        'shit'      => FlxColor.fromRGB(139, 0, 0)
    ];
    
    public function new()
    {
        super();
        
        var marvWindow = ClientPrefs.data.marvelousWindow;
        var sickWindow = ClientPrefs.data.sickWindow;
        var goodWindow = ClientPrefs.data.goodWindow;
        var badWindow = ClientPrefs.data.badWindow;
        maxTiming = 166;
        
        createTimingBar(marvWindow, sickWindow, goodWindow, badWindow);
        createPointer();
        createMiddleLine();
        createHitBars();
        createHitNotes();
        
        this.alpha = 0.7;
        
        screenCenter();
        y = FlxG.height * 0.6;
    }
    
    public function setHitNoteConfig(maxNotes:Int = 5, duration:Float = 2.0)
    {
        maxHitNotes = maxNotes;
        hitNoteDuration = duration;
        
        if (hitNotes != null && hitNotes.length > maxHitNotes)
        {
            for (i in maxHitNotes...hitNotes.members.length)
            {
                var note = hitNotes.members[i];
                if (note != null)
                {
                    note.kill();
                    note.destroy();
                }
            }
            while (hitNotes.members.length > maxHitNotes)
                hitNotes.members.pop();
            while (hitNoteTimers.length > maxHitNotes)
                hitNoteTimers.pop();
        }
    }
    
    function createTimingBar(marvWindow:Float, sickWindow:Float, goodWindow:Float, badWindow:Float)
    {
        var totalWidth = barWidth;
        var bitmapData = new BitmapData(Std.int(totalWidth), Std.int(barHeight), true);
        var centerX = totalWidth / 2;
        var pixelsPerMs = centerX / maxTiming;
        
        var currentX = 0.0;
        var shitWidth = (166 - badWindow) * pixelsPerMs;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, shitWidth, barHeight), ratingColors['shit']);
        currentX += shitWidth;
        
        var badWidth = (badWindow - goodWindow) * pixelsPerMs;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, badWidth, barHeight), ratingColors['bad']);
        currentX += badWidth;
        
        var goodWidth = (goodWindow - sickWindow) * pixelsPerMs;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, goodWidth, barHeight), ratingColors['good']);
        currentX += goodWidth;
        
        var sickWidth = (sickWindow - marvWindow) * pixelsPerMs;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, sickWidth, barHeight), ratingColors['sick']);
        currentX += sickWidth;
        
        var marvWidth = marvWindow * pixelsPerMs;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, marvWidth, barHeight), ratingColors['marvelous']);
        
        currentX = centerX;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, marvWidth, barHeight), ratingColors['marvelous']);
        currentX += marvWidth;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, sickWidth, barHeight), ratingColors['sick']);
        currentX += sickWidth;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, goodWidth, barHeight), ratingColors['good']);
        currentX += goodWidth;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, badWidth, barHeight), ratingColors['bad']);
        currentX += badWidth;
        bitmapData.fillRect(new openfl.geom.Rectangle(currentX, 0, shitWidth, barHeight), ratingColors['shit']);
        
        timingBar = new FlxSprite().loadGraphic(FlxGraphic.fromBitmapData(bitmapData));
        timingBar.updateHitbox();
        timingBar.x = FlxG.width / 2 - timingBar.width / 2;
        add(timingBar);
    }
    
    function createPointer()
    {
        pointer = new FlxSprite().makeGraphic(12, 16, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawPolygon(pointer, [
            FlxPoint.get(0, 16),
            FlxPoint.get(6, 0),
            FlxPoint.get(12, 16)
        ], FlxColor.WHITE);
        pointer.updateHitbox();
        pointer.x = timingBar.x + (timingBar.width / 2) - (pointer.width / 2);
        pointer.y = timingBar.y - pointer.height + 2;
        add(pointer);
    }
    
    function createMiddleLine()
    {
        middleLine = new FlxSprite().makeGraphic(2, 20, FlxColor.WHITE);
        middleLine.x = timingBar.x + (timingBar.width / 2) - 1;
        middleLine.y = timingBar.y - 10;
        add(middleLine);
    }
    
    function createHitBars()
    {
        hitBars = new FlxTypedSpriteGroup<FlxSprite>();
        for (i in 0...20)
        {
            var bar = new FlxSprite().makeGraphic(2, 14, FlxColor.WHITE);
            bar.visible = false;
            hitBars.add(bar);
        }
        add(hitBars);
    }
    
    function createHitNotes()
    {
        hitNotes = new FlxTypedSpriteGroup<FlxSprite>();
        hitNoteTimers = [];
        for (i in 0...maxHitNotes)
        {
            var noteLine = new FlxSprite().makeGraphic(2, 24, FlxColor.WHITE);
            noteLine.visible = false;
            noteLine.active = false;
            noteLine.alpha = 0;
            hitNotes.add(noteLine);
            hitNoteTimers.push(0);
        }
        add(hitNotes);
    }
    
    // 新增：显示ms文本（参考提供的代码风格）
    function showMsText(ms:Float, xPos:Float, ratingName:String)
    {
        // 如果设置了隐藏HUD或不显示ms，则直接返回
        return;
        
        // 立即销毁旧的msText（如果有）
        if (currentMsText != null)
        {
            FlxTween.cancelTweensOf(currentMsText);
            if (this.members.contains(currentMsText))
            {
                this.remove(currentMsText);
            }
            currentMsText.destroy();
            currentMsText = null;
        }
        
        // 创建新的msText
        currentMsText = new FlxText(0, 0, 0, "", 16);
        
        // 设置字体
        currentMsText.setFormat(Paths.font('pixel-latin.ttf'), 16, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

        
        // 设置文本内容
        var msTiming:Float = Math.round(Math.abs(ms) * 100) / 100;
        var sign:String = ms >= 0 ? "-" : "+";
        currentMsText.text = sign + msTiming + 'ms';
        
        // 根据判定设置颜色
        //if (ClientPrefs.data.customColor)
        //{
            switch(ratingName.toLowerCase())
            {
                case 'sick': currentMsText.color = ratingColors['sick'];
                case 'good': currentMsText.color = ratingColors['good'];
                case 'bad': currentMsText.color = ratingColors['bad'];
                case 'shit': currentMsText.color = ratingColors['shit'];
                default: currentMsText.color = FlxColor.WHITE;
            }
        //}
        
        // 设置位置（在竖线上方）
        currentMsText.screenCenter(X);
        currentMsText.y += 5;
        
        // 添加到组
        add(currentMsText);
        
        // 淡出动画（0.5秒后完全透明并销毁）
        FlxTween.tween(currentMsText, {alpha: 0}, 0.2 / games.PlayState.instance.playbackRate, {
            ease: FlxEase.quadOut,
            onComplete: function(tween:FlxTween) {
                if (currentMsText != null && this.members.contains(currentMsText))
                {
                    this.remove(currentMsText);
                    currentMsText.destroy();
                    currentMsText = null;
                }
            },
            startDelay: Conductor.crochet * 0.004 / games.PlayState.instance.playbackRate
        });
    }
    
    // 获取判定名称
    function getRatingName(ms:Float):String
    {
        var absMs = Math.abs(ms);
        if (absMs <= ClientPrefs.data.marvelousWindow)
            return 'marvelous';
        else if (absMs <= ClientPrefs.data.sickWindow)
            return 'sick';
        else if (absMs <= ClientPrefs.data.goodWindow)
            return 'good';
        else if (absMs <= ClientPrefs.data.badWindow)
            return 'bad';
        else
            return 'shit';
    }
    
    public function addHitNote(ms:Float, noteDirection:Int = 0)
    {
        var centerX = timingBar.x + (timingBar.width / 2);
        var halfBar = timingBar.width / 2;
        var percent = ms / maxTiming;
        percent = FlxMath.bound(percent, -1, 1);
        var xPos = centerX + (percent * halfBar);
        
        var absMs = Math.abs(ms);
        var color:FlxColor;
        var ratingName = getRatingName(ms);
        
        if (absMs <= ClientPrefs.data.marvelousWindow)
            color = ratingColors['marvelous'];
        else if (absMs <= ClientPrefs.data.sickWindow)
            color = ratingColors['sick'];
        else if (absMs <= ClientPrefs.data.goodWindow)
            color = ratingColors['good'];
        else if (absMs <= ClientPrefs.data.badWindow)
            color = ratingColors['bad'];
        else
            color = ratingColors['shit'];
        
        if (noteDirection != 0)
        {
            if (noteDirection < 0)
                color = color.getLightened(0.2);
            else if (noteDirection > 0)
            {
                var rgb = color.to24Bit();
                var r = (rgb >> 16) & 0xFF;
                var g = (rgb >> 8) & 0xFF;
                var b = rgb & 0xFF;
                r = Std.int(Math.min(255, r * 1.2));
                color = FlxColor.fromRGB(r, g, b);
            }
        }
        
        var foundSlot = false;
        for (i in 0...maxHitNotes)
        {
            if (hitNoteTimers[i] <= 0)
            {
                var noteLine = hitNotes.members[i];
                if (noteLine != null)
                {
                    noteLine.setPosition(xPos - noteLine.width / 2, timingBar.y - 15);
                    noteLine.color = color;
                    noteLine.alpha = 0.9;
                    noteLine.visible = true;
                    noteLine.active = true;
                    hitNoteTimers[i] = hitNoteDuration;
                    foundSlot = true;
                    break;
                }
            }
        }
        
        if (!foundSlot)
        {
            var oldestIndex = 0;
            var oldestTime = hitNoteTimers[0];
            for (i in 1...maxHitNotes)
            {
                if (hitNoteTimers[i] < oldestTime)
                {
                    oldestTime = hitNoteTimers[i];
                    oldestIndex = i;
                }
            }
            var noteLine = hitNotes.members[oldestIndex];
            if (noteLine != null)
            {
                noteLine.setPosition(xPos - noteLine.width / 2, timingBar.y - 15);
                noteLine.color = color;
                noteLine.alpha = 0.9;
                noteLine.visible = true;
                noteLine.active = true;
                hitNoteTimers[oldestIndex] = hitNoteDuration;
            }
        }
        
        // 显示ms文本（新的会立即销毁旧的）
        showMsText(ms, xPos, ratingName);
        
        this.alpha = 0.9;
    }
    
    public function clearHitNotes()
    {
        for (i in 0...maxHitNotes)
        {
            var noteLine = hitNotes.members[i];
            if (noteLine != null)
            {
                noteLine.visible = false;
                noteLine.active = false;
                noteLine.alpha = 0;
            }
            hitNoteTimers[i] = 0;
        }
        
        // 清除ms文本
        if (currentMsText != null)
        {
            FlxTween.cancelTweensOf(currentMsText);
            if (this.members.contains(currentMsText))
            {
                this.remove(currentMsText);
            }
            currentMsText.destroy();
            currentMsText = null;
        }
    }
    
    public function registerHit(ms:Float, noteDirection:Int = 0)
    {
        currentMS = ms;
        targetMS = ms;
        returnTimer = 2.0;
        shouldReturn = false;
        returning = false;
        addHitMarker(ms);
        addHitNote(ms, noteDirection);
        updatePointerColor();
        this.alpha = 0.9;
    }
    
    function calculatePointerX(ms:Float):Float
    {
        var centerX = timingBar.x + (timingBar.width / 2);
        if (ms == 0) return centerX - (pointer.width / 2);
        var percent = ms / maxTiming;
        percent = FlxMath.bound(percent, -1, 1);
        var halfBar = timingBar.width / 2;
        return centerX + (percent * halfBar) - (pointer.width / 2);
    }
    
    function updatePointerColor()
    {
        var absMs = Math.abs(currentMS);
        if (absMs <= ClientPrefs.data.marvelousWindow)
            pointer.color = ratingColors['marvelous'];
        else if (absMs <= ClientPrefs.data.sickWindow)
            pointer.color = ratingColors['sick'];
        else if (absMs <= ClientPrefs.data.goodWindow)
            pointer.color = ratingColors['good'];
        else if (absMs <= ClientPrefs.data.badWindow)
            pointer.color = ratingColors['bad'];
        else
            pointer.color = ratingColors['shit'];
    }
    
    function addHitMarker(ms:Float)
    {
        var bar = hitBars.recycle();
        if (bar == null) return;
        var centerX = timingBar.x + (timingBar.width / 2);
        var halfBar = timingBar.width / 2;
        var percent = ms / maxTiming;
        percent = FlxMath.bound(percent, -1, 1);
        var xPos = centerX + (percent * halfBar) - (bar.width / 2);
        bar.setPosition(xPos, timingBar.y - 12);
        var absMs = Math.abs(ms);
        var color:FlxColor;
        if (absMs <= ClientPrefs.data.marvelousWindow)
            color = ratingColors['marvelous'];
        else if (absMs <= ClientPrefs.data.sickWindow)
            color = ratingColors['sick'];
        else if (absMs <= ClientPrefs.data.goodWindow)
            color = ratingColors['good'];
        else if (absMs <= ClientPrefs.data.badWindow)
            color = ratingColors['bad'];
        else
            color = ratingColors['shit'];
        bar.color = color;
        bar.alpha = 0.8;
        bar.visible = true;
        FlxTween.tween(bar, {alpha: 0}, 1, {
            onComplete: function(twn:FlxTween) {
                bar.visible = false;
                bar.kill();
            }
        });
    }
    
    public function registerMiss(noteDirection:Int = 0)
    {
        var bar = hitBars.recycle();
        if (bar == null) return;
        var centerX = timingBar.x + (timingBar.width / 2);
        var halfBar = timingBar.width / 2;
        var xPos = centerX + halfBar - (bar.width / 2);
        bar.setPosition(xPos, timingBar.y - 12);
        bar.color = FlxColor.GRAY;
        bar.alpha = 0.8;
        bar.visible = true;
        FlxTween.tween(bar, {alpha: 0}, 1, {
            onComplete: function(twn:FlxTween) {
                bar.visible = false;
                bar.kill();
            }
        });
        addHitNote(maxTiming, noteDirection);
        this.alpha = 0.9;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (targetMS != 0 && !returning)
        {
            returnTimer -= elapsed;
            if (returnTimer <= 0)
            {
                shouldReturn = true;
                returning = true;
            }
        }
        
        if (shouldReturn && returning)
        {
            targetMS = FlxMath.lerp(targetMS, 0, 0.1);
            currentMS = targetMS;
            if (Math.abs(targetMS) < 0.5)
            {
                targetMS = 0;
                currentMS = 0;
                shouldReturn = false;
                returning = false;
            }
            updatePointerColor();
        }
        
        var targetX = calculatePointerX(targetMS);
        pointer.x = FlxMath.lerp(pointer.x, targetX, 0.3);
        
        for (i in 0...maxHitNotes)
        {
            if (hitNoteTimers[i] > 0)
            {
                hitNoteTimers[i] -= elapsed;
                var noteLine = hitNotes.members[i];
                if (noteLine != null && noteLine.visible)
                {
                    if (hitNoteTimers[i] < 0.5)
                        noteLine.alpha = FlxMath.lerp(0, 0.9, hitNoteTimers[i] / 0.5);
                    if (hitNoteTimers[i] <= 0)
                    {
                        noteLine.visible = false;
                        noteLine.active = false;
                        noteLine.alpha = 0;
                        hitNoteTimers[i] = 0;
                    }
                }
            }
        }
        
        if (alpha > 0.5)
            alpha -= 0.3 * elapsed;
    }
    
    public function resetAll()
    {
        currentMS = 0;
        targetMS = 0;
        returnTimer = 0;
        shouldReturn = false;
        returning = false;
        pointer.x = timingBar.x + (timingBar.width / 2) - (pointer.width / 2);
        pointer.color = FlxColor.WHITE;
        for (bar in hitBars)
        {
            bar.visible = false;
            bar.kill();
        }
        clearHitNotes();
        this.alpha = 0.7;
    }
}