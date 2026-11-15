package funkin.play.notes.notekind;

import lime.app.Promise;
import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.song.SongData.SongNoteData;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notekind.NoteKind.NoteKindParam;
import funkin.util.macro.ClassMacro;
import funkin.util.tasks.TaskHandler;
import funkin.util.tasks.TaskHandler.Task;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.collection.SynchronizedMap;
#end

@:nullSafety
class NoteKindManager
{
  /**
   * Every built-in note kind class must be added to this list.
   * Thankfully, with the power of `ClassMacro`, this is done automatically.
   */
  #if FEATURE_MULTITHREADING
  static final BUILTIN_KINDS:SynchronizedArray<Class<NoteKind>> = new SynchronizedArray<Class<NoteKind>>(ClassMacro.listSubclassesOf(NoteKind).filter((cls) ->
  {
    !['funkin.play.notes.notekind.NoteKind'].contains(Type.getClassName(cls));
  }));
  #else
  static final BUILTIN_KINDS:Array<Class<NoteKind>> = ClassMacro.listSubclassesOf(NoteKind).filter((cls) ->
  {
    !['funkin.play.notes.notekind.NoteKind'].contains(Type.getClassName(cls));
  });
  #end
  /**
   * A map of all note kinds, keyed by their name.
   * This is used to retrieve note kinds by their name.
   */
  #if FEATURE_MULTITHREADING
  public static var noteKinds:SynchronizedMap<String, NoteKind> = SynchronizedMap.newStringMap();
  #else
  public static var noteKinds:Map<String, NoteKind> = [];
  #end

  static var dispatchList:Null<Array<NoteKind>> = null;

  /**
   * Retrieve a note kind by its name.
   * @param noteKind The name of the note kind.
   * @return The note kind, or null if it doesn't exist.
   */
  public static function getNoteKind(?noteKind:String):Null<NoteKind>
  {
    if (noteKind == null) return null;
    return noteKinds.get(noteKind);
  }

  /**
   * Retrieve a list of known valid note kinds.
   * @return A list of note kinds
   */
  public static function listNoteKinds():Array<String>
  {
    #if FEATURE_MULTITHREADING
    // MapTools can't be used for SynchronizedMap.
    return[for (k => v in noteKinds) k];
    #else
    return [for (key in noteKinds.keys()) key];
    #end
  }

  /**
   * Initialize custom behavior for note kinds.
   */
  public static function initialize():Void
  {
    clearNoteKindCache();
    registerBaseNoteKinds();
    registerScriptedNoteKinds();
  }

  /** Historical entry point for registering built-in kinds without clearing the cache. */
  public static function registerBaseNoteKinds():Void
  {
    trace('Instantiating ${BUILTIN_KINDS.length} built-in note kinds...');
    for (noteKindCls in BUILTIN_KINDS)
    {
      var noteKindClsName:String = Type.getClassName(noteKindCls);
      try
      {
        var kind:NoteKind = Type.createInstance(noteKindCls, []);
        if (kind != null)
        {
          noteKinds.set(kind.noteKind, kind);
          dispatchList = null;
          trace(' Loaded built-in note kind: ${kind.noteKind}');
        }
        else trace(' Failed to load built-in note kind: ${noteKindClsName}');
      }
      catch (error:Dynamic)
      {
        trace(' Failed to load built-in note kind ${noteKindClsName}: $error');
      }
    }

  }

  /** Historical 0.5–0.7 entry point; only registers script-defined kinds. */
  public static function loadScripts():Void
  {
    registerScriptedNoteKinds();
  }

  /** Historical entry point for registering script-defined kinds. */
  public static function registerScriptedNoteKinds():Void
  {
    var scriptedClassName:Array<String> = NoteKind.listScriptClasses();
    if (scriptedClassName.length > 0)
    {
      trace('Instantiating ${scriptedClassName.length} scripted note kind(s)...');
      for (scriptedClass in scriptedClassName)
      {
        try
        {
          var script:Null<NoteKind> = NoteKind.scriptInit(scriptedClass, 'unknown');
          if (script == null)
          {
            trace(' ERROR '.error() + 'Failed to instantiate scripted note kind ($scriptedClass)');
            continue;
          }
          else
          {
            trace('Instantiated scripted note kind ($scriptedClass = ${script.noteKind})');
            noteKinds.set(script.noteKind, script);
            dispatchList = null;
          }
        }
        catch (e)
        {
          trace(' FAILED to instantiate scripted note kind: ${scriptedClass}');
          trace(e);
        }
      }
    }
  }

