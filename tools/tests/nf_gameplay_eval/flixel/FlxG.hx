package flixel;

class FlxG {
    public static var game = new openfl.display.Sprite();
    public static var signals = {focusGained: new TestSignal(), focusLost: new TestSignal()};
    public static var random = {int: function(min:Int, max:Int) return min};
    public static var autoPause = true;
}

class TestSignal {
    var listeners:Array<Void->Void> = [];
    public function new() {}
    public function has(fn:Void->Void):Bool {
        for (entry in listeners) if (Reflect.compareMethods(entry, fn)) return true;
        return false;
    }
    public function add(fn:Void->Void):Void { if (!has(fn)) listeners.push(fn); }
    public function remove(fn:Void->Void):Void {
        listeners = listeners.filter(function(entry) return !Reflect.compareMethods(entry, fn));
    }
    public function dispatch():Void { for (fn in listeners.copy()) fn(); }
}
