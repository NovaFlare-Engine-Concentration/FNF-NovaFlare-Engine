package general.objects.state.general;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;

class ChangeSprite extends FlxSpriteGroup //背景切换
{
	var bg1:MoveSprite;
	var bg2:MoveSprite;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);

        bg1 = new MoveSprite(0, 0);
        bg1.antialiasing = ClientPrefs.data.antialiasing;

		bg2 = new MoveSprite(0, 0);
        bg2.antialiasing = ClientPrefs.data.antialiasing;

		add(bg2);

        add(bg1);

        moves = false;
	}

    public function load(graphic:FlxGraphicAsset, scaleValue:Float = 1.05) {
        bg1.load(graphic, scaleValue);
        bg2.load(graphic, scaleValue);
        // bg2 is only the cross-fade target. Keeping it visible after a
        // transition wastes a full-screen draw and made shader backgrounds
        // render the same texture twice forever.
        bg2.visible = false;
        return this;
    }

    public function setShader(shader:flixel.system.FlxAssets.FlxShader):Void {
        bg1.shader = shader;
        bg2.shader = shader;
    }

	public function setAllowMove(value:Bool):Void {
		bg1.setAllowMove(value);
		bg2.setAllowMove(value);
	}

	var mainTween:FlxTween;
	var fixTween:FlxTween;
	var lastLoadGraphic:Dynamic;
	var pendingGraphic:FlxGraphic;
	public function changeSprite(graphic:Dynamic, time:Float = 0.6) {
		if (lastLoadGraphic == graphic) return;
		lastLoadGraphic = graphic;

		if (mainTween != null || fixTween != null) {
			if (mainTween != null) {
				mainTween.cancel();
				mainTween = null;
			}
			if (fixTween != null) {
				fixTween.cancel();
				fixTween = null;
			}

			retainPendingGraphic(graphic);
			fixTween = FlxTween.tween(bg1, {alpha: 1}, time / 2, {
				ease: FlxEase.linear,
				onComplete: function(twn:FlxTween)
				{
					fixTween = null;
					updateGraphic(bg2, graphic);
					bg2.syncViewFrom(bg1);
					releasePendingGraphic();
					bg2.alpha = 1;
					bg2.visible = true;
					mainTween = FlxTween.tween(bg1, {alpha: 0}, time, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							updateGraphic(bg1, graphic);
							bg1.syncViewFrom(bg2);
							bg1.alpha = 1;
							bg2.visible = false;
							mainTween = null;
						}
					});
				}
			});

			return;
		}

		updateGraphic(bg2, graphic);
		bg2.syncViewFrom(bg1);
		bg2.alpha = 1;
		bg2.visible = true;
		mainTween = FlxTween.tween(bg1, {alpha: 0}, time, {
			ease: FlxEase.linear,
			onComplete: function(twn:FlxTween)
			{
				updateGraphic(bg1, graphic);
				bg1.syncViewFrom(bg2);
				bg1.alpha = 1;
				bg2.visible = false;
				mainTween = null;
			}
		});
	}

	private function updateGraphic(bg:MoveSprite, graphic:Dynamic) {
		if ((graphic is FlxFramesCollection))
			bg.frames = graphic;
		else
			bg.loadGraphic(graphic, false, 0, 0, false, null);

		bg.updateSize();
	}

	private function retainPendingGraphic(graphic:Dynamic):Void {
		releasePendingGraphic();
		if (graphic is FlxFramesCollection) {
			pendingGraphic = cast(graphic, FlxFramesCollection).parent;
			if (pendingGraphic != null)
				pendingGraphic.incrementUseCount();
		}
	}

	private function releasePendingGraphic():Void {
		if (pendingGraphic != null) {
			var graphic:FlxGraphic = pendingGraphic;
			pendingGraphic = null;
			graphic.decrementUseCount();
		}
	}

    public function changeColor(color:Int, time:Float = 0.6) {
        bg1.changeColor(color, time);
        bg2.changeColor(color, time);
    }

	override function destroy():Void {
		if (mainTween != null) {
			mainTween.cancel();
			mainTween = null;
		}
		if (fixTween != null) {
			fixTween.cancel();
			fixTween = null;
		}
		releasePendingGraphic();
		lastLoadGraphic = null;
		super.destroy();
	}
}
