package general.backend;

import openfl.utils.Assets;

import flixel.util.FlxGradient;
import flixel.FlxSubState;
import flixel.FlxObject;

import states.mainMenuState.MainMenuState;

class CustomFadeTransition extends FlxSubState
{
	public static var finishCallback:Void->Void;

	/**
	 * trans-out 的 tween 完成时统一从这里出去：先把回调取出来、立刻清空，再调用。
	 *
	 * `finishCallback` 是 static，旧实现从不清空 —— 一次会话里只要出现过任何一次
	 * resetState / switchState（Restart、换难度、退出、进编辑器…），这个静态回调就一直
	 * 挂在那儿；之后再出现任何一个 trans-out（包括 mod 脚本自己 new 的），它的 tween
	 * 一完成就会再触发一次旧的 `FlxG.resetState()` / `switchState()`，玩家看到的就是
	 * 「谱面被整个重建、从头重放」。这里按"一次性回调"的本义处理，顺带避免同一条
	 * 过场的四条 tween 各调一次（旧实现在同一帧里会连调 4 次）。
	 */
	public static function callFinishCallback():Void
	{
		var callback:Void->Void = finishCallback;
		finishCallback = null;
		if (callback != null)
			callback();
	}

	private var leTween:FlxTween = null;

	public static var nextCamera:FlxCamera;

	var isTransIn:Bool = false;
	var duration:Float;

	var loadLeft:FlxSprite;
	var loadRight:FlxSprite;
	var loadAlpha:FlxSprite;
	var WaterMark:FlxText;
	var EventText:FlxText;

	var loadLeftTween:FlxTween;
	var loadRightTween:FlxTween;
	var loadAlphaTween:FlxTween;
	var EventTextTween:FlxTween;
	var loadTextTween:FlxTween;

	public function new(duration:Float, isTransIn:Bool)
	{
		this.isTransIn = isTransIn;
		this.duration = duration;

		super();
	}

