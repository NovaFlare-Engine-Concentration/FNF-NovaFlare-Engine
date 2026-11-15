package funkin;

import funkin.ui.debug.cameraeditor.CameraEditorState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.TransitionData;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.debug.log.LogStyle;
import flixel.util.FlxColor;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.util.plugins.SidePanelPlugin;
import funkin.play.event.SongEventHelper;
import funkin.data.event.SongEventRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.modding.module.ModuleHandler;
import funkin.data.character.CharacterRegistry;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.play.PlayStatePlaylist;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.stageeditor.StageEditorState;
import funkin.ui.title.TitleState;
import funkin.ui.transition.LoadingState;
import funkin.util.CLIUtil;
import funkin.util.CLIUtil.CLIParams;
import funkin.util.macro.MacroUtil;
import funkin.util.TrackerUtil;
import funkin.util.WindowUtil;
import openfl.display.BitmapData;
import funkin.ui.debug.playtest.ChartPlaytestMenu;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.NewgroundsClient;
#end

@:nullSafety
class InitState extends FlxState
{
  @:noCompletion
  static var _coreInitialized:Bool = false;

  public static var customTitleState:Null<FlxState> = null;

  /**
   * Perform a bunch of game setup, then immediately transition to the title screen.
   */
  override public function create():Void
  {
    setupShit();

    Preferences.init();

    // Load controls from save data.
    PlayerSettings.init();

    startGame();
  }

