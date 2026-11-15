package general.objects.screen;

import haxe.Timer;

import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.Lib;
import openfl.geom.ColorTransform;

class MouseEffect extends Sprite {
    // 点击特效配置
    public static var clickImagePath:String = 'images/menuExtend/Others/click.png';
    public static var circleImagePath:String = 'images/menuExtend/Others/circle.png';
    
    // 第一个点击贴图(click)配置
    public static var clickStartAlpha:Float = 0.7;
    public static var clickEndAlpha:Float = 0.0;
    public static var clickStartScale:Float = 0.7;
    public static var clickEndScale:Float = 0.2;
    public static var clickDuration:Float = 0.3; // 秒
    public static var clickColor:Int = EngineSet.minorColor;
    
    // 第二个点击贴图(circle)配置
    public static var circleStartAlpha:Float = 1;
    public static var circleEndAlpha:Float = 0.0;
    public static var circleStartScale:Float = 0.2;
    public static var circleEndScale:Float = 1.0;
    public static var circleDuration:Float = 0.3; // 秒
    public static var circleColor:Int = EngineSet.mainColor;
    
    // 路径特效配置
    public static var trailImagePath:String = 'images/menuExtend/Others/star.png';
    public static var trailMinDistance:Float = 40; // 生成新贴图的最小移动距离
    public static var trailStartAlpha:Float = 0.8;
    public static var trailEndAlpha:Float = 0.0;
    public static var trailStartScale:Float = 0.4;
    public static var trailEndScale:Float = 0.2;
    public static var trailMaxCount:Int = 50; // 最大路径贴图数量
    public static var trailMinRotation:Float = -30; // 最小旋转角度
    public static var trailMaxRotation:Float = 30; // 最大旋转角度
    public static var trailColors:Array<Int> =  [
    0xFFCCCB, // 低饱和红 (略带粉调)
    0xCBFFC9, // 低饱和绿 (略带薄荷调)
    0xC9E2FF, // 低饱和蓝 (略带天蓝调)
    0xFFF4C2, // 低饱和黄 (奶油黄)
    0xE8CBFF, // 低饱和紫 (淡薰衣草)
    0xFFD8B1, // 低饱和橙 (淡桃橙)
    0xB5EAD7, // 低饱和青 (淡薄荷青)
    0xFFC3A0, // 低饱和珊瑚 (淡粉橙)
    0xD4A5A5, // 低饱和棕红 (灰粉调)
    0xA5D4FF  // 低饱和天蓝 (柔和蓝)
    ];
    public static var trailDuration:Float = 0.3; // 路径贴图动画持续时间(秒)
    // Freeplay can suppress only the movement trail while retaining click
    // feedback. Gameplay uses a separate suppression layer that hides both
    // kinds of pointer feedback without changing the saved user preference.
    public static var trailEnabled:Bool = true;
    public static var userEffectsEnabled(default, null):Bool = true;
    public static var userTrailEnabled(get, never):Bool;
    private static var gameplayHideDepth:Int = 0;
    private static var editorHideDepth:Int = 0;
    private static var instances:Array<MouseEffect> = [];
    
    // 对象池
    private var clickEffects:Array<ClickEffect> = [];
    private var trailEffects:Array<TrailEffect> = [];
    private var activeClickEffects:Array<ClickEffect> = [];
    private var activeTrailEffects:Array<TrailEffect> = [];
    private var updating:Bool = false;
	private var lastEffectUpdate:Float = 0;
	private static inline var EFFECT_UPDATE_INTERVAL:Float = 1 / 120;
    private var clickBitmapData:BitmapData;
    private var circleBitmapData:BitmapData;
    private var trailBitmapData:BitmapData;
    
    // 路径记录
    private var lastTrailPosition:Point = new Point();
    private var hasTrailPosition:Bool = false;

    public function new(?clickBitmapData:BitmapData, ?circleBitmapData:BitmapData, ?trailBitmapData:BitmapData) {
        super();

        // 预加载资源
        this.clickBitmapData = clickBitmapData ?? BitmapData.fromFile(Paths.modFolders(clickImagePath));
        this.circleBitmapData = circleBitmapData ?? BitmapData.fromFile(Paths.modFolders(circleImagePath));
        this.trailBitmapData = trailBitmapData ?? BitmapData.fromFile(Paths.modFolders(trailImagePath));

        // 初始化对象池
        for (i in 0...10) {
            clickEffects.push(new ClickEffect(this.clickBitmapData, this.circleBitmapData));
        }
        
        for (i in 0...trailMaxCount) {
            trailEffects.push(new TrailEffect(this.trailBitmapData));
        }

        // 添加事件监听
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        Lib.current.stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		instances.push(this);
    }

