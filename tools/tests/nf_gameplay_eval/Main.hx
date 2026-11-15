import general.objects.screen.MouseEffect;
import general.objects.screen.MouseEffect.ClickEffect;
import games.backend.GameplayVideoPause;
import hxvlc.flixel.FlxInternalVideo;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Point;

@:access(general.objects.screen.MouseEffect)
class Main {
    static var passed = 0;
    static function check(value:Bool, message:String):Void {
        if (!value) throw message;
        passed++; trace('PASS ' + message);
    }
    static function near(a:Float, b:Float):Bool return Math.abs(a - b) < 0.001;
    static function mouse():Void {
        // OpenFL transforms/bitmap bounds are real; only the stage event host is synthetic.
        untyped openfl.Lib.current.stage = cast new Sprite();
        var bitmap = new BitmapData(64, 48, true, 0xffffffff);
        var click = new ClickEffect(bitmap, bitmap);
        click.init(0, 0);
        @:privateAccess click.clickTimer -= 0.2;
        @:privateAccess click.circleTimer -= 0.2;
        click.update(); click.init(100, 100);
        for (i in 0...click.numChildren) {
            var child = click.getChildAt(i);
            check(near(child.x + child.width / 2, 0) && near(child.y + child.height / 2, 0), 'pooled click layer stays centered on reuse');
        }
        var parent = new Sprite(); parent.x = 73; parent.y = 31; parent.scaleX = 1.5; parent.scaleY = 1.25;
        var effect = new MouseEffect(bitmap, bitmap, bitmap); parent.addChild(effect);
        var event = new MouseEvent(MouseEvent.MOUSE_DOWN); event.stageX = 300; event.stageY = 200;
        effect.onMouseDown(event);
        var position = effect.getChildAt(0).localToGlobal(new Point());
        check(near(position.x, 300) && near(position.y, 200), 'click matches pointer under parent translation and scaling');
        effect.onMouseMove(event);
        check(effect.activeTrailEffects.length == 0, 'first move initializes the trail anchor');
        event.stageX += 120; effect.onMouseMove(event);
        check(effect.activeTrailEffects.length == 1, 'movement creates a trail at the configured distance');
        effect.onMouseLeave(null); event.stageX += 500; effect.onMouseMove(event);
        check(effect.activeTrailEffects.length == 1, 'window re-entry resets the trail anchor');
        MouseEffect.enterEditor();
        check(effect.activeClickEffects.length == 0 && effect.activeTrailEffects.length == 0, 'entering an editor clears NF mouse effects');
        effect.onMouseDown(event); effect.onMouseMove(event);
        check(effect.activeClickEffects.length == 0 && effect.activeTrailEffects.length == 0, 'editor ownership suppresses NF mouse effects');
        MouseEffect.enterEditor(); MouseEffect.leaveEditor();
        check(!MouseEffect.effectsEnabled(), 'nested editor remains in control until the final release');
        MouseEffect.enterGameplay(); MouseEffect.leaveEditor();
        check(!MouseEffect.effectsEnabled(), 'leaving the editor does not override gameplay suppression');
        MouseEffect.leaveGameplay();
        check(MouseEffect.effectsEnabled(), 'mouse effects resume after all owners release');
        MouseEffect.setUserEffectsEnabled(false); MouseEffect.enterEditor(); MouseEffect.leaveEditor();
        check(!MouseEffect.effectsEnabled(), 'editor ownership preserves the user-disabled mouse setting');
        MouseEffect.setUserEffectsEnabled(true);
        effect.clearEffects(); effect.onRemovedFromStage(null); bitmap.dispose();
    }
    static function sustains():Void {
        ClientPrefs.data.playOpponent = false;
        var play = new ProbePlayState();
        var head = new Note(0, false); head.wasGoodHit = true;
        var expired = new Note(1000, true, head); var future = new Note(1200, true, head);
        head.tail = [expired, future]; play.notes = {members: [expired, future], length: 2};
        play.checkSustainMisses(1099);
        check(!head.missed, 'hold is recoverable inside the late window');
        play.checkSustainMisses(1101);
        check(head.missed && expired.missed && future.missed && !future.canHold && play.songMisses == 1,
            'expired hold breaks its whole chain before note cleanup');
        Conductor.songPosition = 1200; play.keyPressed(0);
        check(!future.canHold, 'new press cannot re-arm a broken hold');
        play.replayApplyInput(1200, [0], [], [true]);
        check(play.hits == 0 && play.songMisses == 1, 'replay rejects broken holds without duplicate misses');
        ClientPrefs.data.playOpponent = true; expired.mustPress = false; future.mustPress = false;
        play.keyPressed(0);
        check(!future.canHold, 'opponent mode rejects re-arming broken holds');
        play.guitarHeroSustains = false; play.keyPressed(0);
        check(future.canHold, 'disabling the option preserves hold recovery');
        var calls = 0; play.paused = true; play.timing.onFocus = function() calls++;
        play.onFocus(); check(calls == 0, 'focus gain does not resume the song clock behind a pause menu');
        ClientPrefs.data.playOpponent = false;
        play = new ProbePlayState(); head = new Note(1000, false); future = new Note(1200, true, head);
        head.tail = [future]; play.notes = {members: [head, future], length: 2}; play.checkSustainMisses(1101);
        check(head.missed && future.missed && !future.canHold, 'missing the head disables the entire hold');
    }
    static function video():Void {
        var playing = new FlxInternalVideo(); var manual = new FlxInternalVideo(); var idle = new FlxInternalVideo();
        playing.play(); manual.play(); manual.pause();
        FlxG.signals.focusLost.dispatch();
        var controller = new GameplayVideoPause(); controller.pause(); controller.pause();
        var resumes = playing.resumes;
        FlxG.signals.focusGained.dispatch();
        check(!playing.isPlaying && playing.resumes == resumes, 'focus gain cannot restart video while the pause menu remains open');
        controller.resume();
        check(playing.isPlaying && !manual.isPlaying && !idle.isPlaying, 'menu exit restores only previously playing videos');
        controller.pause(); idle.play();
        check(!idle.isPlaying, 'asynchronous video opening and playing are held paused');
        FlxG.signals.focusGained.dispatch(); check(!idle.isPlaying, 'late opening cannot re-register automatic focus resume');
        playing.dispose(); controller.resume();
        check(idle.isPlaying && !manual.isPlaying && playing.resumes == resumes + 1, 'destroyed video is not restarted on resume');
        controller.pause(); controller.destroy(); manual.dispose(); idle.dispose();
    }
    static function main():Void {
        mouse(); sustains(); video();
        trace('ALL ' + passed + ' REGRESSION CHECKS PASSED (OpenFL + source methods + decoder double)');
    }
}
