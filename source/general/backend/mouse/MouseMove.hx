package general.backend.mouse;

import flixel.FlxBasic;

class MouseMove extends FlxBasic
{
    static inline final DRAG_VELOCITY_FALLBACK_MS = 8.0;
    static inline final DRAG_VELOCITY_SMOOTH_MS = 32.0;
    static inline final DRAG_RELEASE_HOLD_MS = 32.0;
    static inline final DRAG_STOP_MS = 90.0;

    public var allowUpdate:Bool = true;
    public var enableMouseWheel:Bool = true;
    
    public var follow:Dynamic; //数据跟谁
    public var followData:String; //数据变量的名称

    public var target:Float;
    public var moveLimit:Array<Float> = [0, 0];  //[min, max]
    public var mouseLimit:Array<Array<Float>> = [];   //[ X[min, max], Y[min, max] ]

    public var mouseWheelSensitivity:Float = 1000.0; // 鼠标滚轮更改量的控制变量
    public var tweenData(get, set):Float; //用于tween/lerp到指定数据的
    public var tweenTime:Float = 0.3; //tween时间
    public var tweenType:String = 'linear'; //tween类型
    public var useLerp:Bool = true; //是否使用lerp而不是tween
    public var lerpSmooth:Float = 15; //lerp平滑度

    public var forceUpdateEvent:Bool = true; //是否强制更新事件
    public var event:Void->Void = null;

    ////////////////////////////////////////////////////////////////////////////////////////////////

    public var infScroll:Bool = false; //是否为无限滚动
    
    private var isDragging:Bool = false;
    private var lastMouseY:Float = 0;
    public var velocity:Float = 0; //检测的时候需要它

    private var __target:Float;
    public var state:String = 'stop';
    
    // 物理参数
    private var dragSensitivity:Float = 1.0;   // 拖动灵敏度
    private var inertiaDecay:Float = -Math.log(0.9) * 60;
    private var minVelocity:Float = 0.001;       // 最小速度阈值
    private var springStrength:Float = 25.0;
    private var releaseBoost:Float = 1.1;

    public var saveElapsed:Float = 0; //保存上一次更新的时间
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    
    public function new(follow:Dynamic, followData:String, moveData:Array<Float>, mouseData:Array<Array<Float>>, putEvent:Void->Void = null, needUpdate:Bool = true) {
        super();
        this.allowUpdate = needUpdate;
        
        this.follow = follow;
        this.followData = followData;

        this.target = Reflect.getProperty(follow, followData); //好像确实没啥用，但是可以用来初始化数据 --狐月影
        if (moveData.length == 0) infScroll = true;
        else this.moveLimit = moveData;
        this.mouseLimit = mouseData;
        
        this.event = putEvent;
    }
    
    private var lastDragTick:Int = 0;
    private var lastMovementTick:Int = 0;
    public var inputAllow:Bool = true;
    private var allowLerp:Bool = false;
    private var requestedTarget:Float = 0;
    private var _pendingDragDelta:Float = 0;
    public var dragStartDelayMs:Int = 100;
    public var dragStartDistance:Float = 10;
    private var _dragPending:Bool = false;
    private var _dragPendingTick:Int = 0;
    private var _dragPendingY:Float = 0;
    override function update(elapsed:Float) {
        if (allowUpdate) {
            saveElapsed = elapsed;
            updateInput();
        } else {
            cancelDrag();
        }
        super.update(elapsed);
    }

    private function updateInput():Void {
        var mouse = FlxG.mouse;
        if (!inputAllow || mouse == null) {
            cancelDrag();
            return;
        }

        var now = FlxG.game.ticks;
        var mouseY = mouse.y;
        var inBounds = mouse.x > mouseLimit[0][0] && mouse.x < mouseLimit[0][1] && mouseY > mouseLimit[1][0] && mouseY < mouseLimit[1][1];
        if (mouse.justPressed) {
            cancelDrag();
            if (inBounds) {
                _dragPending = true;
                _dragPendingTick = now;
                _dragPendingY = mouseY;
            }
        }

        if (enableMouseWheel && inBounds && mouse.wheel != 0) {
            cancelDrag();
            velocity += mouse.wheel * mouseWheelSensitivity;
            cancelMoveTo();
            return;
        }

        if (_dragPending && (mouse.pressed || mouse.justReleased)) {
            var passedDistance = Math.abs(mouseY - _dragPendingY) >= dragStartDistance;
            var passedDelay = mouse.pressed && now - _dragPendingTick >= dragStartDelayMs;
            if (passedDistance || passedDelay) startDrag();
        }
        if (isDragging && (mouse.pressed || mouse.justReleased)) updateDrag(mouseY, now);
        if (mouse.justReleased) {
            _dragPending = false;
            endDrag(now);
        } else if (!mouse.pressed) {
            cancelDrag();
        }
    }

