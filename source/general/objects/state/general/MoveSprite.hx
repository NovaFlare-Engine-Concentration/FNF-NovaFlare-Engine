package general.objects.state.general;

import flixel.system.FlxAssets.FlxGraphicAsset;

class MoveSprite extends FlxSprite{

	public var bgFollowSmooth:Float = 15;

    public var allowMove:Bool = true;

    public function new(X:Float = 0, Y:Float = 0) {
        super(X, Y);
        moves = false;
    }

	private var realWidth:Float;
	private var realHeight:Float;
	private var scaleValue:Float = 1.05;
    public function load(graphic:FlxGraphicAsset, scaleValue:Float = 1.05) {
        this.loadGraphic(graphic, false, 0, 0, false);
		this.scaleValue = scaleValue;
        updateSize();
    }

	public function updateSize() {
		var scale = Math.max(FlxG.width * scaleValue / this.width, FlxG.height * scaleValue / this.height);
		realWidth = this.width * scale;
		realHeight = this.height * scale;
		this.scale.x = this.scale.y = scale;
		this.offset.x = this.offset.y = 0;
        updateHitbox();
		if (!allowMove) centerWithoutParallax();
    }

	public function setAllowMove(value:Bool):Void {
		allowMove = value;
		if (!value && realWidth > 0 && realHeight > 0)
			centerWithoutParallax();
	}

	private inline function centerWithoutParallax():Void {
		offsetX = 0;
		offsetY = 0;
		this.x = (FlxG.width - realWidth) * 0.5;
		this.y = (FlxG.height - realHeight) * 0.5;
	}

	/**
	 * Copies the visible layer's parallax progress when a hidden cross-fade
	 * layer is activated. Hidden sprites do not draw and therefore do not
	 * advance their offsets, so exposing one without this sync produces a
	 * one-frame background jump.
	 */
	public function syncViewFrom(source:MoveSprite):Void {
		if (!allowMove) {
			centerWithoutParallax();
			return;
		}

		var sourceRangeX:Float = Math.max(0, (source.realWidth - FlxG.width) * 0.5);
		var sourceRangeY:Float = Math.max(0, (source.realHeight - FlxG.height) * 0.5);
		var targetRangeX:Float = Math.max(0, (realWidth - FlxG.width) * 0.5);
		var targetRangeY:Float = Math.max(0, (realHeight - FlxG.height) * 0.5);
		offsetX = sourceRangeX > 0 ? source.offsetX / sourceRangeX * targetRangeX : 0;
		offsetY = sourceRangeY > 0 ? source.offsetY / sourceRangeY * targetRangeY : 0;
		applyParallaxPosition();
	}

	private inline function applyParallaxPosition():Void {
		this.x = FlxG.width * 0.5 - realWidth * 0.5 + offsetX;
		this.y = FlxG.height * 0.5 - realHeight * 0.5 + offsetY;
	}
    
	private var offsetX:Float = 0;
    private var offsetY:Float = 0;
    override function draw()
    {
        if (allowMove) {
            var centerX = FlxG.width * 0.5;
            var centerY = FlxG.height * 0.5;
            
            var targetOffsetX = FlxMath.bound((FlxG.mouse.x - centerX) / centerX, -0.99, 0.99) * (realWidth - FlxG.width) * 0.5;
            var targetOffsetY = FlxMath.bound((FlxG.mouse.y - centerY) / centerY, -0.99, 0.99) * (realHeight - FlxG.height) * 0.5;
            
            var lerpFactor = Math.exp(-FlxG.drawElapsed * bgFollowSmooth);

            if (Math.abs(offsetX - targetOffsetX) > 0.5) offsetX = FlxMath.lerp(targetOffsetX, offsetX, lerpFactor);
            else offsetX = targetOffsetX;
            if (Math.abs(offsetY - targetOffsetY) > 0.5) offsetY = FlxMath.lerp(targetOffsetY, offsetY, lerpFactor);
            else offsetY = targetOffsetY;

            applyParallaxPosition();
        }

        super.draw();
    }
    
    var colorTween:FlxTween = null;
	public function changeColor(color:Int, time:Float = 0.6) {
		if (colorTween != null) colorTween.cancel();
        var sr = this.color;
        var er = color;
        var startRGB:FlxColor = FlxColor.fromRGB((sr >> 16) & 0xFF, (sr >> 8) & 0xFF, sr & 0xFF);
        var endRGB:FlxColor = FlxColor.fromRGB((er >> 16) & 0xFF, (er >> 8) & 0xFF, er & 0xFF);

        colorTween = FlxTween.num(0, 1, time, null, function(v:Float) {
            this.color = FlxColor.interpolate(startRGB, endRGB, v);
        });
	}
}
