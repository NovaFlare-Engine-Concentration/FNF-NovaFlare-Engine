package funkin.data.song.importer; // import is a reserved word dumbass

import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.importer.FNFLegacyData;
import funkin.data.song.importer.FNFLegacyData.LegacyNoteSection;

@:nullSafety
class FNFLegacyImporter
{
  public static function parseLegacyDataRaw(input:String, fileName:String = 'raw'):Null<FNFLegacyData>
  {
    // The original loader cast the JSON object and ignored unrelated editor fields.
    var parser = new json2object.JsonParser<FNFLegacyData>({ignoreUnknownVariables:true});
    parser.fromJson(input, fileName);

    if (parser.errors.length > 0)
    {
      trace('[FNFLegacyImporter] Error parsing JSON data from ' + fileName + ':');
      for (error in parser.errors) DataError.printError(error);
      return null;
    }
    return parser.value;
  }

  /**
   * @param data The raw parsed JSON data to migrate, as a Dynamic.
   * @param difficulty
   * @return SongMetadata
   */
  public static function migrateMetadata(songData:FNFLegacyData, difficulty:String = 'normal'):SongMetadata
  {
    trace('Migrating song metadata from FNF Legacy.');

    var songMetadata:SongMetadata = new SongMetadata('Import', "", "", Constants.DEFAULT_VARIATION);

    // Set generatedBy string for debugging.
    songMetadata.generatedBy = 'Chart Editor Import (FNF Legacy)';

    var stage = legacyStageId(songData.song.stage ?? songData.song.stageDefault ?? inferLegacyStage(songData.song.song));
    songMetadata.playData.stage = stage;
    if (stage == 'school' || stage == 'schoolEvil') songMetadata.playData.noteStyle = 'pixel';
    songMetadata.songName = songData.song?.song ?? 'Import';
    songMetadata.playData.difficulties = [];

    if (songData.song?.notes != null)
    {
      switch (songData.song.notes)
      {
        case Left(notes):
          // One difficulty of notes.
          songMetadata.playData.difficulties.push(difficulty);
        case Right(difficulties):
          if (difficulties.easy != null) songMetadata.playData.difficulties.push('easy');
          if (difficulties.normal != null) songMetadata.playData.difficulties.push('normal');
          if (difficulties.hard != null) songMetadata.playData.difficulties.push('hard');
      }
    }

    songMetadata.playData.songVariations = [];

    songMetadata.timeChanges = rebuildTimeChanges(songData, difficulty);

    var girlfriend = songData.song.gfVersion ?? switch (stage)
    {
      case 'school' | 'schoolEvil': 'gf-pixel';
      case 'limoRide': 'gf-car';
      case 'mallXmas' | 'mallEvil': 'gf-christmas';
      case 'tankmanBattlefield': 'gf-tankmen';
      default: 'gf';
    };
    if (songData.song.gfVersion == null)
    {
      if (songData.song.player1 == 'pico') girlfriend = 'nene';
      if (songData.song.song.toLowerCase() == 'stress') girlfriend = 'pico-speaker';
    }
    songMetadata.playData.characters = new SongCharacterData(songData.song?.player1 ?? 'bf', girlfriend,
      songData.song?.player2 ?? 'dad', '', [], null, null);

    return songMetadata;
  }

  static function legacyStageId(stage:String):String
  {
    return switch (stage)
    {
      case 'stage': 'mainStage';
      case 'spooky': 'spookyMansion';
      case 'philly': 'phillyTrain';
      case 'limo': 'limoRide';
      case 'mall': 'mallXmas';
      case 'tank': 'tankmanBattlefield';
      default: stage;
    };
  }

  /** Original PlayState selected stages by song ID before charts carried stage metadata. */
  static function inferLegacyStage(song:String):String
  {
    return switch (song.toLowerCase())
    {
      case 'spookeez' | 'monster' | 'south': 'spooky';
      case 'pico' | 'blammed' | 'philly': 'philly';
      case 'milf' | 'satin-panties' | 'high': 'limo';
      case 'cocoa' | 'eggnog': 'mall';
      case 'winter-horrorland': 'mallEvil';
      case 'senpai' | 'roses': 'school';
      case 'thorns': 'schoolEvil';
      case 'guns' | 'stress' | 'ugh': 'tank';
      case 'darnell': 'phillyStreets';
      default: 'stage';
    };
  }

