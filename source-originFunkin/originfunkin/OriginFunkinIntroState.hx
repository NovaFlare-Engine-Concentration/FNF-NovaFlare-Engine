package originfunkin;

import flixel.FlxG;
import flixel.FlxState;
import flixel.input.gamepad.FlxGamepad;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.utils.Assets;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

class OriginFunkinIntroState extends FlxState
{
	var finished:Bool = false;
	var skipText:FlxText;

	#if VIDEOS_ALLOWED
	var video:FlxVideoSprite;
	#end

	override public function create():Void
	{
		super.create();

		FlxG.camera.bgColor = FlxColor.BLACK;
		FlxG.mouse.visible = false;

		// Let Main finish hxvlc initialization before constructing the player.
		new FlxTimer().start(0, function(_):Void
		{
			startIntro();
		});
	}

	function startIntro():Void
	{
		#if VIDEOS_ALLOWED
		var videoPath:String = OriginFunkinMode.novaFlareIntroVideoPath;
		if (videoPath == null || videoPath.length == 0)
		{
			finishIntro();
			return;
		}

		video = new FlxVideoSprite(0, 0);
		video.antialiasing = true;
		video.bitmap.onFormatSetup.add(function():Void
		{
			if (video == null || video.bitmap == null || video.bitmap.bitmapData == null)
			{
				return;
			}

			var scale:Float = Math.min(
				FlxG.width / video.bitmap.bitmapData.width,
				FlxG.height / video.bitmap.bitmapData.height);
			video.setGraphicSize(
				Std.int(video.bitmap.bitmapData.width * scale),
				Std.int(video.bitmap.bitmapData.height * scale));
			video.updateHitbox();
			video.screenCenter();
		});
		video.bitmap.onEndReached.add(finishIntro);
		add(video);
		video.load(videoPath);
		video.play();
		skipText = new FlxText(0, FlxG.height - 32, FlxG.width, "Press Enter to skip", 18);

		skipText.setFormat(null, 18, FlxColor.WHITE, CENTER);
		skipText.alpha = 0;
		skipText.scrollFactor.set();
		add(skipText);
		FlxTween.tween(skipText, {alpha: 1}, 1, {ease: FlxEase.quadIn});
		FlxTween.tween(skipText, {alpha: 0}, 1, {ease: FlxEase.quadIn, startDelay: 4});
		#else
		finishIntro();
		#end
	}

	override public function update(elapsed:Float):Void
	{
		if (!finished && shouldSkip())
		{
			finishIntro();
			return;
		}

		super.update(elapsed);
	}

	function shouldSkip():Bool
	{
		if (FlxG.keys.justPressed.ENTER)
		{
			return true;
		}

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null && gamepad.justPressed.START)
		{
			return true;
		}

		#if android
		if (FlxG.android.justReleased.BACK)
		{
			return true;
		}
		#end

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				return true;
			}
		}
		#end

		return false;
	}

	function finishIntro():Void
	{
		if (finished)
		{
			return;
		}
		finished = true;

		#if VIDEOS_ALLOWED
		if (video != null)
		{
			video.bitmap.onEndReached.remove(finishIntro);
			video.stop();
			remove(video, true);
			video.destroy();
			video = null;
		}
		#end

		if (OriginFunkinMode.preparationError != null)
		{
			FlxG.switchState(new OriginFunkinErrorState());
		}
		else if (!OriginFunkinConfig.originNoticeAcknowledged)
		{
			OriginFunkinDialog.showOriginNotice(function():Void
			{
				if (FlxG.state != this)
				return;

				OriginFunkinConfig.acknowledgeOriginNotice();
				FlxG.switchState(new funkin.InitState());
			});
		}
		else
		{
			FlxG.switchState(new funkin.InitState());
		}
	}
}
