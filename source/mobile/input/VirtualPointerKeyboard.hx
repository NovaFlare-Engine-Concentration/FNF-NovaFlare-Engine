package mobile.input;

import flixel.input.keyboard.FlxKey;
import openfl.ui.Keyboard;

typedef VirtualPointerKey = {
    final action:String;
    final label:String;
    final code:Int;
    final character:Int;
    final shiftCharacter:Int;
    final weight:Float;
}

class VirtualPointerKeyboard
{
    public static final rows:Array<Array<VirtualPointerKey>> = [
        [key("escape", "Esc", Keyboard.ESCAPE, {weight: 1.15})]
            .concat([for (number in 1...13) key('f$number', 'F$number', Keyboard.F1 + number - 1)])
            .concat([
                key("print", "PrtSc", FlxKey.PRINTSCREEN, {weight: 1.25}),
                key("home", "Home", Keyboard.HOME, {weight: 1.18}),
                key("end", "End", Keyboard.END),
                key("delete", "Del", Keyboard.DELETE)
            ]),
        [
            symbol("grave", "`~", Keyboard.BACKQUOTE),
            symbol("1", "1!", Keyboard.NUMBER_1),
            symbol("2", "2@", Keyboard.NUMBER_2),
            symbol("3", "3#", Keyboard.NUMBER_3),
            symbol("4", "4$", Keyboard.NUMBER_4),
            symbol("5", "5%", Keyboard.NUMBER_5),
            symbol("6", "6^", Keyboard.NUMBER_6),
            symbol("7", "7&", Keyboard.NUMBER_7),
            symbol("8", "8*", Keyboard.NUMBER_8),
            symbol("9", "9(", Keyboard.NUMBER_9),
            symbol("0", "0)", Keyboard.NUMBER_0),
            symbol("minus", "-_", Keyboard.MINUS),
            symbol("equal", "=+", Keyboard.EQUAL),
            key("backspace", "Bksp", Keyboard.BACKSPACE, {weight: 1.65}),
            key("page-up", "PgUp", Keyboard.PAGE_UP, {weight: 1.15})
        ],
        [key("tab", "Tab", Keyboard.TAB, {weight: 1.35})]
            .concat(letters("QWERTYUIOP"))
            .concat([
                symbol("left-bracket", "[{", Keyboard.LEFTBRACKET),
                symbol("right-bracket", "]}", Keyboard.RIGHTBRACKET),
                symbol("backslash", "\\|", Keyboard.BACKSLASH),
                key("page-down", "PgDn", Keyboard.PAGE_DOWN, {weight: 1.15})
            ]),
        [key("caps", "Caps", Keyboard.CAPS_LOCK, {weight: 1.55})]
            .concat(letters("ASDFGHJKL"))
            .concat([
                symbol("semicolon", ";:", Keyboard.SEMICOLON),
                symbol("quote", "'\"", Keyboard.QUOTE),
                key("enter", "Enter", Keyboard.ENTER, {weight: 1.65}),
                key("insert", "Ins", Keyboard.INSERT, {weight: 1.15})
            ]),
        [key("shift", "Shift", Keyboard.SHIFT, {weight: 1.95})]
            .concat(letters("ZXCVBNM"))
            .concat([
                symbol("comma", ",<", Keyboard.COMMA),
                symbol("period", ".>", Keyboard.PERIOD),
                symbol("slash", "/?", Keyboard.SLASH),
                key("up", "↑", Keyboard.UP)
            ]),
        [
            key("ctrl", "Ctrl", Keyboard.CONTROL, {weight: 1.45}),
            key("alt", "Alt", Keyboard.ALTERNATE, {weight: 1.35}),
            key("space", "Space", Keyboard.SPACE, {weight: 6.1, characters: "  "}),
            key("left", "←", Keyboard.LEFT),
            key("down", "↓", Keyboard.DOWN),
            key("right", "→", Keyboard.RIGHT)
        ]
    ];

    static final byAction:Map<String, VirtualPointerKey> = [for (row in rows) for (item in row) item.action => item];

    public static function find(action:String):Null<VirtualPointerKey>
    {
        return byAction.get(action);
    }

    static function letters(row:String):Array<VirtualPointerKey>
    {
        return [for (index in 0...row.length) {
            var label = row.charAt(index);
            var lower = label.toLowerCase();
            key(lower, label, row.charCodeAt(index), {characters: lower + label});
        }];
    }

    static function symbol(id:String, pair:String, code:Int):VirtualPointerKey
    {
        return key(id, pair.charAt(0) + " " + pair.charAt(1), code, {characters: pair});
    }

    static function key(id:String, label:String, code:Int, ?options:{?weight:Float, ?characters:String}):VirtualPointerKey
    {
        var characters = options?.characters;
        return {
            action: 'key:$id',
            label: label,
            code: code,
            character: characters?.charCodeAt(0) ?? 0,
            shiftCharacter: characters?.charCodeAt(1) ?? 0,
            weight: options?.weight ?? 1
        };
    }
}