  public static function migrateChartData(songData:FNFLegacyData, difficulty:String = 'normal'):SongChartData
  {
    trace('Migrating song chart data from FNF Legacy.');

    var songChartData:SongChartData = new SongChartData([difficulty => 1.0], [], [difficulty => []]);

    if (songData.song?.notes != null)
    {
      switch (songData.song.notes)
      {
        case Left(notes):
          // One difficulty of notes.
          songChartData.notes.set(difficulty, migrateNoteSections(notes));
        case Right(difficulties):
          if (difficulties.easy != null) songChartData.notes.set('easy', migrateNoteSections(difficulties.easy));
          if (difficulties.normal != null) songChartData.notes.set('normal', migrateNoteSections(difficulties.normal));
          if (difficulties.hard != null) songChartData.notes.set('hard', migrateNoteSections(difficulties.hard));
      }
    }

    // Import event data.
    songChartData.events = rebuildEventData(songData, difficulty);

    switch (songData.song.speed)
    {
      case Left(speed):
        // Sets the scroll speed for the difficulty.
        songChartData.scrollSpeed.set(difficulty, speed);
      case Right(speeds):
        if (speeds.easy != null) songChartData.scrollSpeed.set('easy', speeds.easy);
        if (speeds.normal != null) songChartData.scrollSpeed.set('normal', speeds.normal);
        if (speeds.hard != null) songChartData.scrollSpeed.set('hard', speeds.hard);
    }

    return songChartData;
  }

  /**
   * FNF Legacy doesn't have song events, but without them the song won't look right,
   * so we insert camera events when the character changes.
   */
  static function rebuildEventData(songData:FNFLegacyData, difficulty:String):Array<SongEventData>
  {
    var result:Array<SongEventData> = [];
    var lastSectionWasMustHit:Null<Bool> = null;
    visitSections(songData, difficulty, (section, time, beat, bpm) ->
    {
      if (section.mustHitSection != lastSectionWasMustHit)
      {
        lastSectionWasMustHit = section.mustHitSection;
        result.push(new SongEventData(time, 'FocusCamera', {
          char: section.mustHitSection ? 0 : 1
        }));
      }
    });
    return result;
  }

  /**
   * Port over time changes from FNF Legacy.
   * The original Conductor applies changes at the section boundary, even in empty sections.
   */
  static function rebuildTimeChanges(songData:FNFLegacyData, difficulty:String):Array<SongTimeChange>
  {
    var result:Array<SongTimeChange> = [new SongTimeChange(0, songData.song.bpm, 4, 4, 0)];
    visitSections(songData, difficulty, (_, time, beat, bpm) ->
    {
      var previous = result[result.length - 1];
      if (previous.bpm == bpm) return;
      var change = new SongTimeChange(time, bpm, 4, 4, beat);
      if (previous.timeStamp == time) result[result.length - 1] = change;
      else result.push(change);
    });
    return result;
  }

  static function sectionsForDifficulty(songData:FNFLegacyData, difficulty:String):Array<LegacyNoteSection>
  {
    return switch (songData.song.notes)
    {
      case Left(notes): notes;
      case Right(difficulties):
        switch (difficulty)
        {
          case 'easy': difficulties.easy ?? difficulties.normal ?? difficulties.hard ?? [];
          case 'hard': difficulties.hard ?? difficulties.normal ?? difficulties.easy ?? [];
          default: difficulties.normal ?? difficulties.hard ?? difficulties.easy ?? [];
        }
    };
  }

  static function visitSections(songData:FNFLegacyData, difficulty:String, visitor:(LegacyNoteSection, Float, Float, Float)->Void):Void
  {
    var bpm = songData.song.bpm;
    var time = 0.0;
    var beat = 0.0;
    if (!Math.isFinite(bpm) || bpm <= 0) throw 'Invalid legacy song BPM: $bpm';
    for (section in sectionsForDifficulty(songData, difficulty))
    {
      if (section.changeBPM ?? false) bpm = section.bpm ?? bpm;
      if (!Math.isFinite(bpm) || bpm <= 0) throw 'Invalid legacy section BPM: $bpm';
      var steps = section.lengthInSteps ?? 16;
      if (steps < 0) throw 'Invalid legacy section length: $steps';
      visitor(section, time, beat, bpm);
      time += steps * 60000.0 / (bpm * 4);
      beat += steps / 4.0;
    }
  }

  static final STRUMLINE_SIZE = 4;

  static function migrateNoteSections(input:Array<LegacyNoteSection>):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = [];

    for (section in input)
    {
      var mustHitSection = section.mustHitSection ?? false;
      for (note in section.sectionNotes)
      {
        // Handle the dumb logic for mustHitSection.
        var noteData = note.data;
        if (noteData < 0) continue; // Exclude Psych event notes.
        if (noteData > (STRUMLINE_SIZE * 2)) noteData = noteData % (2 * STRUMLINE_SIZE); // Handle other engine event notes.

        // Flip notes if mustHitSection is FALSE (not true lol).
        if (!mustHitSection)
        {
          if (noteData >= STRUMLINE_SIZE)
          {
            noteData -= STRUMLINE_SIZE;
          }
          else
          {
            noteData += STRUMLINE_SIZE;
          }
        }

        result.push(new SongNoteData(note.time, noteData, note.length, note.getKind()));
      }
    }

    return result;
  }
}
