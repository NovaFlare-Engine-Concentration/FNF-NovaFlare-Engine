package mobile.input;

#if (mobile && FLX_MOUSE)
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import general.backend.ui.PsychUIInputText;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxInputText;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import openfl.display.InteractiveObject;
import openfl.display.Stage;
import openfl.events.KeyboardEvent;
import openfl.events.TextEvent;
import openfl.text.TextField;
import openfl.text.TextFieldType;
import openfl.ui.Keyboard;

/** Sends touch keyboard events through the same stage listeners as hardware keys. */
class VirtualPointerKeyboardInput
{
    public final ime:TextField;

    final stage:Stage;
    final pending:Array<PointerKeyEvent> = [];
    final downKeys:IntMap<PointerKeyEvent> = new IntMap();
    final pressedCharacters:StringMap<Int> = new StringMap();
    var modifiers:KeyModifier = KeyModifier.NONE;
    var imeOpened:Bool = false;

    public function new(stage:Stage)
    {
        this.stage = stage;
        ime = new TextField();
        ime.type = TextFieldType.INPUT;
        ime.width = ime.height = 2;
        ime.alpha = 0.01;
        ime.mouseEnabled = false;
        ime.needsSoftKeyboard = true;
        ime.addEventListener(TextEvent.TEXT_INPUT, onTextInput);
    }

    public function press(action:String):Void
    {
        switch (action)
        {
            case 'ime': showIME();
            case 'copy', 'paste': shortcut(action == 'copy' ? Keyboard.C : Keyboard.V);
            case 'back': enqueue(backCode(), 0, true, modifiers);
            default:
                var key = VirtualPointerKeyboard.find(action);
                if (key == null) return;
                if (toggleModifier(action, key.code)) return;
                var shifted = modifiers.shiftKey;
                if (modifiers.capsLock && key.code >= Keyboard.A && key.code <= Keyboard.Z) shifted = !shifted;
                var character = shifted && key.shiftCharacter != 0 ? key.shiftCharacter : key.character;
                pressedCharacters.set(action, character);
                enqueue(key.code, character, true, modifiers);
        }
    }

    public function release(action:String):Void
    {
        if (action == 'back')
        {
            enqueue(backCode(), 0, false, modifiers);
            return;
        }
        var key = VirtualPointerKeyboard.find(action);
        var character = pressedCharacters.get(action);
        if (key != null && character != null)
        {
            pressedCharacters.remove(action);
            enqueue(key.code, character, false, modifiers);
        }
    }

    public function isLatched(action:String):Bool
    {
        return switch (action)
        {
            case 'key:shift': modifiers.shiftKey;
            case 'key:ctrl': modifiers.ctrlKey;
            case 'key:alt': modifiers.altKey;
            case 'key:caps': modifiers.capsLock;
            default: false;
        }
    }

    function toggleModifier(action:String, code:Int):Bool
    {
        switch (action)
        {
            case 'key:shift': modifiers.shiftKey = !modifiers.shiftKey;
            case 'key:ctrl': modifiers.ctrlKey = !modifiers.ctrlKey;
            case 'key:alt': modifiers.altKey = !modifiers.altKey;
            case 'key:caps':
                modifiers.capsLock = !modifiers.capsLock;
                enqueue(code, 0, true, modifiers);
                enqueue(code, 0, false, modifiers);
                return true;
            default: return false;
        }
        enqueue(code, 0, isLatched(action), modifiers);
        return true;
    }

    function shortcut(code:Int):Void
    {
        var control = KeyModifier.CTRL;
        if (!modifiers.ctrlKey) enqueue(Keyboard.CONTROL, 0, true, control);
        enqueue(code, code + 32, true, control);
        enqueue(code, code + 32, false, control);
        if (!modifiers.ctrlKey) enqueue(Keyboard.CONTROL, 0, false, modifiers);
    }

    inline function backCode():Int
    {
        return #if android (cast flixel.input.android.FlxAndroidKey.BACK : Int) #else Keyboard.ESCAPE #end;
    }

    function enqueue(code:Int, character:Int, down:Bool, modifiers:KeyModifier):Void
    {
        pending.push({code: code, character: character, down: down, modifiers: modifiers, nativeCode: nativeKeyCode(code)});
    }

    public function update():Void
    {
        if (pending.length != 0) send(pending.shift());
    }

    public function reset():Void
    {
        pending.resize(0);
        pressedCharacters.clear();
        modifiers = KeyModifier.NONE;
        for (stroke in [for (stroke in downKeys) stroke])
            send({code: stroke.code, character: stroke.character, down: false, modifiers: modifiers, nativeCode: stroke.nativeCode});
        closeIME();
    }

