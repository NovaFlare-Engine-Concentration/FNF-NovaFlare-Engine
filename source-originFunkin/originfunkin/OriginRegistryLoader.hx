package originfunkin;

import lime.app.Future;
import lime.app.Promise;

/** Script constructors can access graphics and other registries on shared SDL2. */
class OriginRegistryLoader
{
  public static function defer(action:Void->Void):Future<Bool>
  {
    var promise = new Promise<Bool>();
    haxe.Timer.delay(() ->
    {
      try
      {
        if (!funkin.util.tasks.TaskHandler.isMainThread()) throw 'Origin registry construction must run on the main thread.';
        action();
        promise.complete(true);
      }
      catch (error:Dynamic) promise.error(error);
    }, 1);
    return promise.future;
  }

  public static function load(includeModules:Bool = false):Future<Bool>
  {
    var steps:Array<Void->Void> = [
      () -> funkin.data.song.SongRegistry.instance.loadEntries(),
      () -> funkin.data.story.level.LevelRegistry.instance.loadEntries(),
      () -> funkin.data.notestyle.NoteStyleRegistry.instance.loadEntries(),
      () -> funkin.data.freeplay.player.PlayerRegistry.instance.loadEntries(),
      () -> funkin.data.dialogue.ConversationRegistry.instance.loadEntries(),
      () -> funkin.data.dialogue.DialogueBoxRegistry.instance.loadEntries(),
      () -> funkin.data.dialogue.SpeakerRegistry.instance.loadEntries(),
      () -> funkin.data.freeplay.album.AlbumRegistry.instance.loadEntries(),
      () -> funkin.data.stage.StageRegistry.instance.loadEntries(),
      () -> funkin.data.stickers.StickerRegistry.instance.loadEntries(),
      () -> funkin.data.freeplay.style.FreeplayStyleRegistry.instance.loadEntries(),
      () -> funkin.data.event.SongEventRegistry.loadEventCache(),
      () -> funkin.play.notes.notekind.NoteKindManager.initialize(),
      () -> funkin.data.character.CharacterRegistry.instance.loadEntries()
    ];
    // Modules may fetch note styles and characters in their constructors.
    if (includeModules) steps.push(() -> funkin.modding.module.ModuleHandler.loadModuleCache());
    return loadSteps(steps);
  }

  static function loadSteps(steps:Array<Void->Void>):Future<Bool>
  {
    var promise = new Promise<Bool>();
    var completed = 0;
    var failures:Array<String> = [];
    var next:Void->Void = null;
    function advance():Void
    {
      completed++;
      promise.progress(completed, steps.length);
      next();
    }
    next = () ->
    {
      if (completed == steps.length)
      {
        if (failures.length == 0) promise.complete(true);
        else promise.error('Origin registry loading failed: ${failures.join("; ")}');
        return;
      }
      var stepIndex = completed;
      defer(steps[stepIndex]).onComplete(_ -> advance()).onError(error ->
      {
        var message = 'registry $stepIndex: $error';
        trace(message);
        failures.push(message);
        advance();
      });
    };
    next();
    return promise.future;
  }
}
