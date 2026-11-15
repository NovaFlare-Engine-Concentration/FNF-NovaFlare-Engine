package originfunkin;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxTimer;

/** Run Origin's preloader work after NF has constructed the shared FlxGame. */
class OriginFunkinBootState extends FlxState
{
  override public function create():Void
  {
    super.create();
    var message = new FlxText(0, 0, FlxG.width, "Loading Origin Funkin...", 24);
    message.alignment = CENTER;
    message.screenCenter();
    add(message);
    new FlxTimer().start(0.01, (_) -> initializeOrigin());
  }

  function initializeOrigin():Void
  {
    try
    {
      funkin.util.tasks.TaskHandler.initialize();
      funkin.assets.Assets.initialize();
      #if (sys && FEATURE_DEBUG_FUNCTIONS)
      var requestedMods = Sys.args().filter(arg -> StringTools.startsWith(arg, '--origin-mod='));
      if (requestedMods.length > 0)
        funkin.modding.PolymodHandler.loadModsById(requestedMods.map(arg -> arg.substr('--origin-mod='.length)));
      else
      #end
        funkin.modding.PolymodHandler.loadEnabledMods();
      funkin.assets.FunkinAssetCache.instance.cacheAssetLists(true);
      funkin.modding.PolymodHandler.loadScripts(true)
        .onComplete((_) -> loadRegistries())
        .onError(fail);
    }
    catch (error:Dynamic) fail(error);
  }

  function loadRegistries():Void
  {
    try
    {
      funkin.data.song.SongRegistry.instance.loadEntries();
      funkin.data.story.level.LevelRegistry.instance.loadEntries();
      funkin.data.notestyle.NoteStyleRegistry.instance.loadEntries();
      funkin.data.freeplay.player.PlayerRegistry.instance.loadEntries();
      funkin.data.dialogue.ConversationRegistry.instance.loadEntries();
      funkin.data.dialogue.DialogueBoxRegistry.instance.loadEntries();
      funkin.data.dialogue.SpeakerRegistry.instance.loadEntries();
      funkin.data.freeplay.album.AlbumRegistry.instance.loadEntries();
      funkin.data.stage.StageRegistry.instance.loadEntries();
      funkin.data.stickers.StickerRegistry.instance.loadEntries();
      funkin.data.freeplay.style.FreeplayStyleRegistry.instance.loadEntries();
      funkin.data.event.SongEventRegistry.loadEventCache();
      funkin.play.notes.notekind.NoteKindManager.initialize();
      funkin.data.character.CharacterRegistry.instance.loadEntries();
      #if FEATURE_HAXEUI
      OriginFunkinEditors.initialize();
      #end
      FlxG.switchState(() -> new funkin.InitState());
    }
    catch (error:Dynamic) fail(error);
  }

  function fail(error:Dynamic):Void
  {
    OriginFunkinMode.reportRuntimeError(Std.string(error));
    FlxG.switchState(() -> new OriginFunkinErrorState());
  }
}