  function setupShit():Void
  {
    if (!_coreInitialized)
    {
      WindowUtil.initWindowEvents();

      #if FEATURE_DEBUG_TRACY
      funkin.util.WindowUtil.initTracy();
      #end

      #if FEATURE_HAPTICS
      extension.haptics.Haptic.initialize();
      #end

      #if FEATURE_MOBILE_ADVERTISEMENTS
      funkin.mobile.util.AdMobUtil.init();
      #end

      #if FEATURE_MOBILE_IAP
      funkin.mobile.util.InAppPurchasesUtil.init();
      #end

      #if FEATURE_MOBILE_IAR
      // Setup In-App reviews
      funkin.mobile.util.InAppReviewUtil.init();
      #end

      #if FEATURE_MOBILE_WEBVIEW
      // Setup WebView
      funkin.mobile.util.WebViewUtil.init();
      #end

      #if FEATURE_MOBILE_AGESIGNALS
      // Setup AgeSignals
      funkin.mobile.util.AgeSignalsUtil.init();
      #end

      #if android
      // Setup Callback util.
      funkin.external.android.CallbackUtil.init();
      #end

      #if ios
      // Setup Audio session
      funkin.external.apple.AudioSession.initialize();
      #end

      #if mobile
      funkin.mobile.util.FNFLoaderProvider.init();
      #end

      SongEventHelper.generateEaseGraphsBitmaps();

      FlxSprite.defaultAntialiasing = true;

      FlxG.sound.volumeUpKeys = [];
      FlxG.sound.volumeDownKeys = [];
      FlxG.sound.muteKeys = [];

      #if !mobile
      FlxG.game.soundTray.active = true;
      #end

      FlxG.game.focusLostFramerate = 30;

      FlxG.inputs.resetOnStateSwitch = false;

      FlxG.fixedTimestep = false;

      setupFlixelDebug();

      var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
      diamond.persist = true;
      diamond.destroyOnNoUse = false;

      // NOTE: tileData is ignored if TransitionData.type is FADE instead of TILES.
      var tileData:TransitionTileData = {
        asset: diamond,
        width: 32,
        height: 32
      };

      FlxTransitionableState.defaultTransIn = new TransitionData(
        FADE,
        FlxColor.BLACK,
        1,
        FlxPoint.weak(0, -1),
        tileData,
        FlxRect.weak(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4)
      );
      FlxTransitionableState.defaultTransOut = new TransitionData(
        FADE,
        FlxColor.BLACK,
        0.7,
        FlxPoint.weak(0, 1),
        tileData,
        FlxRect.weak(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4)
      );

      FlxG.signals.gameResized.add(function(width:Int, height:Int)
      {
        FlxTransitionableState.defaultTransIn = new TransitionData(
          FADE,
          FlxColor.BLACK,
          1,
          FlxPoint.weak(0, -1),
          tileData,
          FlxRect.weak(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4)
        );
        FlxTransitionableState.defaultTransOut = new TransitionData(
          FADE,
          FlxColor.BLACK,
          0.7,
          FlxPoint.weak(0, 1),
          tileData,
          FlxRect.weak(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4)
        );
      });

      // SDL for some reason enables VSync on focus lost/gained in Android
      // Since we don't really need VSync on Android we're gonna forcefully disable it on these signals for now
      // This is fixed on SDL3 from what I've heared but that doodoo isn't working poperly for Android
      #if android
      FlxG.signals.focusLost.add(function()
      {
        WindowUtil.setVSyncMode(originfunkin.OriginVSyncMode.OFF);
      });
      FlxG.signals.focusGained.add(function()
      {
        WindowUtil.setVSyncMode(originfunkin.OriginVSyncMode.OFF);
      });
      #end

      //
      // NEWGROUNDS API SETUP
      //
      #if FEATURE_NEWGROUNDS
      NewgroundsClient.instance.init();
      #end

      //
      // DISCORD API SETUP
      //
      #if FEATURE_DISCORD_RPC
      if (Preferences.enabledDiscordRPC)
      {
        DiscordClient.instance.init();
      }

      lime.app.Application.current.onExit.add(function(exitCode)
      {
        DiscordClient.instance.shutdown();
      });
      #end

      #if FEATURE_LOST_FOCUS_VOLUME
      FlxG.signals.focusLost.add(onLostFocus);
      FlxG.signals.focusGained.add(onGainFocus);
      #end
      //
      // ANDROID SETUP
      //
      #if android
      FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
      #end

      //
      // FLIXEL PLUGINS
      //
      // Plugins provide a useful interface for globally active Flixel objects,
      // that receive update events regardless of the current state.
      // TODO: Move scripted Module behavior to a Flixel plugin.
      #if FEATURE_DEBUG_FUNCTIONS
      funkin.util.plugins.MemoryGCPlugin.initialize();
      #end
      #if FEATURE_SCREENSHOTS
      funkin.util.plugins.ScreenshotPlugin.initialize();
      #end
      #if FEATURE_NEWGROUNDS
      funkin.util.plugins.NewgroundsMedalPlugin.initialize();
      #end
      funkin.util.plugins.EvacuateDebugPlugin.initialize();
      funkin.util.plugins.ForceCrashPlugin.initialize();
      funkin.util.plugins.ReloadAssetsDebugPlugin.initialize();
      #if !mobile
      funkin.util.plugins.VolumePlugin.initialize();
      #end
      #if FLX_DEBUG
      funkin.util.plugins.WatchPlugin.initialize();
      #end
      #if FEATURE_TOUCH_CONTROLS
      funkin.util.plugins.TouchPointerPlugin.initialize();
      funkin.mobile.input.ControlsHandler.initInputTrackers();
      #end
      funkin.util.plugins.SidePanelPlugin.initialize();

      _coreInitialized = true;
    }

    //
    // GAME DATA PARSING
    //

    // If you're looking for registry initialization, it moved to the preloader :)

    ModuleHandler.buildModuleCallbacks();
    ModuleHandler.loadModuleCache();
    ModuleHandler.callOnCreate();

    funkin.input.Cursor.hide();
  }

  #if FEATURE_LOST_FOCUS_VOLUME
  @:noCompletion
  var _lastFocusVolume:Null<Float>;

  function onLostFocus():Void
  {
    if (FlxG.sound.muted || FlxG.sound.volume == 0 || FlxG.autoPause) return;
    _lastFocusVolume = FlxG.sound.volume;
    FlxG.sound.volume *= Constants.LOST_FOCUS_VOLUME_MULTIPLIER;
  }
  #end

  function onGainFocus():Void
  {
    #if !mobile
    if (Preferences.unlockedFramerate)
    {
      FlxG.updateFramerate = 0;
      FlxG.drawFramerate = 0;
    }
    else
    {
      FlxG.updateFramerate = Preferences.framerate;
      FlxG.drawFramerate = Preferences.framerate;
    }
    #end

    #if FEATURE_LOST_FOCUS_VOLUME
    if (FlxG.sound.muted || FlxG.sound.volume == 0 || FlxG.autoPause) return;
    if (_lastFocusVolume != null) FlxG.sound.volume = _lastFocusVolume;
    #end
  }

