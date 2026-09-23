package general.backend.mouse;

import flixel.FlxBasic;

class MouseMove extends FlxBasic
{
    public var allowUpdate:Bool = true;
    public var enableMouseWheel:Bool = true;
    
    public var follow:Dynamic; //数据跟谁
    public var followData:String; //数据变量的名称

    public var target:Float;
    public var moveLimit:Array<Float> = [0, 0];  //[min, max]
    public var mouseLimit:Array<Array<Float>> = [];   //[ X[min, max], Y[min, max] ]

    public var mouseWheelSensitivity:Float = 1000.0; // 鼠标滚轮更改量的控制变量
    public var tweenData(default, set):Float = 0; //用于tween/lerp到指定数据的
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
    private var velocityArray:Array<Float> = [];

    private var __target:Float;
    public var state:String = 'stop';
    
    // 物理参数
    private var dragSensitivity:Float = 1.0;   // 拖动灵敏度
    private var deceleration:Float = 0.9;      // 减速系数 (0.9 - 0.99 效果较好)
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
    
    private var _lastUpdateTime:Int = 0;
    private var __lastDragTick:Int = 0;
    private var _inertiaTime:Float = 0;
    public var inputAllow:Bool = true;
    private var allowLerp:Bool = false;
    private var _pendingDragDelta:Float = 0;
    public var dragStartDelayMs:Int = 100;
    public var dragStartDistance:Float = 10;
    private var _dragPending:Bool = false;
    private var _dragPendingTick:Int = 0;
    private var _dragPendingY:Float = 0;
    override function update(elapsed:Float) {
        if (!allowUpdate) {
            super.update(elapsed);
            return;
        }

        saveElapsed = elapsed;

        var mouse = FlxG.mouse;

        var checkInput:Bool = true;

        if (!(mouse.x > mouseLimit[0][0] && mouse.x < mouseLimit[0][1] && mouse.y > mouseLimit[1][0] && mouse.y < mouseLimit[1][1])) {
            endDrag();
            _dragPending = false;
            checkInput = false;
        }
        
        if (checkInput && inputAllow) {
            // 鼠标按下
            if (mouse.justPressed) {
                _dragPending = true;
                _dragPendingTick = FlxG.game.ticks;
                _dragPendingY = mouse.y;
                lastMouseY = mouse.y;
            }

            if (_dragPending && mouse.pressed) {
                var heldMs = FlxG.game.ticks - _dragPendingTick;
                var moved = Math.abs(mouse.y - _dragPendingY);
                if (heldMs >= dragStartDelayMs || moved >= dragStartDistance) {
                    _dragPending = false;
                    startDrag(mouse.y);
                    cancelMoveTo();
                }
            }

            // 鼠标滚轮
            if (enableMouseWheel && mouse.wheel!= 0) {
                isDragging = false;
                _dragPending = false;
                velocity += mouse.wheel * mouseWheelSensitivity;
                cancelMoveTo();
            }
            
            // 拖动中更新位置
            if (isDragging && mouse.pressed)
            {
                updateDrag(mouse.y);
            }

            // 鼠标释放时停止拖动
            if (mouse.justReleased) {
                if (_dragPending) _dragPending = false;
                endDrag();
            }
        } else {
            lastMouseY = mouse.y;
            _dragPending = false;
        }

        super.update(elapsed);
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

        if (tweenData != 0 && allowLerp) {
            if (Math.abs(target - tweenData) < 0.1) {
                target = tweenData;
                tweenData = 0;
                allowLerp = false;
            } else {
                target = FlxMath.lerp(tweenData, target, Math.exp(-elapsed * lerpSmooth));
            }
        }

        // ★ 越界当场贴边（原来是 lerp 渐进回弹）。
        //
        // lerp 软回弹会和「拖拽增量 / 惯性」互相拉锯：
        //   鼠标还在往外拖 → 每帧 `target += _pendingDragDelta` 加一点，
        //   lerp 每帧又往回拉一点 → 拖到顶/底时内容一推一拉地抽搐。
        // 直接夹住后，拖到尽头/滚到尽头都是干净地停住。
        if(!infScroll) {
            if (target < moveLimit[0]) target = moveLimit[0];
            else if (target > moveLimit[1]) target = moveLimit[1];
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
    
    private function startDrag(startY:Float) {
        isDragging = true;
        lastMouseY = startY;
        velocLastMouseY = startY;
        _lastUpdateTime = FlxG.game.ticks;
        velocity = 0;
        velocityArray = [];
        __lastDragTick = FlxG.game.ticks;
        _inertiaTime = 0;
        _pendingDragDelta = 0;
    }
    
    private var velocLastMouseY:Float = 0;
    private function updateDrag(currentY:Float) {
        var deltaY = currentY - lastMouseY;
        var now = FlxG.game.ticks;
        var deltaMs = Math.max(1, now - __lastDragTick);
        velocity = (deltaY * dragSensitivity) * (1000.0 / deltaMs);
        _pendingDragDelta += deltaY * dragSensitivity;
        lastMouseY = currentY;
        __lastDragTick = now;

        if (FlxG.game.ticks - _lastUpdateTime >= 16)
        {
            var dY = currentY - velocLastMouseY;
            var dMs = Math.max(1, FlxG.game.ticks - _lastUpdateTime);
            var vps = (dY * dragSensitivity) * (1000.0 / dMs);
            velocUpdate(vps);
            velocLastMouseY = currentY;
            
            _lastUpdateTime = FlxG.game.ticks;
        }
    }
    
    private function endDrag() {
        if (!isDragging) return;
        isDragging = false;
        if (velocLastMouseY != lastMouseY) {
            var dY = lastMouseY - velocLastMouseY;
            var dMs = Math.max(1, FlxG.game.ticks - _lastUpdateTime);
            var vps = (dY * dragSensitivity) * (1000.0 / dMs);
            velocUpdate(vps);
            velocLastMouseY = lastMouseY;
        }
        velocityChange();
        velocity *= releaseBoost;
        _inertiaTime = 0;
    }

    private function set_tweenData(value:Float) {
        var doNotStop:Bool = value == tweenData;
        tweenData = value;
        if (!doNotStop) moveTo(tweenData);

        return tweenData;
    }

    private var moveTween:FlxTween = null;
    private function moveTo(data:Float) {
        if (!useLerp) {
            if (moveTween != null) moveTween.cancel();
            moveTween = FlxTween.num(target, data, tweenTime, {ease:CoolUtil.getTweenEaseByString(tweenType)}, function(v){target = v;});
        } else {
            allowLerp = true;
        }
    }

    private function cancelMoveTo() {
        allowLerp = false;
        tweenData = 0;
        if (moveTween != null) moveTween.cancel();
    }

    /**
     * 强制把滚动量**当场落位**到 v：清掉惯性、拖动残留和补间，不留任何后续写入。
     *
     * ★★ 为什么不能只写 `tweenData = 0`（踩过的坑）★★
     *   `tweenData` 只是"想去的位置 / 补间目标"，真正被反射写回
     *   `follow.followData` 的是 **`target`**（见 drawUpdate 里那句
     *   `if (targetChanged) Reflect.setProperty(...)`）。
     *   只设 tweenData 时 `target` 还停在旧值，而滚轮给的 `velocity` 有几千的量级、
     *   要衰减好几秒；`applyInertia` 每帧都会改 `target` → `targetChanged` 为真 →
     *   把旧值原样写回去。结果就是：切分类时 `contentScrollPos` 刚被置 0，
     *   下一帧又被顶回"上一个分类滚到底"的位置，新分类一进来就是滚到底的状态
     *   （本轮抓图实测：点开「用户界面」直接看到第 2 行 customFadeSound 顶在最上面）。
     *   所以复位必须连 `target` / `__target` / `velocity` 一起清，并直接写一次外部值。
     */
    public function resetTo(v:Float):Void {
        if (moveTween != null) { moveTween.cancel(); moveTween = null; }
        isDragging = false;
        _dragPending = false;
        velocity = 0;
        velocityArray = [];
        _pendingDragDelta = 0;
        _inertiaTime = 0;
        tweenData = 0;        // 可能触发 moveTo(0) 把 allowLerp 打开…
        allowLerp = false;    // …所以关它要放在后面
        target = v;
        __target = v;
        Reflect.setProperty(follow, followData, v);
    }

    var isPositive:Bool = true; //正数检测
    private function velocUpdate(data:Float) {
        var zero = Math.abs(data) < minVelocity;
        if (isPositive) {
            if (data > 0) {
                velocityArray = velocityArray.filter(function(v) return Math.abs(v) >= minVelocity);
                velocityArray.push(data);
                if (velocityArray.length > 11) velocityArray.shift();
            } else if (data < 0) {
                velocityArray = [];
                if (!zero) velocityArray.push(data);
                isPositive = false;
            } else {
                velocityArray.push(0);
                if (velocityArray.length > 11) velocityArray.shift();
            }
        } else {
            if (data < 0) {
                velocityArray = velocityArray.filter(function(v) return Math.abs(v) >= minVelocity);
                velocityArray.push(data);
                if (velocityArray.length > 11) velocityArray.shift();
            } else if (data > 0)  {
                velocityArray = [];
                if (!zero) velocityArray.push(data);
                isPositive = true;
            } else {
                velocityArray.push(0);
                if (velocityArray.length > 11) velocityArray.shift();
            }
        }
    }

    private function velocityChange() {
        if (velocityArray.length < 3) {
            velocity = 0;
            return;
        }
        var delete = Std.int(velocityArray.length / 6);
        var sorted = velocityArray.copy();
        sorted.sort(Reflect.compare);
        var low = sorted[delete];
        var high = sorted[sorted.length - 1 - delete];
        var filtered:Array<Float> = [];
        for (v in velocityArray) if (v >= low && v <= high) filtered.push(v);
        if (filtered.length == 0) filtered = velocityArray.copy();
        var sum:Float = 0;
        var weightSum:Float = 0;
        var n = filtered.length;
        for (i in 0...n) {
            var w = Math.pow(1.25, i);
            sum += filtered[i] * w;
            weightSum += w;
        }
        velocity = sum / weightSum;
    }

    private function applyInertia(elapsed:Float) {
        _inertiaTime += elapsed;
        var decelFactor = Math.pow(deceleration, elapsed * 60);
        velocity *= decelFactor;

        // ★ 边界处理：夹住位置 + 吃掉「朝外」的速度。
        //
        // 原来这里是纯弹簧（acc = 超出量 × springStrength，无阻尼）：
        //   越界 → 被拉回 → 因惯性冲过头 → 反向越界 → 再被拉回 …… 来回振荡；
        // 再叠上下面 `|velocity| < minVelocity` 提前 return（它跳过了
        //   `target += velocity * elapsed`），停在顶/底时位置会卡在越界处不动、
        //   下一帧弹簧又给一个加速度 —— 表现就是滚到尽头/拖到尽头时来回抽搐。
        //
        // 改成硬夹：越界当场贴边，并把继续往外的速度清零，只在反方向（往回收）时保留速度。
        if (!infScroll) {
            if (target < moveLimit[0]) {
                target = moveLimit[0];
                if (velocity < 0) velocity = 0;
            } else if (target > moveLimit[1]) {
                target = moveLimit[1];
                if (velocity > 0) velocity = 0;
            }
        }

        if (Math.abs(velocity) < minVelocity) {
            velocity = 0;
            return;
        }
        target += velocity * elapsed;

        // 这一帧走完再夹一次：避免单帧位移跨过边界后又被下一帧拉回来
        if (!infScroll) {
            if (target < moveLimit[0]) {
                target = moveLimit[0];
                velocity = 0;
            } else if (target > moveLimit[1]) {
                target = moveLimit[1];
                velocity = 0;
            }
        }
    }
}
