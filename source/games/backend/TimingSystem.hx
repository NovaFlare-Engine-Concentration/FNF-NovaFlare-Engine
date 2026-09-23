package games.backend;

import haxe.Timer;

import lime.system.System;

class TimingSystem {
    public var isPlaying:Bool = false;
    public var tickEnabled:Bool = false;
    public var ratePrimary:Float = 1.0;
    public var rateSecondary:Float = 1.0;
    var positionBaseMs:Float = 0.0;
    var timestampBaseSec:Float = 0.0;
    var baseTimerMs:Float = 0;
    var lastTimerMs:Float = -1;
    var wrapOffsetMs:Float = 0.0;
    var pauseStartSec:Float = 0.0;
    var accumulatedPauseSec:Float = 0.0;

    public function new() {}

    inline function nowSec():Float {
        return System.getTimerNano() / 1000;
    }

    inline function nowTimerMs():Float {
        var t:Float = System.getTimerNano();
        if (lastTimerMs < 0) lastTimerMs = t;
        if (t < lastTimerMs) wrapOffsetMs += 4294967296.0;
        lastTimerMs = t;
        return t + wrapOffsetMs;
    }

    inline function totalRate():Float {
        return ratePrimary * rateSecondary;
    }

    public function play():Void {
        if (isPlaying) return;
        timestampBaseSec = nowSec();
        baseTimerMs = nowTimerMs();
        isPlaying = true;
        tickEnabled = true;
    }

    public function pause():Void {
        if (!isPlaying) return;
        positionBaseMs = getPositionMs();
        pauseStartSec = nowSec();
        isPlaying = false;
        tickEnabled = false;
    }

    public function resume():Void {
        var n:Float = nowSec();
        // 已经在跑的时候不能直接把 timestampBaseSec 挪到 now：那等于把已经走过的时间
        // 丢掉、时钟瞬间倒退到 positionBaseMs。先把当前位置固化下来再重新锚定，
        // resume() 就成了幂等操作 —— 「暂停后继续」这条路上即使重复调用也不会跳时间。
        if (isPlaying) {
            positionBaseMs = getPositionMs();
            timestampBaseSec = n;
            baseTimerMs = nowTimerMs();
            tickEnabled = true;
            return;
        }
        if (pauseStartSec > 0) {
            accumulatedPauseSec += (n - pauseStartSec);
            pauseStartSec = 0;
        }
        timestampBaseSec = n;
        baseTimerMs = nowTimerMs();
        isPlaying = true;
        tickEnabled = true;
    }

    public function setPrimaryRate(r:Float):Void {
        var pos:Float = getPositionMs();
        ratePrimary = r;
        positionBaseMs = pos;
        timestampBaseSec = nowSec();
    }

    public function setSecondaryRate(r:Float):Void {
        var pos:Float = getPositionMs();
        rateSecondary = r;
        positionBaseMs = pos;
        timestampBaseSec = nowSec();
    }

    public function setRate(r:Float):Void {
        setPrimaryRate(r);
        setSecondaryRate(1.0);
    }

    public function seek(ms:Float):Void {
        setPosition(ms);
    }

    public function setPosition(ms:Float):Void {
        positionBaseMs = ms;
        timestampBaseSec = nowSec();
    }

    public function enableTick():Void {
        positionBaseMs = getPositionMs();
        timestampBaseSec = nowSec();
        tickEnabled = true;
    }

    public function disableTick():Void {
        tickEnabled = false;
    }

    public function getPositionMs():Float {
        if (!isPlaying && !tickEnabled) return positionBaseMs;
        var dt:Float = (nowSec() - timestampBaseSec) * 1000.0;
        return positionBaseMs + dt * totalRate();
    }

    public function getPositionSec():Float {
        return getPositionMs() / 1000.0;
    }

    public function onFocus():Void {
        if (FlxG.autoPause) resume();
    }

    public function onFocusLost():Void {
        if (FlxG.autoPause) pause();
    }

    public function getDebugString():String {
        var s:String = '';
        s += 'playing=' + isPlaying + '\n';
        s += 'posMs=' + Std.string(Std.int(getPositionMs())) + '\n';
        s += 'rate=' + Std.string(totalRate()) + ' (' + Std.string(ratePrimary) + ' x ' + Std.string(rateSecondary) + ')\n';
        s += 'baseTimerMs=' + Std.string(baseTimerMs) + '\n';
        s += 'wrapOffsetMs=' + Std.string(Std.int(wrapOffsetMs)) + '\n';
        s += 'accPauseMs=' + Std.string(Std.int(accumulatedPauseSec * 1000.0));
        return s;
    }
}
