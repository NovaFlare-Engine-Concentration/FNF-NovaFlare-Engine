package games.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

class DraggableBar extends Bar
{
    public var onValueChanged:Float->Void = null;
    public var isDragging(default, null):Bool = false;
    public var draggable:Bool = true;
    public var jumpOnClick:Bool = true;
    
    public var valueText:FlxText = null;
    
    var dragStartPercent:Float = 0;
    var dragStartMouseX:Float = 0;
    var dragStartMouseScreenX:Float = 0;
    
    public function new(x:Float, y:Float, image:String = 'healthBar', valueFunction:Void->Float = null, boundX:Float = 0, boundY:Float = 1)
    {
        super(x, y, image, valueFunction, boundX, boundY);
//        bg.useHandCursor = true;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!draggable) return;
        
        var mouseOverBg = FlxG.mouse.overlaps(bg, FlxG.camera);
        
        // 开始拖拽
        if (FlxG.mouse.justPressed && mouseOverBg && !isDragging)
        {
            isDragging = true;
            dragStartPercent = percent;
            dragStartMouseScreenX = FlxG.mouse.screenX;
            
            // 获取当前鼠标在相机中的位置作为起始点
            var mouseCamPos = FlxG.mouse.getPositionInCameraView(cameras[0]);
            if (mouseCamPos != null)
            {
                var bgCamPos = bg.getScreenPosition(cameras[0]);
                dragStartMouseX = mouseCamPos.x - bgCamPos.x - barOffset.x;
            }
            
            leftBar.alpha = 0.7;
            rightBar.alpha = 0.7;
        }
        
        // 拖拽中
        if (isDragging && FlxG.mouse.pressed)
        {
            var mouseCamPos = FlxG.mouse.getPositionInCameraView(cameras[0]);
            if (mouseCamPos != null)
            {
                var bgCamPos = bg.getScreenPosition(cameras[0]);
                var currentMouseX = mouseCamPos.x - bgCamPos.x - barOffset.x;
                
                // 方法1: 基于起始点的相对移动
                var deltaX = currentMouseX - dragStartMouseX;
                var newPercent = dragStartPercent + (deltaX / barWidth) * 100;
                newPercent = Math.max(0, Math.min(100, newPercent));
                
                if (newPercent != percent)
                {
                    percent = newPercent;
                    updateBar();
                    
                    if (onValueChanged != null)
                    {
                        onValueChanged(percent);
                    }
                }
            }
        }
        
        // 结束拖拽
        if (FlxG.mouse.justReleased && isDragging)
        {
            isDragging = false;
            leftBar.alpha = 1;
            rightBar.alpha = 1;
        }
        
        // 点击跳转（按下并释放，且没有拖拽过）
        if (FlxG.mouse.justReleased && !isDragging && jumpOnClick && mouseOverBg)
        {
            var mouseCamPos = FlxG.mouse.getPositionInCameraView(cameras[0]);
            if (mouseCamPos != null)
            {
                var bgCamPos = bg.getScreenPosition(cameras[0]);
                var relativeX = mouseCamPos.x - bgCamPos.x - barOffset.x;
                var clickPercent = (relativeX / barWidth) * 100;
                clickPercent = Math.max(0, Math.min(100, clickPercent));
                
                if (clickPercent != percent)
                {
                    percent = clickPercent;
                    updateBar();
                    
                    if (onValueChanged != null)
                    {
                        onValueChanged(percent);
                    }
                }
                
                // 视觉反馈
                leftBar.alpha = 0.5;
                rightBar.alpha = 0.5;
                new FlxTimer().start(0.1, function(_) {
                    if (!isDragging) {
                        leftBar.alpha = 1;
                        rightBar.alpha = 1;
                    }
                });
            }
        }
        
        // 更新数值显示
        if (valueText != null)
        {
            valueText.text = Math.round(percent) + "%";
            valueText.x = x;
            valueText.y = y - 25;
        }
    }
    
    public function setPercent(value:Float, triggerCallback:Bool = true):Void
    {
        var newPercent = Math.max(0, Math.min(100, value));
        if (newPercent == percent) return;
        
        percent = newPercent;
        updateBar();
        
        if (triggerCallback && onValueChanged != null)
        {
            onValueChanged(percent);
        }
    }
    
    override public function destroy():Void
    {
        if (valueText != null) valueText.destroy();
        super.destroy();
    }
}