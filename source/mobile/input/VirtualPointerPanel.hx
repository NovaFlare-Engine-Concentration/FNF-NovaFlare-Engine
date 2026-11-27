package mobile.input;

#if (mobile && FLX_MOUSE)
import haxe.ds.StringMap;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.text.Font;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.utils.AssetType;
import openfl.utils.Assets;

/** Draws the overlay and maps touch coordinates independently of input dispatch. */
class VirtualPointerPanel extends Sprite
{
    static inline final REFERENCE_SHORT_EDGE = 720;
    static inline final TEXT = 0x202020;
    static inline final SUBTLE_TEXT = 0x383838;

    var controls:Array<PointerPanelControl> = [];
    var controlsByAction:StringMap<PointerPanelControl> = new StringMap();
    var bounds:Rectangle = new Rectangle();
    var slider:Shape;
    var sliderTrack:Rectangle;
    var sensitivity:Float = 0.5;
    var labelFont:Null<String>;
    var triedLabelFont:Bool = false;

    public function new()
    {
        super();
        mouseEnabled = false;
        mouseChildren = false;
    }

    public function layout(stageWidth:Float, stageHeight:Float, keyboardVisible:Bool, sensitivity:Float):Void
    {
        removeChildren();
        graphics.clear();
        controls = [];
        controlsByAction = new StringMap();
        slider = null;
        sliderTrack = null;
        this.sensitivity = clamp(sensitivity, 0, 1);

        final displayScale = Math.max(1, Math.min(stageWidth, stageHeight) / REFERENCE_SHORT_EDGE);
        scaleX = scaleY = displayScale;
        final viewportWidth = stageWidth / displayScale;
        final viewportHeight = stageHeight / displayScale;
        final margin = clamp(Math.min(viewportWidth, viewportHeight) * 0.025, 5, 18);
        final padding = clamp(viewportWidth * 0.013, 5, 8);
        final panelWidth = Math.max(1, Math.min(viewportWidth - margin * 2, keyboardVisible ? 1056 : 760));
        final innerWidth = Math.max(1, panelWidth - padding * 2);
        final rowWidth = Math.min(innerWidth, 744);
        final oneRow = rowWidth >= 680;
        final rowHeight = clamp(viewportHeight * 0.064, 30, 40);
        final gap = Math.max(4, padding * 0.75);
        final keyboardHeight = keyboardVisible ? clamp(viewportHeight * 0.325, 76, 239) : 0;
        final rowsBottom = padding + rowHeight + (oneRow ? 0 : rowHeight + gap);
        final panelHeight = rowsBottom + (keyboardVisible ? gap + keyboardHeight : 0) + padding;
        x = (stageWidth - panelWidth * displayScale) * 0.5;
        y = Math.max(0, stageHeight - (panelHeight + margin) * displayScale);
        bounds.setTo(0, 0, panelWidth, panelHeight);

        graphics.beginFill(0x383838, 0.84);
        graphics.drawRoundRect(0, 0, panelWidth, panelHeight, 12);
        graphics.endFill();
        drawControls(new Rectangle((panelWidth - rowWidth) * 0.5, padding, rowWidth, rowHeight), gap, keyboardVisible, oneRow);
        if (keyboardVisible) drawKeyboard(new Rectangle(padding, rowsBottom + gap, innerWidth, keyboardHeight), gap);
    }

    public function actionAt(stageX:Float, stageY:Float):Null<String>
    {
        final localX = toLocalX(stageX);
        final localY = (stageY - y) / scaleY;
        if (!bounds.contains(localX, localY)) return null;
        for (control in controls)
            if (control.bounds.contains(localX, localY)) return control.action;
        return "idle";
    }

    public function sensitivityAt(stageX:Float):Float
    {
        if (sliderTrack == null) return sensitivity;
        return clamp((toLocalX(stageX) - sliderTrack.x) / sliderTrack.width, 0, 1);
    }

    inline function toLocalX(stageX:Float):Float
        return (stageX - x) / scaleX;

    public function setSensitivity(value:Float):Void
    {
        sensitivity = clamp(value, 0, 1);
        if (slider != null) drawSlider();
    }

    public function setPressed(action:String, active:Bool):Void
    {
        final control = controlsByAction.get(action);
        if (control == null || control.pressed == active) return;
        control.pressed = active;
        drawButtonSkin(control);
    }