	override function create()
	{
		var cam:FlxCamera = new FlxCamera();
		cam.bgColor = 0x00;
		FlxG.cameras.add(cam, false);

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if (ClientPrefs.data.customFade == 'Move')
		{
			loadRight = new FlxSprite(isTransIn ? 0 : 1280, 0).loadGraphic(Paths.image('menuExtend/CustomFadeTransition/loadingR'));
			loadRight.scrollFactor.set();
			loadRight.antialiasing = ClientPrefs.data.antialiasing;
			add(loadRight);
			loadRight.setGraphicSize(FlxG.width, FlxG.height);
			loadRight.updateHitbox();

			loadLeft = new FlxSprite(isTransIn ? 0 : -1280, 0).loadGraphic(Paths.image('menuExtend/CustomFadeTransition/loadingL'));
			loadLeft.scrollFactor.set();
			loadLeft.antialiasing = ClientPrefs.data.antialiasing;
			add(loadLeft);
			loadLeft.setGraphicSize(FlxG.width, FlxG.height);
			loadLeft.updateHitbox();

			WaterMark = new FlxText(isTransIn ? 50 : -1230, 720 - 50 - 50 * 2, 0, 'NF ENGINE V' + MainMenuState.novaFlareEngineVersion, 50);
			WaterMark.scrollFactor.set();
			WaterMark.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			WaterMark.antialiasing = ClientPrefs.data.antialiasing;
			add(WaterMark);

			EventText = new FlxText(isTransIn ? 50 : -1230, 720 - 50 - 50, 0, 'LOADING . . . . . . ', 50);
			EventText.scrollFactor.set();
			EventText.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			EventText.antialiasing = ClientPrefs.data.antialiasing;
			add(EventText);

			if (!isTransIn)
			{
				try
				{
					FlxG.sound.play(Paths.sound('loading_close_move'), ClientPrefs.data.customFadeSound);
				}
				if (!ClientPrefs.data.customFadeText)
				{
					EventText.text = '';
					WaterMark.text = '';
				}
				loadLeftTween = FlxTween.tween(loadLeft, {x: 0}, duration, {
					onComplete: function(twn:FlxTween)
					{
						callFinishCallback();
					},
					ease: FlxEase.expoInOut
				});

				loadRightTween = FlxTween.tween(loadRight, {x: 0}, duration, {
					onComplete: function(twn:FlxTween)
					{
						callFinishCallback();
					},
					ease: FlxEase.expoInOut
				});

				loadTextTween = FlxTween.tween(WaterMark, {x: 50}, duration, {
					onComplete: function(twn:FlxTween)
					{
						callFinishCallback();
					},
					ease: FlxEase.expoInOut
				});

				EventTextTween = FlxTween.tween(EventText, {x: 50}, duration, {
					onComplete: function(twn:FlxTween)
					{
						callFinishCallback();
					},
					ease: FlxEase.expoInOut
				});
			}
			else
			{
				try
				{
					FlxG.sound.play(Paths.sound('loading_open_move'), ClientPrefs.data.customFadeSound);
				}
				EventText.text = 'COMPLETED !';
				if (!ClientPrefs.data.customFadeText)
				{
					EventText.text = '';
					WaterMark.text = '';
				}
				loadLeftTween = FlxTween.tween(loadLeft, {x: -1280}, duration, {
					onComplete: function(twn:FlxTween)
					{
						close();
					},
					ease: FlxEase.expoInOut
				});

				loadRightTween = FlxTween.tween(loadRight, {x: 1280}, duration, {
					onComplete: function(twn:FlxTween)
					{
						close();
					},
					ease: FlxEase.expoInOut
				});

				loadTextTween = FlxTween.tween(WaterMark, {x: -1230}, duration, {
					onComplete: function(twn:FlxTween)
					{
						close();
					},
					ease: FlxEase.expoInOut
				});

				EventTextTween = FlxTween.tween(EventText, {x: -1230}, duration, {
					onComplete: function(twn:FlxTween)
					{
						close();
					},
					ease: FlxEase.expoInOut
				});
			}
		}
		else
		{
			loadAlpha = new FlxSprite(0, 0).loadGraphic(Paths.image('menuExtend/CustomFadeTransition/loadingAlpha'));
			loadAlpha.scrollFactor.set();
			loadAlpha.antialiasing = ClientPrefs.data.antialiasing;
			add(loadAlpha);
			loadAlpha.setGraphicSize(FlxG.width, FlxG.height);
			loadAlpha.updateHitbox();

			WaterMark = new FlxText(50, 720 - 50 - 50 * 2, 0, 'NF ENGINE V' + MainMenuState.novaFlareEngineVersion, 50);
			WaterMark.scrollFactor.set();
			WaterMark.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			WaterMark.antialiasing = ClientPrefs.data.antialiasing;
			add(WaterMark);

			EventText = new FlxText(50, 720 - 50 - 50, 0, 'LOADING . . . . . . ', 50);
			EventText.scrollFactor.set();
			EventText.setFormat(Assets.getFont("assets/fonts/loadText.ttf").fontName, 50, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			EventText.antialiasing = ClientPrefs.data.antialiasing;
			add(EventText);

			if (!isTransIn)
			{
				try
				{
					FlxG.sound.play(Paths.sound('loading_close_alpha'), ClientPrefs.data.customFadeSound);
				}
				if (!ClientPrefs.data.customFadeText)
				{
					EventText.text = '';
					WaterMark.text = '';
				}
				WaterMark.alpha = 0;
				EventText.alpha = 0;
				loadAlpha.alpha = 0;
				loadAlphaTween = FlxTween.tween(loadAlpha, {alpha: 1}, duration, {
					onComplete: function(twn:FlxTween)
					{
						callFinishCallback();
					},
					ease: FlxEase.sineInOut
				});

				loadTextTween = FlxTween.tween(WaterMark, {alpha: 1}, duration, {
					onComplete: function(twn:FlxTween)
					{
						callFinishCallback();
					},
					ease: FlxEase.sineInOut
				});

				EventTextTween = FlxTween.tween(EventText, {alpha: 1}, duration, {
					onComplete: function(twn:FlxTween)
					{
						callFinishCallback();
					},
					ease: FlxEase.sineInOut
				});
			}
			else
			{
				try
				{
					FlxG.sound.play(Paths.sound('loading_open_alpha'), ClientPrefs.data.customFadeSound);
				}
				EventText.text = 'COMPLETED !';
				if (!ClientPrefs.data.customFadeText)
				{
					EventText.text = '';
					WaterMark.text = '';
				}
				loadAlphaTween = FlxTween.tween(loadAlpha, {alpha: 0}, duration, {
					onComplete: function(twn:FlxTween)
					{
						close();
					},
					ease: FlxEase.sineInOut
				});

				loadTextTween = FlxTween.tween(WaterMark, {alpha: 0}, duration, {
					onComplete: function(twn:FlxTween)
					{
						close();
					},
					ease: FlxEase.sineInOut
				});

				EventTextTween = FlxTween.tween(EventText, {alpha: 0}, duration, {
					onComplete: function(twn:FlxTween)
					{
						close();
					},
					ease: FlxEase.sineInOut
				});
			}
		}

		super.create();
	}
}