    function send(stroke:PointerKeyEvent):Void
    {
        if (stroke.down) downKeys.set(stroke.code, stroke); else downKeys.remove(stroke.code);
        var mods = stroke.modifiers;
        var window = stage.window;
        if (stroke.nativeCode != KeyCode.UNKNOWN && window != null)
        {
            if (stroke.down) window.onKeyDown.dispatch(stroke.nativeCode, mods); else window.onKeyUp.dispatch(stroke.nativeCode, mods);
            if (stroke.down && stroke.character >= 32 && !mods.ctrlKey && !mods.altKey && window.textInputEnabled && stage.focus != ime)
            {
                // The legacy editor consumes Space on key down even when the Lime text-input signal is enabled.
                if (stroke.code != Keyboard.SPACE || PsychUIInputText.focusOn == null)
                    window.onTextInput.dispatch(String.fromCharCode(stroke.character));
            }
            return;
        }

        var event = new KeyboardEvent(stroke.down ? KeyboardEvent.KEY_DOWN : KeyboardEvent.KEY_UP, true, true,
            stroke.character, stroke.code, null, mods.ctrlKey, mods.altKey, mods.shiftKey, mods.ctrlKey);
        var target:InteractiveObject = stage.focus != null ? stage.focus : stage;
        target.dispatchEvent(event);
    }

    static function nativeKeyCode(code:Int):KeyCode
    {
        if (code >= Keyboard.A && code <= Keyboard.Z) return cast (code - Keyboard.A + (KeyCode.A : Int));
        if (code >= Keyboard.NUMBER_0 && code <= Keyboard.NUMBER_9) return cast code;
        if (code >= Keyboard.F1 && code <= Keyboard.F12) return cast (code - Keyboard.F1 + (KeyCode.F1 : Int));
        return switch (code)
        {
            case Keyboard.BACKSPACE, Keyboard.TAB, Keyboard.ENTER, Keyboard.SPACE: cast code;
            case Keyboard.DELETE: KeyCode.DELETE;
            case Keyboard.ESCAPE: KeyCode.ESCAPE;
            case Keyboard.INSERT: KeyCode.INSERT;
            case Keyboard.PAGE_UP: KeyCode.PAGE_UP;
            case Keyboard.PAGE_DOWN: KeyCode.PAGE_DOWN;
            case Keyboard.LEFT: KeyCode.LEFT;
            case Keyboard.RIGHT: KeyCode.RIGHT;
            case Keyboard.UP: KeyCode.UP;
            case Keyboard.DOWN: KeyCode.DOWN;
            case Keyboard.HOME: KeyCode.HOME;
            case Keyboard.END: KeyCode.END;
            case Keyboard.CONTROL: KeyCode.LEFT_CTRL;
            case Keyboard.ALTERNATE: KeyCode.LEFT_ALT;
            case Keyboard.SHIFT: KeyCode.LEFT_SHIFT;
            case Keyboard.CAPS_LOCK: KeyCode.CAPS_LOCK;
            case Keyboard.BACKQUOTE: KeyCode.GRAVE;
            case Keyboard.MINUS: KeyCode.MINUS;
            case Keyboard.EQUAL: KeyCode.EQUALS;
            case Keyboard.LEFTBRACKET: KeyCode.LEFT_BRACKET;
            case Keyboard.RIGHTBRACKET: KeyCode.RIGHT_BRACKET;
            case Keyboard.BACKSLASH: KeyCode.BACKSLASH;
            case Keyboard.SEMICOLON: KeyCode.SEMICOLON;
            case Keyboard.QUOTE: KeyCode.SINGLE_QUOTE;
            case Keyboard.COMMA: KeyCode.COMMA;
            case Keyboard.PERIOD: KeyCode.PERIOD;
            case Keyboard.SLASH: KeyCode.SLASH;
            case FlxKey.PRINTSCREEN: KeyCode.PRINT_SCREEN;
            default: KeyCode.UNKNOWN;
        };
    }

    function showIME():Void
    {
        var focus = stage.focus;
        var openflInputFocused = focus is TextField && cast(focus, TextField).type == TextFieldType.INPUT;
        var gameInputFocused = PsychUIInputText.focusOn != null || FlxInputText.globalManager.isTyping;
        if (!openflInputFocused && !gameInputFocused) stage.focus = ime;
        if (stage.window == null || stage.window.textInputEnabled) return;
        imeOpened = true;
        stage.window.textInputEnabled = true;
    }

    function closeIME():Void
    {
        if (stage.focus == ime) stage.focus = null;
        if (imeOpened && stage.window != null) stage.window.textInputEnabled = false;
        imeOpened = false;
    }

    function onTextInput(event:TextEvent):Void
    {
        if (stage.focus != ime) return;
        event.preventDefault();
        for (index in 0...event.text.length)
        {
            var character = event.text.charCodeAt(index);
            if (character == null) continue;
            var code = character >= 97 && character <= 122 ? character - 32 : character;
            pending.push({code: code, character: character, down: true, modifiers: KeyModifier.NONE, nativeCode: KeyCode.UNKNOWN});
            pending.push({code: code, character: character, down: false, modifiers: KeyModifier.NONE, nativeCode: KeyCode.UNKNOWN});
        }
    }
}

private typedef PointerKeyEvent = {
    final code:Int;
    final character:Int;
    final down:Bool;
    final modifiers:KeyModifier;
    final nativeCode:KeyCode;
}
#end
