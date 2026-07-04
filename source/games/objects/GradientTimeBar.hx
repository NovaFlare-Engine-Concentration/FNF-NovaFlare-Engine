package games.objects;

import flixel.FlxSprite;
import flixel.math.FlxRect;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class GradientTimeBar extends Bar
{
    public var leftColor:FlxColor = FlxColor.RED;
    public var rightColor:FlxColor = FlxColor.BLUE;
    
    public function new(x:Float, y:Float, image:String = 'timeBar', valueFunc:Void->Float = null, boundX:Float = 0, boundY:Float = 1)
    {
        super(x, y, image, valueFunc, boundX, boundY);
        
        // 移除原有的leftBar，用渐变条替代
        if(leftBar != null) {
            remove(leftBar);
            leftBar.destroy();
            leftBar = null;
        }
        
        // 创建渐变条
        createGradientBar();
        
        // 重新生成剪辑区域
        regenerateClips();
    }
    
    function createGradientBar() {
        // 使用父类的barWidth和barHeight
        var gradientBitmap:BitmapData = createGradientBitmap(barWidth, barHeight, leftColor, rightColor);
        leftBar = new FlxSprite().loadGraphic(gradientBitmap);
        leftBar.antialiasing = ClientPrefs.data.antialiasing;
        
        // 将渐变条添加到组中
        add(leftBar);
    }
    
    function createGradientBitmap(width:Int, height:Int, startColor:FlxColor, endColor:FlxColor):BitmapData {
        var bitmap:BitmapData = new BitmapData(width, height, true, 0x00000000);
        
        var segments:Int = 100;
        for (i in 0...segments) {
            var ratio:Float = i / (segments - 1);
            var currentColor:FlxColor = FlxColor.interpolate(startColor, endColor, ratio);
            
            var segmentWidth:Int = Math.ceil(width / segments);
            var xPos:Int = Math.floor(i * (width / segments));
            var segmentRect:Rectangle = new Rectangle(xPos, 0, segmentWidth, height);
            
            bitmap.fillRect(segmentRect, currentColor);
        }
        
        return bitmap;
    }
    
    public function updateGradientColors(newLeftColor:FlxColor, newRightColor:FlxColor) {
        if (leftColor == newLeftColor && rightColor == newRightColor) return;
        
        leftColor = newLeftColor;
        rightColor = newRightColor;
        
        // 重新创建渐变条
        if(leftBar != null) {
            remove(leftBar);
            leftBar.destroy();
        }
        createGradientBar();
        regenerateClips();
    }
    
    // 重写setColors方法以支持渐变
    override public function setColors(left:FlxColor = null, right:FlxColor = null) {
        if (left != null) {
            // 对于渐变条，我们更新整个渐变
            updateGradientColors(left, right != null ? right : this.rightColor);
        }
        if (right != null) {
            rightBar.color = right;
        }
    }
}