  /**
   * Start the game.
   *
   * By default, moves to the `TitleState`.
   * But based on compile defines, the game can start immediately on a specific song,
   * or immediately in a specific debug menu.
   */
  function startGame():Void
  {
    // Don't play transition in when entering the title state.
    FlxTransitionableState.skipNextTransIn = true;

    #if (sys && FEATURE_DEBUG_FUNCTIONS)
    if (startDebugTarget()) return;
    #end

    #if SONG
    // -DSONG=bopeebo
    startSong(defineSong(), defineDifficulty());
    #elseif LEVEL
    // -DLEVEL=week1 -DDIFFICULTY=hard
    startLevel(defineLevel(), defineDifficulty());
    #elseif FREEPLAY
    // -DFREEPLAY
    FlxG.switchState(() -> new funkin.ui.freeplay.FreeplayState());
    #elseif DIALOGUE
    // -DDIALOGUE
    FlxG.switchState(() -> new funkin.ui.debug.dialogue.ConversationDebugState());
    #elseif ANIMATE
    // -DANIMATE
    FlxG.switchState(() -> new funkin.ui.debug.anim.FlxAnimateTest());
    #elseif WAVEFORM
    // -DWAVEFORM
    FlxG.switchState(() -> new funkin.ui.debug.WaveformTestState());
    #elseif CHARTING
    // -DCHARTING
    FlxG.switchState(() -> new funkin.ui.debug.charting.ChartEditorState());
    #elseif STAGING
    // -DSTAGING
    FlxG.switchState(() -> new funkin.ui.debug.stageeditor.StageEditorState());
    #elseif STAGEBUILD
    // -DSTAGEBUILD
    FlxG.switchState(() -> new funkin.ui.debug.stage.StageBuilderState());
    #elseif EYESOFGOD
    // -DEYESOFGOD
    FlxG.switchState(() -> new funkin.ui.debug.cameraeditor.CameraEditorState());
    #elseif RESULTS
    // -DRESULTS
    FlxG.switchState(() -> new funkin.play.ResultState({
      storyMode: true,
      title: 'Cum Song Erect by Kawai Sprite',
      songId: 'cum',
      characterId: 'pico',
      difficultyId: 'hard',
      isNewHighscore: true,
      scoreData: {
        score: 1_234_567,
        tallies: {
          sick: 130,
          good: 60,
          bad: 69,
          shit: 69,
          missed: 69,
          combo: 69,
          maxCombo: 69,
          totalNotesHit: 140,
          totalNotes: 240
        }
        // 2400 total notes = 7% = LOSS
        // 275 total notes = 69% = NICE
        // 240 total notes = 79% = GOOD
        // 230 total notes = 82% = GREAT
        // 210 total notes = 91% = EXCELLENT
        // 190 total notes = PERFECT
      },
    }));
    #elseif ANIMDEBUG
    // -DANIMDEBUG
    FlxG.switchState(() -> new funkin.ui.debug.anim.DebugBoundingState());
    #elseif LATENCY
    // -DLATENCY
    FlxG.switchState(() -> new funkin.LatencyState());
    #else
    startGameNormally();
    #end
  }

  public static function resetTitleState():Void
  {
    if (customTitleState != null) customTitleState.destroy();
    customTitleState = null;
  }

