package options.base;

import flixel.FlxSubState;
import flixel.input.FlxPointer;
import flixel.util.FlxAxes;

import states.freeplayState.FreeplayState;
import states.mainMenuState.MainMenuState;
import lime.system.System as LimeSystem;

class SelectGameSubState extends MusicBeatSubstate
{
    var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuExtend/LoadingState/loadScreen'));
	var ui:FlxSprite = new FlxSprite().makeGraphic(FlxG.width - 200, FlxG.height - 200, 0xFF000000);
    var subcameras:FlxCamera;

	var suppostedGames:Array<String> = #if CODENAME_ENGINE_COMPAT ["Origin Funkin", "CodeName Engine"] #else ["Origin Funkin"] #end;
	var selectedGroup:FlxSpriteGroup = new FlxSpriteGroup();
	var backButton:GeneralBack;

	var nowSelected:Int = 0;

	var infoBG1:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuExtend/SelectGameSubState/originFunkin'));
	var infoBG2:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuExtend/SelectGameSubState/Codename'));

	var transitioning:Bool = false;
	var zoomTween:FlxTween;
	var blackTween:FlxTween;
	var flashTween:FlxTween;
	var volumeTween:FlxTween;
	var transitionStartVolume:Float = 1;
	var switchAccepted:Bool = false;

