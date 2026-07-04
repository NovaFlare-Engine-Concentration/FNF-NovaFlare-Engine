package games.objects;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import states.PlayState;

class HealthText extends FlxText {
    public var state:PlayState;

    public function new(state:PlayState) {
        super(0, 0, 300, "", 30);
        this.state = state;
        this.setFormat(Paths.font("vcr.ttf"), 30, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
        this.scrollFactor.set();
        this.borderSize = 1.25;
        this.visible = !ClientPrefs.data.hideHud && ClientPrefs.data.healthText;
        state.uiGroup.add(this);
        refresh();
    }

    // 使用自定义方法名以避免覆盖 FlxText.update(elapsed)
    public function refresh():Void {
        if(state.isSplitCoopMode())
        {
        this.text = "Health: " + Math.floor(state.opponentHealth * 50) + " / " + Math.floor(state.playerHealth * 50);
        }
        else
        {
            this.text = "Health: " + Math.floor(state.health * 50);
        }
        var textWidth:Int = 300;
        if (ClientPrefs.data.downScroll) {
            this.x = FlxG.width / 2 - textWidth / 2;
            this.y = FlxG.height - this.height - 150;
        } else {
            this.x = FlxG.width / 2 - textWidth / 2;
            this.y = 150;
        }
        if (state != null && state.boyfriend != null && state.boyfriend.healthColorArray != null) {
            this.color = FlxColor.fromRGB(state.boyfriend.healthColorArray[0], state.boyfriend.healthColorArray[1], state.boyfriend.healthColorArray[2]);
        }
    }
}