  #if (sys && FEATURE_DEBUG_FUNCTIONS)
  /** Launch a local test without changing saves or requiring another build. */
  function startDebugTarget():Bool
  {
    var argument = Sys.args().find(arg -> arg.startsWith("--origin-test="));
    if (argument == null) return false;
    var target = argument.substr("--origin-test=".length);
    if (target == "input" || Sys.args().contains("--origin-log-input")) installInputDiagnostics();
    if (target.startsWith("play:"))
    {
      var songArgs = target.substr("play:".length).split(":");
      startSong(songArgs[0], songArgs.length > 1 ? songArgs[1] : "normal", true);
      return true;
    }
    switch (target)
    {
      case "compat":
        originfunkin.compat.CompatibilityChecks.run();
      #if CODENAME_ENGINE_COMPAT
      case "cne-legacy-syntax":
        FlxG.switchState(() -> new codename.funkin.tests.LegacySyntaxChecks());
      case "cne-bop-zoom":
        FlxG.switchState(() -> new codename.funkin.tests.BopZoomChecks());
      case "cne-pause":
        FlxG.switchState(() -> new codename.funkin.tests.PauseGameChecks());
      #end
      #if cpp
      case "native-allocation":
        originfunkin.compat.NativeAllocationChecks.run();
      #end
      case "legacy-render":
        FlxG.switchState(() -> new originfunkin.compat.LegacyRenderChecks());
      case "classic-characters":
        FlxG.switchState(() -> new originfunkin.compat.ClassicCharacterChecks());
      case "serializer-import":
        FlxG.switchState(() -> new originfunkin.compat.SongSerializerImportChecks());
      #if hxvlc
      case "legacy-video":
        FlxG.switchState(() -> new originfunkin.compat.LegacyVideoChecks());
      case "native-video":
        FlxG.switchState(() -> new originfunkin.compat.NativeVideoChecks());
      #if cpp
      case "attract-lifecycle":
        FlxG.switchState(() -> new originfunkin.compat.AttractLifecycleChecks());
      #end
      case "attract":
        FlxG.switchState(() -> new funkin.ui.title.AttractState());
      #end
      case "reload":
        FlxG.switchState(() -> new funkin.ui.transition.preload.hotreload.HotReloadState({
          targetState: () -> new funkin.ui.modmenu.ModMenuState(),
          onComplete: () -> trace('[Origin hot reload check] Reached completion; default note style=${funkin.data.notestyle.NoteStyleRegistry.instance.fetchDefault()?.id}')
        }));
      case "sync-reload-image-check":
        // Test-only fixture overrides this exact key, then reload restores saved mods.
        var probePath = funkin.assets.Paths.image('ui/freeplay/albums/volume1');
        var originalImage = funkin.assets.Assets.getBitmapData(probePath);
        var beforePixel = originalImage.getPixel32(0, 11);
        var originalGraphic = FlxG.bitmap.add(probePath.toString());
        var beforeGraphicPixel = originalGraphic.bitmap.getPixel32(0, 11);
        funkin.modding.PolymodHandler.forceReloadAssets();
        var afterImage = funkin.assets.Assets.getBitmapData(probePath);
        var afterPixel = afterImage.getPixel32(0, 11);
        var afterGraphic = FlxG.bitmap.add(probePath.toString());
        var afterGraphicPixel = afterGraphic.bitmap.getPixel32(0, 11);
        var oldImageAlive = originalImage.getPixel32(0, 11) == beforePixel;
        var oldGraphicAlive = originalGraphic.bitmap.getPixel32(0, 11) == beforeGraphicPixel;
        // Releasing the old graphic must not remove or dispose its replacement.
        FlxG.bitmap.remove(originalGraphic);
        var currentGraphic = FlxG.bitmap.get(probePath.toString());
        var newGraphicAlive = currentGraphic == afterGraphic && afterGraphic.bitmap != null
          && afterGraphic.bitmap.getPixel32(0, 11) == afterGraphicPixel && afterImage.getPixel32(0, 11) == afterPixel;
        trace('[Origin reload image check] before=$beforePixel after=$afterPixel graphicBefore=$beforeGraphicPixel graphicAfter=$afterGraphicPixel oldImageAlive=$oldImageAlive oldGraphicAlive=$oldGraphicAlive newGraphicAlive=$newGraphicAlive');
        if (beforePixel == afterPixel || beforeGraphicPixel == afterGraphicPixel || !oldImageAlive || !oldGraphicAlive || !newGraphicAlive)
        {
          trace('[Origin reload image check] FAIL');
          Sys.stdout().flush();
          Sys.exit(1);
        }
        trace('[Origin reload image check] CHECKS PASSED');
        Sys.stdout().flush();
        Sys.exit(0);
      case "sync-reload-audio-check":
        // A silent channel remains live while a test-only mod sound is replaced.
        var probePath = funkin.assets.Paths.sound('ui/character-select/sounds/locked');
        var originalSound = funkin.assets.Assets.getSound(probePath);
        var beforeLength = originalSound.length;
        var channel = originalSound.play(0, 0, new openfl.media.SoundTransform(0));
        if (channel == null) throw 'Could not start silent audio probe';
        funkin.modding.PolymodHandler.forceReloadAssets();
        var afterSound = funkin.assets.Assets.getSound(probePath);
        var afterLength = afterSound.length;
        haxe.Timer.delay(() ->
        {
          var position = channel.position;
          var originalLength = originalSound.length;
          trace('[Origin reload audio check] before=$beforeLength after=$afterLength oldLength=$originalLength position=$position');
          channel.stop();
          if (beforeLength < 5000 || afterLength <= 0 || afterLength > 2000 || originalLength != beforeLength || position <= 0)
          {
            trace('[Origin reload audio check] FAIL');
            Sys.stdout().flush();
            Sys.exit(1);
          }
          trace('[Origin reload audio check] CHECKS PASSED');
          Sys.stdout().flush();
          Sys.exit(0);
        }, 700);
      case "sync-reload-atlas-check":
        // Fixture provides a real atlas image while the saved mods provide the base atlas.
        var atlasKey = 'ui/freeplay/interface/freeplay-album';
        var originalAtlas = funkin.Paths.getAnimateAtlas(atlasKey, null, {});
        var originalFrameCount = originalAtlas.frames.length;
        funkin.modding.PolymodHandler.forceReloadAssets();
        var reloadedAtlas = funkin.Paths.getAnimateAtlas(atlasKey, null, {});
        var oldAtlasAlive = originalAtlas.frames.length == originalFrameCount && originalFrameCount > 0;
        var rebuilt = originalAtlas != reloadedAtlas;
        trace('[Origin reload atlas check] rebuilt=$rebuilt oldAtlasAlive=$oldAtlasAlive frames=$originalFrameCount');
        if (!rebuilt || !oldAtlasAlive)
        {
          trace('[Origin reload atlas check] FAIL');
          Sys.stdout().flush();
          Sys.exit(1);
        }
        trace('[Origin reload atlas check] CHECKS PASSED');
        Sys.stdout().flush();
        Sys.exit(0);
      case "sync-reload":
        funkin.modding.PolymodHandler.forceReloadAssets();
        var scriptsInitialized = @:privateAccess polymod.hscript._internal.PolymodScriptClass.scriptsInitialized;
        if (!scriptsInitialized)
          throw 'Synchronous legacy reload returned before script registration.';
        trace('[Origin synchronous reload check] Scripts initialized; default note style=${funkin.data.notestyle.NoteStyleRegistry.instance.fetchDefault()?.id}');
        FlxG.switchState(() -> new funkin.ui.freeplay.FreeplayState());
      #if FEATURE_CHART_EDITOR
      case "chart": FlxG.switchState(() -> new ChartEditorState());
      #end
      #if FEATURE_CAMERA_EDITOR
      case "camera": FlxG.switchState(() -> new CameraEditorState());
      #end
      #if FEATURE_STAGE_EDITOR
      case "stage": FlxG.switchState(() -> new StageEditorState());
      #end
      #if FEATURE_ANIMATION_EDITOR
      case "animation": FlxG.switchState(() -> new funkin.ui.debug.anim.DebugBoundingState());
      #end
      #if FEATURE_RESULTS_DEBUG
      case "results": FlxG.switchState(() -> new funkin.ui.debug.results.ResultsDebugSubState());
      case "result-screen": FlxG.switchState(() -> new funkin.play.ResultState(funkin.ui.debug.results.ResultsDebugSubState.createTestParams()));
      case "result-flow": FlxG.switchState(() -> new originfunkin.compat.ResultFlowChecks());
      #end
      case "main": FlxG.switchState(() -> new funkin.ui.mainmenu.MainMenuState());
      case "options": FlxG.switchState(() -> new funkin.ui.options.OptionsState());
      #if FEATURE_DEBUG_MENU
      case "menu":
        FlxG.switchState(() ->
        {
          var state = new funkin.ui.mainmenu.MainMenuState();
          // Register during the target factory: InitState is still inside its
          // own create() when startDebugTarget runs, before its switch signal.
          FlxG.signals.postStateSwitch.addOnce(() ->
          {
            state.persistentUpdate = false;
            state.openSubState(new funkin.ui.debug.DebugMenuSubState());
          });
          return state;
        });
      #end
      #if FEATURE_POLYMOD_MODS
      case "mods": FlxG.switchState(() -> new funkin.ui.modmenu.ModMenuState());
      #if sys
      case "mods-check": FlxG.switchState(() -> new originfunkin.compat.ModMenuLogicChecks());
      #end
      #end
      case "play": startSong("bopeebo", "normal", true);
      case "input":
        FlxG.switchState(() -> new funkin.ui.mainmenu.MainMenuState());
      default:
        trace('Unknown Origin test target "$target". Use menu, main, mods, chart, camera, stage, animation, results, result-screen, play or input.');
        return false;
    }
    return true;
  }