    private inline function startUpdating():Void {
        if (!updating) {
            updating = true;
			lastEffectUpdate = Timer.stamp();
			Lib.current.stage.addEventListener(Event.ENTER_FRAME, update);
        }
    }

    private function onMouseDown(e:MouseEvent):Void {
        if (!effectsEnabled()) return;

        // 从对象池获取点击特效
        var effect:ClickEffect = null;
        if (clickEffects.length > 0) {
            effect = clickEffects.pop();
        } else {
            // 如果对象池空了，创建一个新的
            effect = new ClickEffect(clickBitmapData, circleBitmapData);
        }
        
        // 初始化特效
        var position = globalToLocal(new Point(e.stageX, e.stageY));
        effect.init(position.x, position.y);
        activeClickEffects.push(effect);
        addChild(effect);
        startUpdating();
    }
    
    private function onMouseMove(e:MouseEvent):Void {
        var position = globalToLocal(new Point(e.stageX, e.stageY));
        if (!trailEnabled || !effectsEnabled()) {
            // Keep the anchor current so re-enabling the effect in another
            // state never emits a stale, long-distance trail point.
            lastTrailPosition.copyFrom(position);
            hasTrailPosition = false;
            return;
        }

        if (!hasTrailPosition) {
            lastTrailPosition.copyFrom(position);
            hasTrailPosition = true;
            return;
        }

        // 检查移动距离是否足够
        var deltaX = position.x - lastTrailPosition.x;
        var deltaY = position.y - lastTrailPosition.y;
        if (deltaX * deltaX + deltaY * deltaY <
            trailMinDistance * trailMinDistance) return;
        
        lastTrailPosition.copyFrom(position);
        
        // 从对象池获取路径特效
        var effect:TrailEffect = null;
        if (trailEffects.length > 0) {
            effect = trailEffects.pop();
        } else {
            // 如果对象池空了，移除最旧的特效
            if (activeTrailEffects.length > 0) {
                var oldEffect = activeTrailEffects.shift();
                removeEffect(oldEffect);
                trailEffects.push(oldEffect);
                effect = trailEffects.pop();
            } else {
                // 如果还是空的，创建一个新的
                effect = new TrailEffect(trailBitmapData);
            }
        }
        
        // 初始化特效
        var color = trailColors[FlxG.random.int(0, trailColors.length - 1)];
        var rotation = trailMinRotation + Math.random() * (trailMaxRotation - trailMinRotation);
        effect.init(position.x, position.y, color, rotation);
        activeTrailEffects.push(effect);
        addChild(effect);
        startUpdating();
    }

    private function onMouseLeave(_:Event):Void {
        hasTrailPosition = false;
    }

	private static inline function get_userTrailEnabled():Bool {
		return userEffectsEnabled;
	}

	private static inline function effectsEnabled():Bool {
		return userEffectsEnabled && gameplayHideDepth == 0 && editorHideDepth == 0;
	}

	public static function setUserEffectsEnabled(value:Bool):Void {
		if (userEffectsEnabled == value) return;

		userEffectsEnabled = value;
		if (!value) clearAllEffects();
	}

	// Compatibility for source/mod code that still calls the old trail-only API.
	public static inline function setUserTrailEnabled(value:Bool):Void {
		setUserEffectsEnabled(value);
	}

	public static function enterGameplay():Void {
		gameplayHideDepth++;
		clearAllEffects();
	}

	public static function leaveGameplay():Void {
		if (gameplayHideDepth > 0) gameplayHideDepth--;
	}

	/** Editors own their cursor; suppress only the NF overlay while they are active. */
	public static function enterEditor():Void {
		editorHideDepth++;
		clearAllEffects();
	}

	public static function leaveEditor():Void {
		if (editorHideDepth > 0) editorHideDepth--;
	}

	private static function clearAllEffects():Void {
		for (instance in instances)
			instance.clearEffects();
	}

	private function clearEffects():Void {
		hasTrailPosition = false;
		var i = activeClickEffects.length;
		while (i-- > 0) {
			var effect = activeClickEffects[i];
			activeClickEffects.splice(i, 1);
			removeEffect(effect);
			clickEffects.push(effect);
		}

		clearTrailEffects();
	}

