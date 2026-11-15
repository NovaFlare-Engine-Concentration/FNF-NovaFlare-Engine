class EngineSet { public static var mainColor = 0xFFFFFF; public static var minorColor = 0xFFFFFF; }
class Paths { public static function modFolders(value:String):String return value; }
class ClientPrefs { public static var data = {playOpponent: false, ghostTapping: true}; }
class Conductor { public static var songPosition:Float = 0; public static var safeZoneOffset:Float = 100; }
class LuaUtils {
    public static var Function_Continue = 'continue';
    public static var Function_Stop = 'stop';
    public static var Function_StopHScript = 'stop_hscript';
    public static var Function_StopAll = 'stop_all';
}
class Character {
    public var stunned = false;
    public var hasMissAnimations = false;
    public var animOffsets:Map<String, Bool> = [];
    public var specialAnim = false;
    public function new() {}
    public function playAnim(name:String, force:Bool = false):Void {}
}
class StrumNote {
    public var animation = {curAnim: {name: 'static'}};
    public var resetAnim:Float = 0;
    public function new() {}
    public function playAnim(name:String):Void {}
}
class Note {
    public var strumTime:Float;
    public var noteData = 0;
    public var mustPress = true;
    public var isSustainNote:Bool;
    public var parent:Note;
    public var tail:Array<Note> = [];
    public var alive = true;
    public var exists = true;
    public var wasGoodHit = false;
    public var missed = false;
    public var ignoreNote = false;
    public var blockHit = false;
    public var canBeHit = true;
    public var tooLate = false;
    public var canHold = true;
    public var lateHitMult:Float = 1;
    public var earlyHitMult:Float = 1;
    public var alpha:Float = 1;
    public var multAlpha:Float = 1;
    public var hitCausesMiss = false;
    public var killTail = false;
    public var gfNote = false;
    public var noMissAnimation = true;
    public var noteType = '';
    public var animSuffix = '';
    public var missHealth:Float = 0.05;
    public function new(time:Float, sustain:Bool, parent:Note = null) {
        strumTime = time; isSustainNote = sustain; this.parent = parent;
    }
}