  static var inputDiagnosticsInstalled:Bool = false;

  /** Observe delivered input and menu changes; never dispatch input or mutate controls. */
  static function installInputDiagnostics():Void
  {
    if (inputDiagnosticsInstalled) return;
    inputDiagnosticsInstalled = true;
    for (eventType in [openfl.events.KeyboardEvent.KEY_DOWN, openfl.events.KeyboardEvent.KEY_UP])
      FlxG.stage.addEventListener(eventType, (event:openfl.events.KeyboardEvent) ->
        trace('[Origin input test] ${event.type}: key=${event.keyCode}, char=${event.charCode}, ctrl=${event.ctrlKey}, shift=${event.shiftKey}, alt=${event.altKey}, enabled=${FlxG.keys.enabled}, state=${inputDiagnosticState()}'),
        false, 10000);
    var previousMenuSnapshot:String = '';
    FlxG.signals.postUpdate.add(() ->
    {
      if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
        trace('[Origin input test] pressed=${FlxG.keys.justPressed.ANY}, released=${FlxG.keys.justReleased.ANY}, controlHeld=${FlxG.keys.pressed.CONTROL}');
      #if FEATURE_POLYMOD_MODS
      if (Std.isOfType(FlxG.state, funkin.ui.modmenu.ModMenuState))
      {
        var menu:funkin.ui.modmenu.ModMenuState = cast FlxG.state;
        var snapshot = haxe.Json.stringify({
          selection: Std.string(@:privateAccess menu.selection),
          enabled: [for (item in @:privateAccess menu.enabledModItems.modItems) item.getModId()],
          allowInput: @:privateAccess menu.allowInput,
          exiting: @:privateAccess menu.exitingMenu
        });
        if (snapshot != previousMenuSnapshot)
        {
          trace('[Origin input test] menu=$snapshot');
          previousMenuSnapshot = snapshot;
        }
      }
      else previousMenuSnapshot = '';
      #end
    });
    FlxG.signals.postStateSwitch.add(() ->
      trace('[Origin input test] entered=${inputDiagnosticState()}, savedMods=${haxe.Json.stringify(funkin.save.Save.instance.enabledModIds.value)}'));
    trace('[Origin input test] diagnostics enabled; observing delivered events only');
  }