	private function clearTrailEffects():Void {
		var i = activeTrailEffects.length;
		while (i-- > 0) {
			var effect = activeTrailEffects[i];
			activeTrailEffects.splice(i, 1);
			removeEffect(effect);
			trailEffects.push(effect);
		}

		if (activeClickEffects.length == 0 && activeTrailEffects.length == 0 && updating) {
			Lib.current.stage.removeEventListener(Event.ENTER_FRAME, update);
			updating = false;
		}
	}

	private function onRemovedFromStage(_:Event):Void {
		removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		Lib.current.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		Lib.current.stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave);
		if (updating) {
			Lib.current.stage.removeEventListener(Event.ENTER_FRAME, update);
			updating = false;
		}
		instances.remove(this);
	}
    
    private function update(e:Event):Void {
		var now:Float = Timer.stamp();
		if (now - lastEffectUpdate < EFFECT_UPDATE_INTERVAL) return;
		lastEffectUpdate = now;

        // 更新点击特效
        var i = activeClickEffects.length;
        while (i-- > 0) {
            var effect = activeClickEffects[i];
            effect.update();
            
            if (effect.isComplete) {
                activeClickEffects.splice(i, 1);
                removeEffect(effect);
                clickEffects.push(effect);
            }
        }
        
        // 更新路径特效
        i = activeTrailEffects.length;
        while (i-- > 0) {
            var effect = activeTrailEffects[i];
            effect.update();
            
            if (effect.isComplete) {
                activeTrailEffects.splice(i, 1);
                removeEffect(effect);
                trailEffects.push(effect);
            }
        }

        // With no live effect there is nothing to animate. Avoid dispatching
        // this listener on every one of the engine's high-rate update ticks.
        if (activeClickEffects.length == 0 && activeTrailEffects.length == 0) {
			Lib.current.stage.removeEventListener(Event.ENTER_FRAME, update);
            updating = false;
        }
    }
    
    private function removeEffect(effect:Sprite):Void {
        if (contains(effect)) {
            removeChild(effect);
        }
    }
}

// 点击特效类
class ClickEffect extends Sprite {
    public var isComplete:Bool = false;
    
    private var clickBitmap:Bitmap;
    private var circleBitmap:Bitmap;
    private var clickTimer:Float = 0;
    private var circleTimer:Float = 0;
    private var xPos:Float = 0;
    private var yPos:Float = 0;
    private var clickOffsetX:Float = 0;
    private var clickOffsetY:Float = 0;
    private var circleOffsetX:Float = 0;
    private var circleOffsetY:Float = 0;
    
    public function new(clickBitmapData:BitmapData, circleBitmapData:BitmapData) {
        super();
        
        clickBitmap = new Bitmap(clickBitmapData);
        circleBitmap = new Bitmap(circleBitmapData);
        
        // 计算中心点偏移量
        clickOffsetX = clickBitmap.width / 2;
        clickOffsetY = clickBitmap.height / 2;
        circleOffsetX = circleBitmap.width / 2;
        circleOffsetY = circleBitmap.height / 2;
        
        // 设置初始属性
        clickBitmap.alpha = MouseEffect.clickStartAlpha;
        clickBitmap.scaleX = clickBitmap.scaleY = MouseEffect.clickStartScale;
        clickBitmap.visible = false;
        
        circleBitmap.alpha = MouseEffect.circleStartAlpha;
        circleBitmap.scaleX = circleBitmap.scaleY = MouseEffect.circleStartScale;
        circleBitmap.visible = false;
        
        // 设置初始位置（会在init中更新）
        clickBitmap.x = -clickOffsetX;
        clickBitmap.y = -clickOffsetY;
        circleBitmap.x = -circleOffsetX;
        circleBitmap.y = -circleOffsetY;
        
        // 应用颜色
        applyColor(clickBitmap, MouseEffect.clickColor);
        applyColor(circleBitmap, MouseEffect.circleColor);
        
        addChild(circleBitmap);
        addChild(clickBitmap);
    }
    
    public function init(x:Float, y:Float):Void {
        isComplete = false;
        clickTimer = Timer.stamp();
        circleTimer = Timer.stamp();
        xPos = x;
        yPos = y;
        
        this.x = xPos;
        this.y = yPos;
        
        // 重置状态
        clickBitmap.alpha = MouseEffect.clickStartAlpha;
        clickBitmap.scaleX = clickBitmap.scaleY = MouseEffect.clickStartScale;
        clickBitmap.x = -clickOffsetX * MouseEffect.clickStartScale;
        clickBitmap.y = -clickOffsetY * MouseEffect.clickStartScale;
        clickBitmap.visible = true;
        
        circleBitmap.alpha = MouseEffect.circleStartAlpha;
        circleBitmap.scaleX = circleBitmap.scaleY = MouseEffect.circleStartScale;
        circleBitmap.x = -circleOffsetX * MouseEffect.circleStartScale;
        circleBitmap.y = -circleOffsetY * MouseEffect.circleStartScale;
        circleBitmap.visible = true;
    }
    
