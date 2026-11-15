package funkin.data.character;

import funkin.assets.Paths;
import funkin.assets.Assets;
import funkin.data.BaseRegistry;
import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.DefaultRegistryImpl;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterData.CharacterRenderType;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import flixel.graphics.frames.FlxFrame;
import funkin.play.character.AnimateAtlasCharacter;
import funkin.play.character.BaseCharacter;
import funkin.play.character.SparrowCharacter;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.character.MultiAnimateAtlasCharacter;
import funkin.play.character.PackerCharacter;
import funkin.util.tasks.TaskHandler;
import funkin.util.tasks.TaskHandler.Task;
import funkin.util.tools.ISingleton;
import lime.app.Promise;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
import hx.concurrent.collection.SynchronizedMap;
#end

@:nullSafety
class CharacterRegistry extends BaseRegistry<BaseCharacter, CharacterData, CharacterEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the character data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateCharacterData()` function.
   */
  public static final CHARACTER_DATA_VERSION:thx.semver.Version = '1.0.2';

  public static final CHARACTER_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';
  #if FEATURE_MULTITHREADING
  static final characterCache:SynchronizedMap<String, CharacterData> = SynchronizedMap.newStringMap();
  #else
  static final characterCache:Map<String, CharacterData> = [];
  #end
  #if FEATURE_MULTITHREADING
  static final characterScriptedClass:SynchronizedMap<String, String> = SynchronizedMap.newStringMap();
  #else
  static final characterScriptedClass:Map<String, String> = [];
  #end
  static final DEFAULT_CHAR_ID:String = 'UNKNOWN';

  public function new()
  {
    super({
      registryId: 'CHARACTER',
      dataFilePath: 'gameplay/characters/',
      nestedEntries: true,
      versionRule: CHARACTER_DATA_VERSION_RULE
    });
  }

  /**
   * Returns the idle frame of a character.
   * TODO: Too similar to the other function in PixellatedIcon and really needs a damn rewrite.
   */
  public static function getCharPixelIconAsset(char:String):Null<FlxFrame>
  {
    var charPath:String = 'ui/freeplay/characters/';

    var charIDParts:Array<String> = char.split('-');
    var iconName:String = '';
    var lastValidIconName:String = '';
    for (i in 0...charIDParts.length)
    {
      iconName += charIDParts[i];

      if (Paths.image(charPath + '${iconName}', false).exists())
      {
        lastValidIconName = iconName;
      }

      if (i < charIDParts.length - 1) iconName += '-';
    }

    charPath += '${lastValidIconName}';

    var assetPath:AssetPath = Paths.image(charPath, false);

    if (!assetPath.exists())
    {
      trace(' WARNING '.warning() + ' Character ${char} has no freeplay icon.');
      return null;
    }

    var isAnimated = assetPath.withAssetType(XML).exists();

    if (isAnimated)
    {
      var frames = Assets.getSparrowAtlas(assetPath);

      var idleFrame:Null<FlxFrame> = frames.frames.find(function(frame:FlxFrame):Bool
      {
        return frame.name.startsWith('idle');
      });

      if (idleFrame == null)
      {
        trace(' WARNING '.warning() + ' Character ${char} has no idle in their freeplay icon.');
        return null;
      }

      return idleFrame;
    }
    else
    {
      var imageFrame = flixel.graphics.frames.FlxImageFrame.fromImage(assetPath.toFlxGraphicAsset());
      return imageFrame.frame;
    }
  }

  public override function loadEntries():Void
  {
    // Match asynchronous reload: disabled mods must not leave stale character data or script classes.
    clearEntries();
    // Instead of loading the entries, we load the character data.
    log(' INFO '.info() + 'Parsing all entries...');

    var charIdList:Array<String> = fetchEntryIdsFromFiles();
    log('Fetching data for ${charIdList.length} characters characters...');

    for (charId in charIdList)
    {
      try
      {
        var charData:Null<CharacterData> = parseEntryData(charId);
        if (charData != null)
        {
          log('Loaded character "${charId}"');
          characterCache.set(charId, charData);
        }
      }
      catch (e)
      {
        // Assume error was already logged.
        continue;
      }
    }

    var scriptedCharClassNames1:Array<String> = originfunkin.compat.LegacyCoreScripts.entryClasses(SparrowCharacter.listScriptClasses());
    if (scriptedCharClassNames1.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames1.length} (Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames1)
      {
        try
        {
          var character:Null<SparrowCharacter> = SparrowCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Sparrow character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Sparrow character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Sparrow character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames2:Array<String> = originfunkin.compat.LegacyCoreScripts.entryClasses(PackerCharacter.listScriptClasses());
    if (scriptedCharClassNames2.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames2.length} (Packer) scripted characters...');
      for (charCls in scriptedCharClassNames2)
      {
        try
        {
          var character:Null<PackerCharacter> = PackerCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Packer character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Packer character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Packer character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames3:Array<String> = originfunkin.compat.LegacyCoreScripts.entryClasses(MultiSparrowCharacter.listScriptClasses());
    if (scriptedCharClassNames3.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames3.length} (Multi-Sparrow) scripted characters...');
      for (charCls in scriptedCharClassNames3)
      {
        try
        {
          var character:Null<MultiSparrowCharacter> = MultiSparrowCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Sparrow character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Multi-Sparrow character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Sparrow character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames4:Array<String> = originfunkin.compat.LegacyCoreScripts.entryClasses(AnimateAtlasCharacter.listScriptClasses());
    if (scriptedCharClassNames4.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames4.length} (Animate Atlas) scripted characters...');
      for (charCls in scriptedCharClassNames4)
      {
        try
        {
          var character:Null<AnimateAtlasCharacter> = AnimateAtlasCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted character: $charCls');
            continue;
          }
          else
          {
            log('Instantiated Animate Atlas character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Animate Atlas character: $charCls');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    var scriptedCharClassNames5:Array<String> = originfunkin.compat.LegacyCoreScripts.entryClasses(MultiAnimateAtlasCharacter.listScriptClasses());
    if (scriptedCharClassNames5.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames5.length} (Multi-Animate Atlas) scripted characters...');
      for (charCls in scriptedCharClassNames5)
      {
        try
        {
          var character:Null<MultiAnimateAtlasCharacter> = MultiAnimateAtlasCharacter.scriptInit(charCls, DEFAULT_CHAR_ID);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Animate Atlas character ($charCls)');
            continue;
          }
          else
          {
            log('Instantiated Multi-Animate Atlas character ($charCls = ${character.characterId})');
            characterScriptedClass.set(character.characterId, charCls);
          }
        }
        catch (e)
        {
          log(' ERROR '.error() + 'Failed to instantiate scripted Multi-Animate Atlas character ($charCls)');
          log(' ERROR '.error() + '$e');
        }
      }
    }
    // NOTE: Only initialize the ones not populated above.
    // BaseCharacter.listScriptClasses() will pick up scripts extending the other classes.
    var scriptedCharClassNames:Array<String> = originfunkin.compat.LegacyCoreScripts.entryClasses(BaseCharacter.listScriptClasses());

    scriptedCharClassNames = scriptedCharClassNames.filter((charCls:String) ->
    {
      return !(
        scriptedCharClassNames1.contains(charCls)
        || scriptedCharClassNames2.contains(charCls)
        || scriptedCharClassNames3.contains(charCls)
        || scriptedCharClassNames4.contains(charCls)
        || scriptedCharClassNames5.contains(charCls)
      );
    });

    if (scriptedCharClassNames.length > 0)
    {
      log('Instantiating ${scriptedCharClassNames.length} (Base) scripted characters...');
      for (charCls in scriptedCharClassNames)
      {
        try
        {
          var character:Null<BaseCharacter> = BaseCharacter.scriptInit(charCls, DEFAULT_CHAR_ID, Custom);
          if (character == null)
          {
            log(' ERROR '.error() + 'Failed to instantiate scripted character ($charCls)');
            continue;
          }
          characterScriptedClass.set(character.characterId, charCls);
          log('Instantiated base scripted character ($charCls = ${character.characterId})');
        }
        catch (error:Dynamic)
        {
          log(' ERROR '.error() + 'Failed to load scripted character ($charCls): $error');
        }
      }
    }
    log(' INFO '.info() + 'Successfully instantiated ${characterCache.size()} characters.');
  }

  #if FEATURE_MULTITHREADING
  public override function loadEntriesAsync():lime.app.Future<LoadEntriesResult>
  {
    clearEntries();

    var perf:funkin.util.logging.Perf = new funkin.util.logging.Perf('loadCharacterCacheAsync');
    var promise:lime.app.Promise<LoadEntriesResult> = new lime.app.Promise<LoadEntriesResult>();
    var entryDataErrors:SynchronizedArray<
      {entryId:String, error:Any, ?entryCls:String}> = new SynchronizedArray();
    var entryScriptErrors:SynchronizedArray<
      {entryId:String, error:Any, ?entryCls:String}> = new SynchronizedArray();

    var charIdList:Array<String> = fetchEntryIdsFromFiles();
    var previousScriptedEntryClasses:SynchronizedArray<String> = new SynchronizedArray<String>();
    var scriptedEntryClassNames:SynchronizedArray<String> = new SynchronizedArray<String>();
    var entryCount:Int = 0;
    var completedCount:Int = 0;

    // Used to track the state we're in while loading the characters. This can either be us loading all character data, or loading each scripted character types.
    // For example, `data means we're loading all of the character data currently
    // `packer` means we're currently loading the scripted classes for PackerCharacter, etc.
    var entryLoadingState:String = 'data';

    var loadCharacterDataAsync:Void->Void = () -> {
    }
    var loadScriptedEntriesAsync:Void->Void = () -> {
    }

    var checkAsyncProgress = () ->
    {
      // We're checking the progress on loading the data for all characters.
      if (entryLoadingState == 'data')
      {
        var current:Int = completedCount;
        if (current == entryCount)
        {
          entryCount = 0; // Reset the entry count so it can be used for scripted classes now.
          entryLoadingState = 'sparrow'; // Move to loading scripted characters.
          loadScriptedEntriesAsync();
          log('Finished loading data for characters (1/2)');
        }
      }
      else
      {
        // We're checking the progress on what characters are scripted.
        var current:Int = completedCount;
        if (current == entryCount)
        {
          // We've finished loading the scripted entries for a character type, use a basic state machine switching to the next one.
          switch (entryLoadingState)
          {
            case 'sparrow':
              entryLoadingState = 'packer';
              log('Finished loading scripted sparrow characters (1/6) ($current / ${entryCount})');
            case 'packer':
              entryLoadingState = 'animateatlas';
              log('Finished loading scripted packer characters (2/6) ($current / ${entryCount})');
            case 'animateatlas':
              entryLoadingState = 'multisparrow';
              log('Finished loading scripted animateatlas characters (3/6) ($current / ${entryCount})');
            case 'multisparrow':
              entryLoadingState = 'multianimateatlas';
              log('Finished loading scripted multi-sparrow characters (4/6) ($current / ${entryCount})');
            case 'multianimateatlas':
              entryLoadingState = 'base';
              log('Finished loading scripted multi-animateatlas characters (5/6) ($current / ${entryCount})');
            case 'base':
              log('Finished loading scripted base characters (6/6) ($current / ${entryCount})');
              log('Finished loading all scripted classes for characters (2/2)');

              // NOTE: `entriesFailed` is the sum of errors from loading both scripted classes & data for characters
              // Same for how `entriesLoaded` is the sum successfully loaded entries for character data & scripted classes
              promise.complete({
                entriesLoaded: characterCache.size() + characterScriptedClass.size(),
                entriesFailed: (entryDataErrors.length + entryScriptErrors.length)
              });
              perf.print();
              return;
          }

          // Restart loading scripted entries.
          loadScriptedEntriesAsync();
        }
      }
    }

    var onError:(String,
      {error:Any, entryCls:Null<String>}) -> Void = (entryId, state) ->
      {
        if (entryLoadingState == 'data')
        {
          entryDataErrors.push({
            entryId: entryId,
            error: state.error
          });
        }
        else
        {
          entryScriptErrors.push({
            entryId: entryId,
            error: state.error
          });
        }

        // Log based on the current state.
        switch (entryLoadingState)
        {
          case 'data':
            log(' ERROR '.error() + ' Failed to load data for character entry ($entryId)');
          case 'sparrow':
            log(' ERROR '.error() + ' Failed to instantiate scripted Sparrow character ($entryId)');
          case 'packer':
            log(' ERROR '.error() + ' Failed to instantiate scripted Packer character ($entryId)');
          case 'animateatlas':
            log(' ERROR '.error() + ' Failed to instantiate scripted Animate Atlas character ($entryId)');
          case 'multisparrow':
            log(' ERROR '.error() + ' Failed to instantiate scripted Multi-Sparrow character ($entryId)');
          case 'multianimateatlas':
            log(' ERROR '.error() + ' Failed to instantiate scripted Multi-Animate Atlas character ($entryId)');
          case 'base':
            log(' ERROR '.error() + ' Failed to instantiate scripted base character ($entryId)');
        }
        completedCount++;
        checkAsyncProgress();
      };

    var onUnscriptedEntryLoaded:(String,
      {entryData:CharacterData}) -> Void = (entryId, state) ->
      {
        try
        {
          characterCache.set(entryId, state.entryData);
        }
        catch (error:Dynamic)
        {
          onError(entryId, {error: error, entryCls: null});
          return;
        }
        completedCount++;
        log('  Loaded data for character: ${entryId} ($completedCount / ${charIdList.length})');
        checkAsyncProgress();
      };

    var onScriptedEntryLoaded:(String,
      {entry:BaseCharacter, entryCls:String}) -> Void = (entryCls, state) ->
      {
        var entryId:String;
        try
        {
          entryId = state.entry.characterId;
          characterScriptedClass.set(entryId, state.entryCls);
        }
        catch (error:Dynamic)
        {
          onError(entryCls, {error: error, entryCls: entryCls});
          return;
        }

        completedCount++;
        log('  Loaded scripted entry: ${entryId} (${state.entryCls}) ($completedCount / ${entryCount})');
        checkAsyncProgress();
      };

    var performLoadUnscriptedEntryData:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var entryId:String = currentState.entryId;
      try
      {
        var charData:Null<CharacterData> = parseEntryData(entryId);
        if (charData != null)
        {
          workOutput.sendComplete({
            entryData: charData
          }, []);
        }
        else
        {
          workOutput.sendError({
            error: 'Failed to load data for character entry (${entryId})'
          });
        }
      }
      catch (e)
      {
        workOutput.sendError({
          entryId: entryId,
          error: e
        });
      }
    }

    var performLoadScriptedEntry:Task = (currentState:State, workOutput:WorkOutput) ->
    {
      var entryCls:String = currentState.entryCls;
      try
      {
        var character:Null<BaseCharacter> = funkin.util.tasks.ScriptLock.run(() -> switch (entryLoadingState)
        {
          case 'sparrow':
            (SparrowCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID) : Null<BaseCharacter>);
          case 'packer':
            PackerCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'animateatlas':
            AnimateAtlasCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'multianimateatlas':
            MultiAnimateAtlasCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'multisparrow':
            MultiSparrowCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          case 'base':
            BaseCharacter.scriptInit(entryCls, DEFAULT_CHAR_ID);
          default:
            null;
        });

        if (character != null)
        {
          workOutput.sendComplete({
            entryCls: entryCls,
            entry: character
          }, []);
        }
        else
        {
          workOutput.sendError({
            entryCls: entryCls,
            error: 'Failed to create scripted entry (${entryCls})'
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

    loadCharacterDataAsync = () ->
    {
      var loadCharacterDataFuture = TaskHandler.performSimpleTask(() ->
      {
        log('Loading data for ${charIdList.length} characters...');

        entryCount = charIdList.length;
        completedCount = 0;

        return true;
      });

      loadCharacterDataFuture.onError((error) -> {
        log('Failed to prepare character data loading: $error');
        promise.error(error);
      });
      loadCharacterDataFuture.onComplete((_) ->
      {
        if (charIdList.length == 0)
        {
          checkAsyncProgress();
          return;
        }
        for (entryId in charIdList)
        {
          var loadUnscriptedEntryDataFuture = TaskHandler.performTask({
            task: performLoadUnscriptedEntryData,
            initialState: {
              entryId: entryId
            }
          }, new Promise<
            {entryData:CharacterData}>());

          loadUnscriptedEntryDataFuture.onError(onError.bind(entryId));
          loadUnscriptedEntryDataFuture.onComplete(onUnscriptedEntryLoaded.bind(entryId));
        }
      });
    }

    // NOTE: Runs several times as we have to load the scripted classes for multiple different types of characters.
    loadScriptedEntriesAsync = () ->
    {
      var loadScriptedEntriesFuture = TaskHandler.performSimpleTask(() ->
      {
        var scriptedClsNames:Array<String> = switch (entryLoadingState)
        {
          case 'sparrow':
            SparrowCharacter.listScriptClasses();
          case 'packer':
            PackerCharacter.listScriptClasses();
          case 'animateatlas':
            AnimateAtlasCharacter.listScriptClasses();
          case 'multisparrow':
            MultiSparrowCharacter.listScriptClasses();
          case 'multianimateatlas':
            MultiAnimateAtlasCharacter.listScriptClasses();
          case 'base':
            var scriptedClasses:Array<String> = BaseCharacter.listScriptClasses().filter((charCls:String) ->
            {
              // ONLY populate the base character classes that hasn't already been populated.
              return !previousScriptedEntryClasses.contains(charCls);
            });
            scriptedClasses;
          default:
            [];
        }
        scriptedClsNames = originfunkin.compat.LegacyCoreScripts.entryClasses(scriptedClsNames);
        scriptedEntryClassNames.clear();
        scriptedEntryClassNames.addAll(scriptedClsNames);

        // We concatenate this list so we can use this when checking for BaseCharacter entries.
        previousScriptedEntryClasses.addAll(scriptedClsNames);

        log('Queuing loading for ${scriptedClsNames.length} $entryLoadingState character scripted entries...');
        // Multiple classes can declare the same character ID; each task still completes.
        entryCount = scriptedClsNames.length;
        completedCount = 0;

        return true;
      });

      loadScriptedEntriesFuture.onError((error) -> {
        log('Failed to enumerate scripted characters: $error');
        promise.error(error);
      });
      loadScriptedEntriesFuture.onComplete((_) ->
      {
        if (scriptedEntryClassNames.length == 0)
        {
          checkAsyncProgress();
        }
        else
        {
          for (entryCls in scriptedEntryClassNames)
          {
            var loadScriptedEntryFuture = TaskHandler.performTask({
              task: performLoadScriptedEntry,
              initialState: {
                entryCls: entryCls
              }
            }, new Promise<
              {
                entry:BaseCharacter,
                entryCls:String
              }>());
            loadScriptedEntryFuture.onError(onError.bind(entryCls));
            loadScriptedEntryFuture.onComplete(onScriptedEntryLoaded.bind(entryCls));
          }
        }
      });
    }

    // First load the character data for all characters.
    loadCharacterDataAsync();

    return promise.future;
  }
  #end

  /**
   * Retrieves a character from the given id and additional parameters.
   * Unlike other registries, this instantiates a new character instead of just re-using an existing entry.
   * @param id The id of the character to fetch.
   * @param params Optional params when loading this character.
   * @return Null<BaseCharacter>
   */
  public override function fetchEntry(id:String, ?params:CharacterEntryParams):Null<BaseCharacter>
  {
    if (id == null || id == '' || !characterCache.exists(id))
    {
      // Gracefully handle songs that don't use this character,
      // or throw an error if the character is missing.

      if (id != null && id != '') trace('Failed to instantiate character, not found in cache: ${id}');
      return null;
    }

    var charData:Null<CharacterData> = characterCache.get(id);
    var charScriptClass:Null<String> = characterScriptedClass.get(id);

    var char:Null<BaseCharacter> = null;

    if (charScriptClass != null)
    {
      if (charData != null)
      {
        switch (charData.renderType)
        {
          case CharacterRenderType.AnimateAtlas:
            char = AnimateAtlasCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.MultiSparrow:
            char = MultiSparrowCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.Sparrow:
            char = SparrowCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.Packer:
            char = PackerCharacter.scriptInit(charScriptClass, id);
          case CharacterRenderType.MultiAnimateAtlas:
            char = MultiAnimateAtlasCharacter.scriptInit(charScriptClass, id);
          default:
            // We're going to assume that the script class does the rendering.
            char = BaseCharacter.scriptInit(charScriptClass, id, {
              renderType: CharacterRenderType.Custom
            });
        }
      }
    }
    else
    {
      if (charData != null)
      {
        switch (charData.renderType)
        {
          case CharacterRenderType.AnimateAtlas:
            char = new AnimateAtlasCharacter(id);
          case CharacterRenderType.MultiSparrow:
            char = new MultiSparrowCharacter(id);
          case CharacterRenderType.Sparrow:
            char = new SparrowCharacter(id);
          case CharacterRenderType.Packer:
            char = new PackerCharacter(id);
          case CharacterRenderType.MultiAnimateAtlas:
            char = new MultiAnimateAtlasCharacter(id);
          default:
            trace(' WARNING '.warning() + ' Instantiating character with undefined renderType ${charData.renderType}');
            char = new BaseCharacter(id, {
              renderType: CharacterRenderType.Custom
            });
        }
      }
    }

    if (char == null)
    {
      trace('Failed to instantiate character: ${id}');
      return null;
    }
    var debug:Bool = params?.debug ?? false;

    trace('Successfully instantiated character (${debug ? 'debug' : 'stable'}): ${id}');

    char.debug = debug;

    // Call onCreate only in the fetchCharacter() function, not at application initialization.
    var event:ScriptEvent = ScriptEvent.get(CREATE);
    ScriptEventDispatcher.callEvent(char, event);
    event.finish();

    return char;
  }

  public override function clearEntries():Void
  {
    if (characterCache != null)
    {
      characterCache.clear();
    }
    if (characterScriptedClass != null)
    {
      characterScriptedClass.clear();
    }
  }

  public override function hasEntry(id:String):Bool
  {
    return characterCache.exists(id);
  }

  public override function countEntries():Int
  {
    return characterCache.size();
  }

  public override function isScriptedEntry(id:String, ?params:CharacterEntryParams):Bool
  {
    return characterScriptedClass.exists(id);
  }

  public override function getScriptedEntryClassName(id:String, ?params:CharacterEntryParams):Null<String>
  {
    return characterScriptedClass.get(id);
  }

  public override function listEntryIds():Array<String>
  {
    return characterCache.keys().array();
  }

  /** Query the shared health-icon resources without selecting a renderer. */
  @:nullSafety(Off)
  public function queryBaseAssets(type:funkin.assets.Assets.AssetType, id:String):Array<funkin.assets.Paths.AssetPath>
  {
    var data = characterCache.get(id);
    if (data == null || (type != IMAGE && type != XML)) return [];
    var iconId = data.healthIcon?.id ?? Constants.DEFAULT_HEALTH_ICON;
    if (iconId == null || iconId == '') return [];
    var key = 'gameplay/characters/$iconId/icon-$iconId';
    var path = type == IMAGE ? funkin.assets.Paths.image(key, false) : funkin.assets.Paths.xml(key, false);
    return path != null && path.exists() ? [path] : [];
  }

  @:nullSafety(Off)
  override function queryDefaultAssets(type:funkin.assets.Assets.AssetType, id:String,
    ?params:CharacterEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    return queryCharacterAssets(type, id, params);
  }

  /** Explicit renderer is used when a 0.9 script queries a renderer subclass. */
  @:nullSafety(Off)
  public function queryCharacterAssets(type:funkin.assets.Assets.AssetType, id:String,
    ?params:CharacterEntryParams, ?forcedRender:String):Array<funkin.assets.Paths.AssetPath>
  {
    if (type != IMAGE && type != XML && type != JSON && type != TEXT) return [];
    var data = characterCache.get(id);
    if (data == null) return [];
    var result:Array<funkin.assets.Paths.AssetPath> = [];
    var seen:Map<String, Bool> = [];
    function add(path:funkin.assets.Paths.AssetPath):Void
    {
      if (path == null || !path.exists() || seen.exists(path.toString())) return;
      seen.set(path.toString(), true);
      result.push(path);
    }
    function addAtlas(path:String, kind:String):Void
    {
      if (path == null || path == '') return;
      var animate = kind == 'animateatlas';
      var key = funkin.assets.Paths.formatRelative(path, 'gameplay/characters/$id', animate ? null : 'png');
      if (animate)
      {
        var atlas = funkin.assets.Paths.animateAtlas(key, false);
        if (type == IMAGE) for (image in atlas.image()) add(image);
        if (type == JSON) for (json in atlas.json()) add(json);
      }
      else if (type == IMAGE) add(funkin.assets.Paths.image(key, false));
      else if (kind == 'packer' && type == TEXT) add(funkin.assets.Paths.txt(key, false));
      else if (kind != 'packer' && type == XML) add(funkin.assets.Paths.xml(key, false));
    }
    for (icon in queryBaseAssets(type, id)) add(icon);
    var render = forcedRender ?? Std.string(data.renderType ?? CharacterRenderType.Sparrow);
    if (render == 'animateatlas' || render == 'multianimateatlas') addAtlas(data.assetPath, 'animateatlas');
    else if (render == 'packer') addAtlas(data.assetPath, 'packer');
    else if (render == 'sparrow' || render == 'multisparrow') addAtlas(data.assetPath, 'sparrow');
    if ((render == 'multisparrow' || render == 'multianimateatlas') && data.animations != null)
    {
      for (animation in data.animations)
      {
        if (animation == null) continue;
        var kind = render == 'multisparrow' ? (animation.renderType == 'animateatlas' ? 'animateatlas' : 'sparrow')
          : (animation.renderType == 'sparrow' ? 'sparrow' : 'animateatlas');
        addAtlas(animation.assetPath, kind);
      }
    }
    return result;
  }

  public function parseEntryData(id:String):Null<CharacterData>
  {
    @:privateAccess
    return switch (this.loadEntryFile(id))
    {
      case {fileName:fileName, contents:contents}:
        // Preserve the strict raw parser while adapting known legacy exports
        // only when the character data belongs to a historical Origin mod.
        if ((contents.indexOf('"Made_With"') >= 0 || contents.indexOf('"asset"') >= 0)
          && originfunkin.compat.LegacyRuntime.isLegacyOrigin('hscriptClass($fileName)'))
        {
          try
          {
            var source:Dynamic = haxe.Json.parse(funkin.util.SerializerUtil.sanitizeJSON(contents));
            var changed = false;
            if (Reflect.isObject(source) && !Std.isOfType(source, Array))
            {
              if (Std.isOfType(Reflect.field(source, 'Made_With'), String))
              {
                Reflect.deleteField(source, 'Made_With');
                changed = true;
              }
              var animations:Dynamic = Reflect.field(source, 'animations');
              if (Std.isOfType(animations, Array))
              {
                for (animation in (cast animations:Array<Dynamic>))
                {
                  if (animation == null || !Reflect.isObject(animation)) continue;
                  var legacyAsset:Dynamic = Reflect.field(animation, 'asset');
                  if (!Std.isOfType(legacyAsset, String)) continue;
                  // Explicit modern data wins, including an explicitly null value.
                  if (!Reflect.hasField(animation, 'assetPath')) Reflect.setField(animation, 'assetPath', legacyAsset);
                  Reflect.deleteField(animation, 'asset');
                  changed = true;
                }
              }
              if (changed) contents = haxe.Json.stringify(source);
            }
          }
          catch (_:Dynamic) {} // Let the normal parser report invalid data.
        }
        var data = parseEntryDataRaw(contents, fileName);
        data == null ? null : CharacterData.validateCharacterData(id, data);
      default: null;
    };
  }

  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<CharacterData>
  {
    var parser = new json2object.JsonParser<CharacterData>();
    parser.fromJson(funkin.util.SerializerUtil.sanitizeJSON(contents), fileName);
    if (parser.errors.length > 0)
    {
      @:privateAccess
      this.printErrors(parser.errors, fileName);
      return null;
    }

    var data = parser.value;
    // Test ownership before validation supplies modern default atlas settings.
    // Explicit renderer settings retain the author's selected modern behavior.
    data.legacyAtlasPlacement = data.renderType == AnimateAtlas && data.atlasSettings == null && data.applyStageMatrix == null
      && originfunkin.compat.LegacyRuntime.usesInitialAtlasPlacement('hscriptClass($fileName)');
    data.legacyAtlasStageMatrix = data.renderType == AnimateAtlas && data.atlasSettings == null && data.applyStageMatrix == null
      && originfunkin.compat.LegacyRuntime.usesHistoricalAtlasStageMatrix('hscriptClass($fileName)');
    // Preserve the raw parser contract: validation/defaults belong to registry entries.
    return data;
  }

  /**
   * Fetches just the character data for a character.
   * @param charId The character ID to fetch.
   * @return The character data, or null if the character was not found.
   */
  public function fetchCharacterData(charId:String):Null<CharacterData>
  {
    if (characterCache.exists(charId)) return characterCache.get(charId);

    return null;
  }
}

typedef CharacterEntryParams =
{
  /**
   * Whether this character should be in debug mode when loaded.
   */
  var ?debug:Bool;
}