  static function inputDiagnosticState():String
  {
    var cls = Type.getClass(FlxG.state);
    return cls == null ? 'none' : (Type.getClassName(cls) ?? 'unknown');
  }
  #end

  /**
   * Start the game by moving to the title state and play the game as normal.
   */
  function startGameNormally():Void
  {
    var params:CLIParams = CLIUtil.processArgs();

    #if FEATURE_ONE_CLICK_INSTALL
    // Claims the handoff lock, so any later launch forwards its link here instead of booting.
    funkin.modding.install.OneClickInstallHandler.initialize();

    #if mobile
    final fnfModUrl:Null<String> = funkin.mobile.util.FNFLoaderProvider.queryFNFMOD();

    if (fnfModUrl != null && fnfModUrl.length > 0)
    {
      funkin.modding.install.OneClickInstallHandler.handleLink(fnfModUrl);
    }
    #end

    if (funkin.modding.install.OneClickInstallHandler.stashLaunchLink(params.oneClickUrl) || funkin.modding.install.OneClickInstallHandler.hasPendingLink())
    {
      FlxG.switchState(() -> new funkin.ui.modmenu.ModMenuState());
      return;
    }
    #end

    if (params.chart.shouldLoadChart)
    {
      #if FEATURE_CHART_EDITOR
      FlxG.switchState(() -> new ChartEditorState({
        loadFromPath: params.chart.chartPath,
      }));
      #else
      FlxG.switchState(() -> new TitleState());
      #end
    }
    else if (params.camera.shouldLoadChart)
    {
      #if FEATURE_CAMERA_EDITOR
      FlxG.switchState(() -> new CameraEditorState({
        loadFromPath: params.camera.chartPath,
      }));
      #else
      FlxG.switchState(() -> new TitleState());
      #end
    }
    else if (params.stage.shouldLoadStage)
    {
      #if FEATURE_STAGE_EDITOR
      FlxG.switchState(() -> new StageEditorState({
        fnfsTargetPath: params.stage.stagePath,
      }));
      #else
      FlxG.switchState(() -> new TitleState());
      #end
    }
    else if (params.song.shouldLoadSong && params.song.songPath != null)
    {
      #if sys
      FlxG.switchState(() -> new ChartPlaytestMenu(params.song.songPath));
      #else
      FlxG.switchState(() -> new TitleState());
      #end
    }
    else
    {
      #if mobile
      funkin.mobile.util.FNFLoaderProvider.onFNFCOpen.add(function(fnfcFile:String)
      {
        flixel.tweens.FlxTween.globalManager.clear();
        flixel.util.FlxTimer.globalManager.clear();
        @:nullSafety(Off)
        if (FlxG.sound.music != null)
        {
          FlxG.sound.music.destroy();
          FlxG.sound.music = null;
        }

        FlxG.switchState(() -> new ChartPlaytestMenu(fnfcFile));
      });

      final fnfcFile = funkin.mobile.util.FNFLoaderProvider.queryFNFC();

      if (fnfcFile != null)
      {
        trace('launching FNFC from $fnfcFile');

        FlxG.switchState(() -> new ChartPlaytestMenu(fnfcFile));
      }
      else if (customTitleState != null)
      {
        FlxG.switchState(() -> customTitleState);
      }
      else
      {
        FlxG.switchState(() -> new TitleState());
      }
      #else
      if (customTitleState != null)
      {
        FlxG.switchState(() -> customTitleState);
        return;
      }

      FlxG.switchState(() -> new TitleState());
      #end
    }
  }