    public function update():Void {
        // 更新click动画
        var time = Timer.stamp() - clickTimer;

        if (time < MouseEffect.clickDuration) {
            var progress = time / MouseEffect.clickDuration;
            
            clickBitmap.alpha = MouseEffect.clickStartAlpha + (MouseEffect.clickEndAlpha - MouseEffect.clickStartAlpha) * progress;
            var scale = MouseEffect.clickStartScale + (MouseEffect.clickEndScale - MouseEffect.clickStartScale) * progress;
            clickBitmap.scaleX = clickBitmap.scaleY = scale;
            
            // 更新位置确保中心点不变
            clickBitmap.x = -clickOffsetX * scale;
            clickBitmap.y = -clickOffsetY * scale;
        } else if (clickBitmap.visible) {
            clickBitmap.visible = false;
        }
        
        // 更新circle动画
        var time = Timer.stamp() - circleTimer;

        if (time < MouseEffect.circleDuration) {
            var progress = time / MouseEffect.circleDuration;
            
            circleBitmap.alpha = MouseEffect.circleStartAlpha + (MouseEffect.circleEndAlpha - MouseEffect.circleStartAlpha) * progress;
            var scale = MouseEffect.circleStartScale + (MouseEffect.circleEndScale - MouseEffect.circleStartScale) * progress;
            circleBitmap.scaleX = circleBitmap.scaleY = scale;
            
            // 更新位置确保中心点不变
            circleBitmap.x = -circleOffsetX * scale;
            circleBitmap.y = -circleOffsetY * scale;
        } else if (circleBitmap.visible) {
            circleBitmap.visible = false;
        }

        if (!clickBitmap.visible && !circleBitmap.visible)
            isComplete = true;
    }
    
    private function applyColor(bitmap:Bitmap, color:Int):Void {
        var transform = bitmap.transform;
        var colorTransform = transform.colorTransform;
        colorTransform.color = color;
        bitmap.transform.colorTransform = colorTransform;
    }
}

// 路径特效类
class TrailEffect extends Sprite {
    public var isComplete:Bool = false;
    
    private var bitmap:Bitmap;
    private var timer:Float = 0;
    private var startScale:Float;
    private var endScale:Float;
    private var startAlpha:Float;
    private var endAlpha:Float;
    private var offsetX:Float = 0;
    private var offsetY:Float = 0;
    
    public function new(bitmapData:BitmapData) {
        super();
        
        bitmap = new Bitmap(bitmapData);
        offsetX = bitmap.width / 2;
        offsetY = bitmap.height / 2;
        bitmap.x = -offsetX;
        bitmap.y = -offsetY;
        addChild(bitmap);
    }
    
    public function init(x:Float, y:Float, color:Int, rotation:Float):Void {
        isComplete = false;
        timer = Timer.stamp();
        
        this.x = x;
        this.y = y;
        this.rotation = rotation;
        
        // 设置初始属性
        startScale = MouseEffect.trailStartScale;
        endScale = MouseEffect.trailEndScale;
        startAlpha = MouseEffect.trailStartAlpha;
        endAlpha = MouseEffect.trailEndAlpha;
        
        bitmap.scaleX = bitmap.scaleY = startScale;
        bitmap.alpha = startAlpha;
        bitmap.x = -offsetX * startScale;
        bitmap.y = -offsetY * startScale;
        
        // 应用颜色
        applyColor(bitmap, color);
    }
    
    public function update():Void {
        var time = Timer.stamp() - timer;
        
        if (time < MouseEffect.trailDuration) {
            var progress = time / MouseEffect.trailDuration;
            
            bitmap.alpha = startAlpha + (endAlpha - startAlpha) * progress;
            var scale = startScale + (endScale - startScale) * progress;
            bitmap.scaleX = bitmap.scaleY = scale;
            bitmap.x = -offsetX * scale;
            bitmap.y = -offsetY * scale;
        } else {
            isComplete = true;
        }
    }
    
    private function applyColor(bitmap:Bitmap, color:Int):Void {
        var transform = bitmap.transform;
        var colorTransform = transform.colorTransform;
        colorTransform.color = color;
        bitmap.transform.colorTransform = colorTransform;
    }
}