  #if FEATURE_MULTITHREADING
  public static function loadNoteKindsAsync():lime.app.Future<LoadEntriesResult>
  {
    clearNoteKindCache();

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadNoteKindsAsync');
    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();
    var entryErrors:SynchronizedArray<
      {entryId:String, error:Any, ?entryCls:String}> = new SynchronizedArray();
    var scriptedNoteKindClasses:Array<String>;
    try
    {
      scriptedNoteKindClasses = NoteKind.listScriptClasses();
    }
    catch (error:Dynamic)
    {
      trace('Failed to enumerate scripted note kinds: $error');
      promise.error(error);
      return promise.future;
    }
    var entryCount:Int = 0;
    var completedCount:Int = 0;
    var loadedBaseNoteKinds:Bool = false;

    var loadBaseNoteKindsAsync:Void->Void = () -> {};
    var loadScriptedNoteKindsAsync:Void->Void = () -> {};

    var checkAsyncProgress = () ->
    {
      var current:Int = completedCount;
      if (current == entryCount)
      {
        if (!loadedBaseNoteKinds)
        {
          loadedBaseNoteKinds = true;
          trace('Finished loading built-in note kinds (1/2) ($current / $entryCount)');
          loadScriptedNoteKindsAsync();
        }
        else
        {
          trace('Finished loading scripted note kinds (2/2) ($current / $entryCount)');
          promise.complete({
            entriesLoaded: noteKinds.size(),
            entriesFailed: entryErrors.length
          });
          perf.print();
        }
      }
    }

    var onError:(String,
      {error:Any, entryCls:Null<String>}) -> Void = (entryId, state) ->
      {
        entryErrors.push({
          entryId: entryId,
          error: state.error
        });
        trace('  Failed to load note kind (${entryId}): ${state.error}');
        completedCount++;
        checkAsyncProgress();
      };

    var performLoadBaseNoteKind:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var noteKindClsName:String = Type.getClassName(currentState.noteKindCls);
      var noteKindCls:Class<NoteKind> = currentState.noteKindCls;

      try
      {
        var noteKind:Null<NoteKind> = Type.createInstance(noteKindCls, []);
        if (noteKind != null)
        {
          workOutput.sendComplete({
            kind: noteKind
          }, []);
        }
        else
        {
          workOutput.sendError({
            noteKindId: noteKindClsName,
            error: 'Failed to create built-in note kind ($noteKindClsName)'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          eventId: noteKindClsName,
          error: e
        });
      }
    }

    var performLoadScriptedNoteKind:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var entryCls:String = currentState.entryCls;
      try
      {
        var noteKind:Null<NoteKind> = funkin.util.tasks.ScriptLock.run(() -> NoteKind.scriptInit(entryCls, 'UNKNOWN'));
        if (noteKind != null)
        {
          workOutput.sendComplete({
            kind: noteKind,
            entryCls: entryCls
          }, []);
        }
        else
        {
          workOutput.sendError({
            entryCls: entryCls,
            error: 'Failed to create scripted note kind (${entryCls})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          entryCls: entryCls,
          error: e,
        });
      }
    }

    var onBaseNoteKindLoaded:(String,
      {kind:NoteKind}) -> Void = (entryId, state) ->
      {
        try
        {
          noteKinds.set(state.kind.noteKind, state.kind);
          dispatchList = null;
        }
        catch (error:Dynamic)
        {
          onError(entryId, {error: error, entryCls: null});
          return;
        }
        trace(' Loaded built-in note kind: ${state.kind.noteKind} ($entryId)');
        completedCount++;
        checkAsyncProgress();
      };

    var onScriptedNoteKindLoaded:(String,
      {kind:NoteKind, entryCls:String}) -> Void = (entryCls, state) ->
      {
        var entryId:String;
        try
        {
          entryId = state.kind.noteKind;
          noteKinds.set(entryId, state.kind);
          dispatchList = null;
        }
        catch (error:Dynamic)
        {
          onError(entryCls, {error: error, entryCls: entryCls});
          return;
        }
        completedCount++;
        trace('  Loaded scripted note kind: ${entryId} (${state.entryCls}) ($completedCount / $entryCount)');
        checkAsyncProgress();
      };

    loadBaseNoteKindsAsync = () ->
    {
      completedCount = 0;
      entryCount = BUILTIN_KINDS.length;
      trace('Instantiating ${BUILTIN_KINDS.length} built-in note kinds...');

      if (BUILTIN_KINDS.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (noteKindCls in BUILTIN_KINDS)
        {
          var entryClsName:String = Type.getClassName(noteKindCls);
          var baseNoteKindFuture = TaskHandler.performTask({
            task: performLoadBaseNoteKind,
            initialState: {
              noteKindCls: noteKindCls
            },
          }, new Promise<
            {kind:NoteKind}>());

          baseNoteKindFuture.onError(onError.bind(entryClsName));
          baseNoteKindFuture.onComplete(onBaseNoteKindLoaded.bind(entryClsName));
        }
      }
    }

    loadScriptedNoteKindsAsync = () ->
    {
      // Built-in and scripted kinds may use the same ID; count completed tasks.
      completedCount = 0;
      entryCount = scriptedNoteKindClasses.length;
      trace('Instantiating ${scriptedNoteKindClasses.length} scripted note kind(s)...');

      if (scriptedNoteKindClasses.length == 0)
      {
        checkAsyncProgress();
      }
      else
      {
        for (entryCls in scriptedNoteKindClasses)
        {
          var scriptedNoteKindFuture = TaskHandler.performTask({
            task: performLoadScriptedNoteKind,
            initialState: {
              entryCls: entryCls
            }
          }, new lime.app.Promise<
            {
              kind:NoteKind,
              entryCls:String
            }>());

          scriptedNoteKindFuture.onError(onError.bind(entryCls));
          scriptedNoteKindFuture.onComplete(onScriptedNoteKindLoaded.bind(entryCls));
        }
      }
    }

    loadBaseNoteKindsAsync();

    return promise.future;
  }
  #end

