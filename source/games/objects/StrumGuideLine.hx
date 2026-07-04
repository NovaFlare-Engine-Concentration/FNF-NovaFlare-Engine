package games.objects;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxG;
import flixel.util.FlxColor;

import games.PlayState;

class StrumGuideLine extends FlxTypedSpriteGroup<FlxSprite>
{
    // 4个黑条，对应4列（玩家侧）
    var playerLines:Array<FlxSprite> = [];
    // 对手侧黑条（用于双人模式）
    var opponentLines:Array<FlxSprite> = [];
    
    public function new()
    {
        super(0, 0);
        
        // 创建玩家侧的4个黑条
        for (i in 0...4)
        {
            var line = new FlxSprite();
            line.makeGraphic(115, FlxG.height, FlxColor.BLACK);
            line.alpha = ClientPrefs.data.guideLineAlpha;
            line.visible = false;
            playerLines.push(line);
            add(line);
        }
        
        // 创建对手侧的4个黑条（预创建，根据需要显示）
        for (i in 0...4)
        {
            var line = new FlxSprite();
            line.makeGraphic(115, FlxG.height, FlxColor.BLACK);
            line.alpha = ClientPrefs.data.guideLineAlpha;
            line.visible = false;
            opponentLines.push(line);
            add(line);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var playState = PlayState.instance;
        if (playState == null) return;
        
        var isCoopMode:Bool = false; // 目前没有明确的 coopMode 标志，暂时设为 false
        var isOpponentMode:Bool = ClientPrefs.data.playOpponent;
        
        // 更新玩家侧黑条（始终显示，但对手模式下可能隐藏或不同行为）
        for (i in 0...playerLines.length)
        {
            var strum = playState.playerStrums.members[i];
            var shouldShow:Bool = (strum != null && strum.visible);
            
            // 对手模式下，玩家侧轨道不显示（因为玩家控制对手侧）
            if (isOpponentMode)
                shouldShow = false;
            
            if (shouldShow)
            {
                var line = playerLines[i];
                line.x = strum.x + (strum.width / 2) - (line.width / 2);
                line.y = 0;
                line.alpha = ClientPrefs.data.guideLineAlpha;
                line.visible = (line.alpha > 0);
            }
            else
            {
                playerLines[i].visible = false;
            }
        }
        
        // 更新对手侧黑条（双人模式或对手模式下显示）
        for (i in 0...opponentLines.length)
        {
            var strum = playState.opponentStrums.members[i];
            var shouldShow:Bool = (strum != null && strum.visible);
            
            // 普通模式下，对手侧轨道不显示
            if (!isCoopMode && !isOpponentMode)
                shouldShow = false;
            
            if (shouldShow)
            {
                var line = opponentLines[i];
                line.x = strum.x + (strum.width / 2) - (line.width / 2);
                line.y = 0;
                line.alpha = ClientPrefs.data.guideLineAlpha;
                line.visible = (line.alpha > 0);
            }
            else
            {
                opponentLines[i].visible = false;
            }
        }
    }
    
    /**
     * 更新透明度
     */
    public function updateAlpha()
    {
        for (line in playerLines)
        {
            line.alpha = ClientPrefs.data.guideLineAlpha;
            line.visible = (line.alpha > 0);
        }
        for (line in opponentLines)
        {
            line.alpha = ClientPrefs.data.guideLineAlpha;
            line.visible = (line.alpha > 0);
        }
    }
    
    override public function destroy():Void
    {
        playerLines = null;
        opponentLines = null;
        super.destroy();
    }
}