  /**
   * Start the game by directly loading into a specific song.
   * @param songId
   * @param difficultyId
   */
  function startSong(songId:String, difficultyId:String = 'normal', testMode:Bool = false):Void
  {
    var songData:Null<funkin.play.song.Song> = funkin.data.song.SongRegistry.instance.fetchEntry(songId, {
      variation: Constants.DEFAULT_VARIATION
    });

    if (songData == null)
    {
      startGameNormally();
      return;
    }

    #if (sys && FEATURE_DEBUG_FUNCTIONS)
    if (testMode)
    {
      var styleArg = Sys.args().find(arg -> arg.startsWith('--origin-test-style='));
      if (styleArg != null)
      {
        var styleId = styleArg.substr('--origin-test-style='.length);
        if (funkin.data.notestyle.NoteStyleRegistry.instance.fetchEntry(styleId) == null)
          throw 'Unknown test note style: $styleId';
        // Chart caching reads these per-process metadata objects again below.
        for (metadata in songData.getRawMetadata())
        {
          metadata.playData.noteStyle = styleId;
          var difficulty = songData.getDifficulty(difficultyId, metadata.variation);
          if (difficulty != null) difficulty.noteStyle = styleId;
        }
        trace('[Origin play test] Using note style $styleId without changing song files.');
      }
    }
    #end

    // TODO: Rework loading behavior so we don't have to do this.
    switch (songId)
    {
      case 'tutorial' | 'bopeebo' | 'fresh' | 'dadbattle':
        PlayStatePlaylist.campaignId = 'week1';
      case 'spookeez' | 'south' | 'monster':
        PlayStatePlaylist.campaignId = 'week2';
      case 'pico' | 'philly-nice' | 'blammed':
        PlayStatePlaylist.campaignId = 'week3';
      case 'high' | 'satin-panties' | 'milf':
        PlayStatePlaylist.campaignId = 'week4';
      case 'cocoa' | 'eggnog' | 'winter-horrorland':
        PlayStatePlaylist.campaignId = 'week5';
      case 'senpai' | 'roses' | 'thorns':
        PlayStatePlaylist.campaignId = 'week6';
      case 'ugh' | 'guns' | 'stress':
        PlayStatePlaylist.campaignId = 'week7';
      case 'darnell' | 'lit-up' | '2hot' | 'blazin':
        PlayStatePlaylist.campaignId = 'weekend1';
    }

    @:nullSafety(Off) // Cannot unify?
    LoadingState.loadPlayState({
      targetSong: songData,
      targetDifficulty: difficultyId,
      practiceMode: testMode,
      botPlayMode: testMode,
    });
  }

