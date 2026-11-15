package hxvlc.flixel;

import flixel.FlxG;
import flixel.FlxG.TestSignal;

/** Decoder double matching hxvlc 2.2.4's focus signal order and resume intent. */
class FlxInternalVideo extends openfl.display.Sprite {
    public var isPlaying = false;
    private var resumeOnFocus = false;
    public var onOpening = new TestSignal();
    public var onPlaying = new TestSignal();
    public var resumes = 0;
    public function new() {
        super();
        onOpening.add(function() {
            FlxG.signals.focusGained.add(onFocusGained);
            FlxG.signals.focusLost.add(onFocusLost);
        });
        FlxG.game.addChild(this);
    }
    public function play():Void { onOpening.dispatch(); isPlaying = true; onPlaying.dispatch(); }
    public function pause():Void { isPlaying = false; }
    public function resume():Void { resumes++; isPlaying = true; onPlaying.dispatch(); }
    private function onFocusLost():Void { resumeOnFocus = isPlaying; pause(); }
    private function onFocusGained():Void {
        if (resumeOnFocus) { resumeOnFocus = false; resume(); }
    }
    public function dispose():Void {
        FlxG.signals.focusGained.remove(onFocusGained);
        FlxG.signals.focusLost.remove(onFocusLost);
        if (parent != null) parent.removeChild(this);
        isPlaying = false;
    }
}