    function drawControls(area:Rectangle, gap:Float, keyboardVisible:Bool, oneRow:Bool):Void
    {
        final actionsWidth = Math.min(keyboardVisible ? 182 : 134, area.width * 0.54);
        final utilitiesWidth = Math.min(166, area.width - actionsWidth - gap);
        final actionsX = area.right - actionsWidth;
        drawUtilities(new Rectangle(area.x, area.y, utilitiesWidth, area.height), gap);
        drawKeyboardActions(new Rectangle(actionsX, area.y, actionsWidth, area.height), gap, keyboardVisible);
        if (oneRow)
        {
            final mouseX = area.x + utilitiesWidth + gap;
            drawMouseControls(new Rectangle(mouseX, area.y, actionsX - mouseX - gap, area.height), gap);
            return;
        }
        drawMouseControls(new Rectangle(area.x, area.bottom + gap, area.width, area.height), gap);
    }

    function drawUtilities(area:Rectangle, gap:Float):Void
    {
        final width = Math.max(1, (area.width - gap * 2) / 3);
        final size = Math.min(16, area.height * 0.43);
        addButton("back", "返回", new Rectangle(area.x, area.y, width, area.height), {size: size, fallback: "Back"});
        addButton("copy", "复制", new Rectangle(area.x + width + gap, area.y, width, area.height), {size: size, fallback: "Copy"});
        addButton("paste", "粘贴", new Rectangle(area.right - width, area.y, width, area.height), {size: size, fallback: "Paste"});
    }

    function drawKeyboardActions(area:Rectangle, gap:Float, keyboardVisible:Bool):Void
    {
        final closeWidth = Math.min(area.height, area.width * 0.28);
        final keyActionsWidth = area.width - closeWidth - gap;
        final imeWidth = keyboardVisible ? (keyActionsWidth - gap) * 0.40 : 0;
        final keyboardX = keyboardVisible ? area.x + imeWidth + gap : area.x;
        final keyboardWidth = keyboardVisible ? keyActionsWidth - imeWidth - gap : keyActionsWidth;
        final size = Math.min(16, area.height * 0.43);
        if (keyboardVisible)
            addButton("ime", "输入法", new Rectangle(area.x, area.y, imeWidth, area.height), {size: size, fallback: "IME"});
        addButton("keyboard", keyboardVisible ? "收起键盘" : "键盘", new Rectangle(keyboardX, area.y, keyboardWidth, area.height),
            {size: size, fallback: keyboardVisible ? "Hide keys" : "Keyboard"});
        addButton("close", "×", new Rectangle(area.right - closeWidth, area.y, closeWidth, area.height), {size: size * 1.27});
        setPressed("keyboard", keyboardVisible);
    }

    function drawMouseControls(area:Rectangle, gap:Float):Void
    {
        final sliderWidth = area.width * 0.40;
        final buttonWidth = Math.max(1, (area.width - sliderWidth - gap * 3) / 3);
        final size = Math.min(15, area.height * 0.38);
        addButton("left", "左键", new Rectangle(area.x, area.y, buttonWidth, area.height), {size: size, fallback: "Left"});
        addButton("right", "右键", new Rectangle(area.x + buttonWidth + gap, area.y, buttonWidth, area.height), {size: size, fallback: "Right"});
        addButton("wheel", "滚轮", new Rectangle(area.x + (buttonWidth + gap) * 2, area.y, buttonWidth, area.height), {size: size, fallback: "Wheel"});
        buildSlider(new Rectangle(area.right - sliderWidth, area.y, sliderWidth, area.height));
    }

    function buildSlider(area:Rectangle):Void
    {
        final control = addControl("sensitivity", area);
        drawButtonSkin(control);
        final font = Math.min(14, area.height * 0.38);
        final titleWidth = Math.min(66, area.width * 0.52);
        addLabel(control.view, "灵敏度", new Rectangle(0, 0, titleWidth, area.height), {size: font, color: SUBTLE_TEXT, fallback: "Sensitivity"});
        sliderTrack = new Rectangle(area.x + titleWidth + 1, area.y + area.height * 0.5 - 2,
            Math.max(1, area.width - titleWidth - 12), 4);
        slider = new Shape();
        addChild(slider);
        drawSlider();
    }

    function drawSlider():Void
    {
        final track = sliderTrack;
        final ink = slider.graphics;
        ink.clear();
        ink.beginFill(0x777777, 0.72);
        ink.drawRoundRect(track.x, track.y, track.width, track.height, track.height);
        ink.endFill();

        final knobX = track.x + track.width * sensitivity;
        final knobY = track.y + track.height * 0.5;
        ink.beginFill(0x454545);
        ink.drawCircle(knobX, knobY, 5.5);
        ink.endFill();
    }