    override function drawUpdate(elapsed:Float) {
        super.drawUpdate(elapsed);
        if (!allowUpdate) return;

        saveElapsed = elapsed;

        if (_pendingDragDelta != 0) {
            target += _pendingDragDelta;
            _pendingDragDelta = 0;
        }

        if (!isDragging && Math.abs(velocity) > minVelocity) {
            applyInertia(elapsed);
        }

        if (allowLerp) {
            if (Math.abs(target - requestedTarget) < 0.1) {
                target = requestedTarget;
                cancelMoveTo();
            } else {
                target = FlxMath.lerp(requestedTarget, target, Math.exp(-elapsed * lerpSmooth));
            }
        }

        if(!infScroll) {
            if (target < moveLimit[0]) target = FlxMath.lerp(moveLimit[0], target, Math.exp(-elapsed * lerpSmooth * 2));
            if (target > moveLimit[1]) target = FlxMath.lerp(moveLimit[1], target, Math.exp(-elapsed * lerpSmooth * 2));
        }

        var previousState:String = state;
        var targetChanged:Bool = __target != target;
        if (__target > target) state = 'up';
        else if (__target < target) state = 'down';
        else state = 'stop';

        __target = target;

        // Reflection invokes a full dynamic setter path. Do it only when the
        // scroll value actually moved instead of on every draw callback.
        if (targetChanged)
            Reflect.setProperty(follow, followData, target);
        
        // Dispatch the one transition back to "stop" as well. Consumers use
        // it to restore full row detail after the lightweight drag rendering.
        if (event!= null && (state != 'stop' || previousState != state || forceUpdateEvent)) {
            event();
        }
    }
    
    private function startDrag():Void {
        _dragPending = false;
        isDragging = true;
        // The threshold confirms the gesture, so the first sample still starts at the press.
        lastMouseY = _dragPendingY;
        lastMovementTick = lastDragTick = _dragPendingTick;
        velocity = 0;
        cancelMoveTo();
    }

    private function updateDrag(currentY:Float, now:Int):Void {
        var distance = (currentY - lastMouseY) * dragSensitivity;
        var inputInterval = now - lastDragTick;
        var movementInterval = now - lastMovementTick;
        lastMouseY = currentY;
        lastDragTick = now;
        if (distance == 0) {
            if (movementInterval >= DRAG_STOP_MS) velocity = 0;
            return;
        }

        _pendingDragDelta += distance;
        // Input coordinates can update less often than the game polls them.
        var sampleMs:Float = movementInterval < DRAG_STOP_MS ? movementInterval : inputInterval;
        if (sampleMs <= 0) sampleMs = DRAG_VELOCITY_FALLBACK_MS;
        var sampleVelocity = distance * (1000.0 / sampleMs);
        if (velocity * sampleVelocity <= 0 || movementInterval >= DRAG_STOP_MS) {
            velocity = sampleVelocity;
        } else {
            velocity = FlxMath.lerp(sampleVelocity, velocity, Math.exp(-sampleMs / DRAG_VELOCITY_SMOOTH_MS));
        }
        lastMovementTick = now;
    }

    private function endDrag(now:Int):Void {
        if (!isDragging) return;
        isDragging = false;
        var recentMovement = FlxMath.bound((DRAG_STOP_MS - (now - lastMovementTick)) / (DRAG_STOP_MS - DRAG_RELEASE_HOLD_MS), 0, 1);
        velocity *= releaseBoost * recentMovement;
    }

    private function cancelDrag():Void {
        _dragPending = false;
        if (!isDragging) return;
        isDragging = false;
        velocity = 0;
    }

    private function get_tweenData():Float {
        return requestedTarget;
    }

    private function set_tweenData(value:Float):Float {
        if (value == requestedTarget && (allowLerp || moveTween != null)) return value;
        cancelMoveTo();
        requestedTarget = value;
        velocity = 0;
        if (target == value) return value;
        if (useLerp) allowLerp = true;
        else moveTween = FlxTween.num(target, value, tweenTime, {
            ease: CoolUtil.getTweenEaseByString(tweenType),
            onComplete: _ -> moveTween = null
        }, position -> target = position);
        return value;
    }

    private var moveTween:FlxTween;
    private function cancelMoveTo():Void {
        allowLerp = false;
        requestedTarget = 0;
        if (moveTween != null) {
            moveTween.cancel();
            moveTween = null;
        }
    }

    override public function destroy():Void {
        cancelMoveTo();
        super.destroy();
    }

    private function applyInertia(elapsed:Float):Void {
        // Integrating the exponential decay keeps unbounded inertia independent of the draw rate.
        var decay = Math.exp(-inertiaDecay * elapsed);
        var distance = velocity * (1 - decay) / inertiaDecay;
        velocity *= decay;
        if (!infScroll) {
            var boundary = FlxMath.bound(target, moveLimit[0], moveLimit[1]);
            var correction = (boundary - target) * springStrength * elapsed;
            velocity += correction;
            distance += correction * elapsed;
        }
        target += distance;
        if (Math.abs(velocity) < minVelocity) velocity = 0;
    }
}