	var blackScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
	var flashScreen:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);

	public function new()
	{
		super();
	}

	override function create()
	{
		super.create();
		FlxG.state.persistentUpdate = false;
		subcameras = new FlxCamera();

        var maxScale:Float = Math.max(FlxG.width / bg.width, FlxG.height / bg.height);

		bg.setGraphicSize(Std.int(FlxG.width));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.updateHitbox();
		bg.alpha = 0.3;
		add(bg);

		add(ui);
		bg.cameras = [subcameras];
		ui.cameras = [subcameras];
		ui.screenCenter();
		ui.alpha = 0.5;

		FlxG.cameras.add(subcameras, false);
		subcameras.bgColor = 0;

		var defX:Float = 50;
		var textX:Float = 0;

		for (gameName in suppostedGames) {
			var text:FlxText = new FlxText(textX, 0, 0, gameName, 32);
			text.font = Paths.font('Lang-ZH.ttf');
			textX += text.width + 50;
			selectedGroup.add(text);
		}

		selectedGroup.cameras = [subcameras];
		add(selectedGroup);
		selectedGroup.x = FlxG.width / 2 - selectedGroup.width / 2;
		selectedGroup.y = 100;

		infoBG1.cameras = [subcameras];
		infoBG2.cameras = [subcameras];

		infoBG1.screenCenter();
		infoBG2.screenCenter();

		infoBG1.scale.set(0.5, 0.5);
		infoBG2.scale.set(0.5, 0.5);

		add(infoBG1);
		add(infoBG2);

		infoBG2.visible = false;

		backButton = new GeneralBack(0, FlxG.height * 0.9, FlxG.width * 0.2, FlxG.height * 0.1,
			Language.get('back', 'main'), EngineSet.mainColor, requestClose);
		backButton.cameras = [subcameras];
		add(backButton);

		add(blackScreen);
		blackScreen.cameras = [subcameras];
		blackScreen.alpha = 0;

		flashScreen.cameras = [subcameras];
		flashScreen.alpha = 0;
		add(flashScreen);
	}

	override function update(elapsed:Float)
	{
		if (transitioning)
		{
			super.update(elapsed);
			return;
		}

		if (controls.BACK #if android || FlxG.android.justReleased.BACK #end)
        {
			requestClose();
			return;
        }

		#if mobile
		if (backButtonTouchJustPressed())
		{
			requestClose();
			return;
		}

		if (selectedGameTouchJustPressed())
			return;

		if (infoBackgroundJustPressed())
		{
			requestSelectedGame();
			return;
		}
		#end

		if (controls.ACCEPT)
		{
			requestSelectedGame();
			return;
		}

		if (controls.justPressed("ui_right"))
		{
			nowSelected++;
			if (nowSelected >= selectedGroup.members.length) {
				nowSelected = 0;
			}
			toggleBG();
		} else if (controls.justPressed("ui_left"))
		{
			nowSelected--;
			if (nowSelected < 0) {
				nowSelected = selectedGroup.members.length - 1;
			}
			toggleBG();
		}

		for (i in 0...selectedGroup.members.length) {
			var text:FlxText = cast selectedGroup.members[i];
			if (i == nowSelected) {
				text.color = 0xFFFFFFFF;
			} else {
				#if CODENAME_ENGINE_COMPAT
				text.color = 0xA9A9A9;
				#else
				text.alpha = 0;
				#end
			}
		}

		super.update(elapsed);
	}

	#if mobile
	function backButtonTouchJustPressed():Bool
	{
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed && touch.overlaps(backButton, subcameras))
				return true;
		}
		#end

		return false;
	}

	function selectedGameTouchJustPressed():Bool
	{
		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (!touch.justPressed)
				continue;

			for (i in 0...selectedGroup.members.length)
			{
				var option:FlxSprite = selectedGroup.members[i];
				if (option != null && option.visible && pointerOverlapsSprite(touch, option))
				{
					if (nowSelected != i)
					{
						nowSelected = i;
						toggleBG();
					}

					return true;
				}
			}
		}
		#end

		return false;
	}

	function infoBackgroundJustPressed():Bool
	{
		var target:FlxSprite = nowSelected == 0 ? infoBG1 : infoBG2;
		if (!target.visible)
			return false;

		if (FlxG.mouse.justPressed && pointerOverlapsSprite(FlxG.mouse, target))
			return true;

		#if FLX_TOUCH
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed && pointerOverlapsSprite(touch, target))
				return true;
		}
		#end

		return false;
	}

	function pointerOverlapsSprite(pointer:FlxPointer, target:FlxSprite):Bool
	{
		var bounds = target.getScreenBounds(null, subcameras);
		var position = pointer.getViewPosition(subcameras);
		var overlaps:Bool = bounds.containsPoint(position);
		position.put();
		bounds.put();
		return overlaps;
	}
	#end

	function requestClose():Void
	{
		if (transitioning)
			return;

		FlxG.state.persistentUpdate = true;
		close();
	}

	function requestSelectedGame():Void
	{
		if (transitioning)
			return;

		transitioning = true;
		transitionStartVolume = FlxG.sound.volume;

		FlxG.sound.play(Paths.sound('confirmMenu'));

		subcameras.zoom = 1.1;
		flashScreen.alpha = 1;

		zoomTween = FlxTween.tween(subcameras, {zoom: 1}, 0.7,
		{
			ease: FlxEase.quartOut,
			onComplete: _ ->
			{
				zoomTween = FlxTween.tween(subcameras, {zoom: 2}, 1,
				{
					ease: FlxEase.quartIn
				});
				blackTween = FlxTween.tween(blackScreen, {alpha: 1}, 1,
				{
					ease: FlxEase.quartIn,
					onComplete: _ ->
					{
						FlxG.sound.volume = 0;
						if (!finishSelectedGame())
							restoreFailedTransition();
					}
				});
				volumeTween = FlxTween.tween(FlxG.sound, {volume: 0}, 1,
				{
					ease: FlxEase.quartIn
				});
			}
		});

		flashTween = FlxTween.tween(flashScreen, {alpha: 0}, 0.5,
		{
			ease: FlxEase.quadOut
		});
	}

	function restoreFailedTransition():Void
	{
		flashScreen.alpha = 0;
		zoomTween = FlxTween.tween(subcameras, {zoom: 1}, 0.35,
		{
			ease: FlxEase.quadOut
		});
		volumeTween = FlxTween.tween(FlxG.sound, {volume: transitionStartVolume}, 0.35,
		{
			ease: FlxEase.quadOut
		});
		blackTween = FlxTween.tween(blackScreen, {alpha: 0}, 0.35,
		{
			ease: FlxEase.quadOut,
			onComplete: _ -> transitioning = false
		});
	}

	function finishSelectedGame():Bool
	{
		switch (nowSelected)
		{
			case 0:
				if (!originfunkin.OriginFunkinMode.canEnterOrigin())
				{
					SUtil.showPopUp(originfunkin.OriginFunkinMode.preparationError, "Origin Funkin");
					return false;
				}
				if (!originfunkin.OriginFunkinConfig.requestOrigin())
				{
					SUtil.showPopUp("Could not save the Origin Funkin startup request.", "NovaFlare Engine");
					return false;
				}

			case 1:
				#if CODENAME_ENGINE_COMPAT
				if (!codenamechain.CodeNameMode.canEnter())
				{
					SUtil.showPopUp(codenamechain.CodeNameMode.preparationError, "CodeName");
					return false;
				}
				if (!originfunkin.OriginFunkinConfig.requestCodeName())
				{
					SUtil.showPopUp("Could not save the CodeName startup request.", "NovaFlare Engine");
					return false;
				}
				#end
		}

		try
		{
			// The transition fades the runtime master volume only. Preserve the
			// user's saved volume for the engine that starts next.
			FlxG.save.data.volume = transitionStartVolume;
			ClientPrefs.saveSettings();
		}
		catch (error:Dynamic)
		{
			trace('[SelectGameSubState] Could not save NovaFlare preferences: $error');
		}
		switchAccepted = true;
		LimeSystem.exit(0);
		return true;
	}

	function toggleBG()
	{
		switch (nowSelected) {
			case 0:
				infoBG1.visible = true;
				infoBG2.visible = false;

			case 1:
				infoBG1.visible = false;
				infoBG2.visible = true;
		}
	}

	override function destroy():Void
	{
		FlxG.state.persistentUpdate = true;
		if (transitioning && !switchAccepted)
			FlxG.sound.volume = transitionStartVolume;
		for (tween in [zoomTween, blackTween, flashTween, volumeTween])
		{
			if (tween != null)
			{
				tween.cancel();
				tween.destroy();
			}
		}
		if (subcameras != null)
		{
			FlxG.cameras.remove(subcameras, true);
			subcameras = null;
		}
		super.destroy();
	}
}