  /**
   * Calls the given event for note kind scripts
   * @param event The event
   */
  public static function callEvent(event:ScriptEvent):Void
  {
    // if it is a note script event,
    // then only call the event for the specific note kind script
    if (Std.isOfType(event, NoteScriptEvent))
    {
      var noteEvent:NoteScriptEvent = cast(event, NoteScriptEvent);

      var kind = noteEvent?.note?.kind;
      if (kind == null) return;

      var noteKind:Null<NoteKind> = noteKinds.get(kind);

      if (noteKind != null)
      {
        ScriptEventDispatcher.callEvent(noteKind, event);
      }
    }
    else // call the event for all note kind scripts
    {
      var list:Null<Array<NoteKind>> = dispatchList;
      if (list == null)
      {
        #if FEATURE_MULTITHREADING
        dispatchList = list = [for (noteKind in noteKinds.values()) noteKind];
        #else
        dispatchList = list = [for (noteKind in noteKinds) noteKind];
        #end
      }

      for (i in 0...list.length)
      {
        var noteKind:NoteKind = list[i];
        ScriptEventDispatcher.callEvent(noteKind, event);
      }
    }
  }

  /**
   * Retrieve the note style from the given note kind
   * @param noteKind note kind name
   * @param suffix Used for song note styles
   * @return NoteStyle
   */
  public static function getNoteStyle(noteKind:String, ?suffix:String):Null<NoteStyle>
  {
    var noteStyleId:Null<String> = getNoteStyleId(noteKind, suffix);

    if (noteStyleId == null)
    {
      return null;
    }

    return NoteStyleRegistry.instance.fetchEntry(noteStyleId);
  }

  /** Preserve the historical API and its original empty-result behavior. */
  @:nullSafety(Off)
  public static function listNoteStyles(songNoteDatas:Array<SongNoteData>):Array<NoteStyle>
  {
    for (songNoteData in songNoteDatas) if (songNoteData != null) getNoteStyle(songNoteData.kind, null);
    return [];
  }

  /** Get the note styles used by the given notes for preloading. */
  public static function listNoteStylesByNoteData(songNoteDatas:Array<SongNoteData>):Array<NoteStyle>
  {
    var results:Array<NoteStyle> = [];
    for (songNoteData in songNoteDatas)
    {
      if (songNoteData == null) continue;
      var kind = songNoteData.kind;
      if (kind == null) continue;

      var noteStyle:Null<NoteStyle> = getNoteStyle(kind, null);
      if (noteStyle != null && !results.contains(noteStyle))
      {
        results.push(noteStyle);
      }
    }
    return results;
  }

  /**
   * Retrieve the note style id from the given note kind
   * @param noteKind Note kind name
   * @param suffix Used for song note styles
   * @return Null<String>
   */
  public static function getNoteStyleId(noteKind:String, ?suffix:String):Null<String>
  {
    if (suffix == '')
    {
      suffix = null;
    }

    var noteStyleId:Null<String> = noteKinds.get(noteKind)?.noteStyleId;
    if (noteStyleId != null && suffix != null)
    {
      noteStyleId = NoteStyleRegistry.instance.hasEntry('$noteStyleId-$suffix') ? '$noteStyleId-$suffix' : noteStyleId;
    }

    return noteStyleId;
  }

  /**
   * Retrive custom params of the given note kind
   * @param noteKind Name of the note kind
   * @return Array<NoteKindParam>
   */
  public static function getParams(noteKind:Null<String>):Array<NoteKindParam>
  {
    if (noteKind == null)
    {
      return [];
    }

    return noteKinds.get(noteKind)?.params ?? [];
  }

  /**
   * Clear the note kind cache.
   * Be sure to register the note kinds again before trying to use them.
   */
  public static function clearNoteKindCache():Void
  {
    noteKinds.clear();
    dispatchList = null;
  }
}