    function drawKeyboard(area:Rectangle, gap:Float):Void
    {
        final spacing = Math.max(2, gap * 0.57);
        final rowPadding = spacing + 2;
        final rowHeight = (area.height - rowPadding * 2 - spacing * (VirtualPointerKeyboard.rows.length - 1)) / VirtualPointerKeyboard.rows.length;
        if (rowHeight <= 1) return;
        var rowY = area.y + rowPadding;
        for (row in VirtualPointerKeyboard.rows)
        {
            var units:Float = 0;
            for (key in row) units += key.weight;
            final unitWidth = (area.width - rowPadding * 2 - spacing * (row.length - 1)) / units;
            var keyX = area.x + rowPadding;
            for (key in row)
            {
                final keyWidth = key.weight * unitWidth;
                final size = Math.min(17, Math.min(rowHeight * 0.55, keyWidth / Math.max(1.4, key.label.length * 0.64)));
                addButton(key.action, key.label, new Rectangle(keyX, rowY, keyWidth, rowHeight), {size: size});
                keyX += keyWidth + spacing;
            }
            rowY += rowHeight + spacing;
        }
    }

    function addButton(action:String, label:String, area:Rectangle, style:PointerLabelStyle):Void
    {
        final control = addControl(action, area);
        drawButtonSkin(control);
        addLabel(control.view, label, new Rectangle(0, 0, area.width, area.height), style);
    }

    function addControl(action:String, area:Rectangle):PointerPanelControl
    {
        final view = new Sprite();
        view.mouseEnabled = false;
        view.mouseChildren = false;
        view.x = area.x;
        view.y = area.y;
        addChild(view);
        final control = {action: action, bounds: area, view: view, pressed: false};
        controls.push(control);
        controlsByAction.set(action, control);
        return control;
    }

    function drawButtonSkin(control:PointerPanelControl):Void
    {
        final area = control.bounds;
        final ink = control.view.graphics;
        ink.clear();
        ink.beginFill(control.pressed ? 0xB0B0B0 : 0xE8E8E8, control.pressed ? 0.75 : 0.64);
        ink.drawRoundRect(0, 0, area.width, area.height, 8);
        ink.endFill();
    }

    function addLabel(target:Sprite, label:String, area:Rectangle, style:PointerLabelStyle):Void
    {
        final localizedFont = style.fallback == null ? null : getLabelFont();
        final visibleLabel = localizedFont != null ? label : style.fallback ?? label;
        final text = new TextField();
        final fontSize = Std.int(Math.max(5, style.size));
        final format = new TextFormat(localizedFont ?? "_sans", fontSize, style.color ?? TEXT, false, null, null, null, null,
            TextFormatAlign.CENTER);
        text.defaultTextFormat = format;
        text.embedFonts = localizedFont != null;
        text.selectable = false;
        text.mouseEnabled = false;
        text.width = Math.max(1, area.width);
        text.height = Math.max(1, area.height);
        text.x = area.x;
        text.text = visibleLabel;
        final availableWidth = text.width - 5;
        if (availableWidth > 0 && text.textWidth > availableWidth)
        {
            format.size = Std.int(Math.max(5, fontSize * availableWidth / text.textWidth));
            text.setTextFormat(format);
        }
        text.y = area.y + Math.max(0, (area.height - text.textHeight) * 0.5 - 2);
        target.addChild(text);
    }

    function getLabelFont():Null<String>
    {
        if (triedLabelFont) return labelFont;
        triedLabelFont = true;
        final asset = "assets/fonts/Lang-ZH.ttf";
        // Origin can replace the default manifest. The packaged font still has a file path there.
        final font = Assets.exists(asset, AssetType.FONT) ? Assets.getFont(asset) : Font.fromFile(asset);
        if (font != null && font.fontName != null && font.fontName != "")
        {
            Font.registerFont(font);
            labelFont = font.fontName;
        }
        return labelFont;
    }

    static inline function clamp(value:Float, min:Float, max:Float):Float
        return Math.max(min, Math.min(max, value));
}

private typedef PointerPanelControl =
{
    var action:String;
    var bounds:Rectangle;
    var view:Sprite;
    var pressed:Bool;
}

private typedef PointerLabelStyle =
{
    final size:Float;
    @:optional final color:Int;
    @:optional final fallback:String;
}
#end