  /**
   * Start the game by directly loading into a specific story mode level.
   * @param levelId
   * @param difficultyId
   */
  function startLevel(levelId:String, difficultyId:String = 'normal'):Void
  {
    var currentLevel:Null<funkin.ui.story.Level> = funkin.data.story.level.LevelRegistry.instance.fetchEntry(levelId);

    if (currentLevel == null)
    {
      startGameNormally();
      return;
    }

    PlayStatePlaylist.campaignId = levelId;

    PlayStatePlaylist.playlistSongIds = currentLevel.getSongs();
    PlayStatePlaylist.isStoryMode = true;
    PlayStatePlaylist.campaignScore = 0;

    var targetSongId:Null<String> = PlayStatePlaylist.playlistSongIds.shift();

    var targetSong:Null<funkin.play.song.Song> = null;

    if (targetSongId != null) targetSong = SongRegistry.instance.fetchEntry(targetSongId, {
      variation: Constants.DEFAULT_VARIATION
    });

    if (targetSongId == null)
    {
      startGameNormally();
      return;
    }

    @:nullSafety(Off)
    LoadingState.loadPlayState({
      targetSong: targetSong,
      targetDifficulty: difficultyId,
    });
  }

  @:nullSafety(Off) // Meh, remove when flixel.system.debug.log.LogStyle is null safe
  function setupFlixelDebug():Void
  {
    //
    // FLIXEL DEBUG SETUP
    //
    #if (FEATURE_DEBUG_FUNCTIONS && !FLX_NO_DEBUG)
    trace('Initializing Flixel debugger...');

    #if !debug
    // Make errors less annoying on release builds.
    LogStyle.ERROR.openConsole = false;
    LogStyle.ERROR.errorSound = null;
    #end

    // Make errors and warnings less annoying.
    LogStyle.WARNING.openConsole = false;
    LogStyle.WARNING.errorSound = null;

    // Disable using ~ to open the console (we use that for the Editor menu)
    FlxG.debugger.toggleKeys = [F2];
    TrackerUtil.initTrackers();

    // Adds a red button to the debugger.
    // This pauses the game AND the music! This ensures the Conductor stops.
    FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFFCC2233), function()
    {
      if (FlxG.vcr.paused)
      {
        FlxG.vcr.resume();

        for (snd in FlxG.sound.list)
        {
          snd.resume();
        }

        FlxG.sound.music.resume();
      }
      else
      {
        FlxG.vcr.pause();

        for (snd in FlxG.sound.list)
        {
          snd.pause();
        }

        FlxG.sound.music.pause();
      }
    });

    // Adds a blue button to the debugger.
    // This skips forward in the song.
    FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFF2222CC), function()
    {
      FlxG.game.debugger.vcr.onStep();

      for (snd in FlxG.sound.list)
      {
        snd.pause();
        snd.time += FlxG.elapsed * 1000;
      }

      FlxG.sound.music.pause();
      FlxG.sound.music.time += FlxG.elapsed * 1000;
    });

    // Adds an additional Close Debugger button.
    // This big obnoxious white button is for MOBILE, so that you can press it
    // easily with your finger when debug bullshit pops up during testing lol!
    #if mobile
    FlxG.debugger.addButton(LEFT, new BitmapData(200, 200), function()
    {
      FlxG.debugger.visible = false;

      // Make errors and warnings less annoying.
      // Forcing this always since I have never been happy to have the debugger to pop up
      LogStyle.ERROR.openConsole = false;
      LogStyle.ERROR.errorSound = null;
      LogStyle.WARNING.openConsole = false;
      LogStyle.WARNING.errorSound = null;
    });
    #end // mobile big butotn crap
    #end
  }

  function defineSong():Null<String>
  {
    return MacroUtil.getDefine('SONG');
  }

  function defineLevel():Null<String>
  {
    return MacroUtil.getDefine('LEVEL');
  }

  function defineDifficulty():Null<String>
  {
    return MacroUtil.getDefine('DIFFICULTY');
  }
}
