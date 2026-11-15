package originfunkin.compat;

#if (sys && FEATURE_DEBUG_FUNCTIONS && FEATURE_RESULTS_DEBUG)
import flixel.FlxG;
import funkin.graphics.FunkinSprite;
import funkin.play.ResultState;
import funkin.play.scoring.Scoring.ScoringRank;
using Lambda;

/** Explicit native results regression. Practice/bot play prevent score side effects. */
@:access(funkin.play.ResultState)
class ResultFlowChecks extends ResultState
{
  var sprites:Array<FunkinSprite> = [];
  var framesSeen:Array<Map<String, Bool>> = [];
  var finishes:Array<Int> = [];
  var drawn:Int = 0;
  var elapsedTime:Float = 0;
  var musicAdvanced:Bool = false;
  var previousMusicTime:Float = -1;
  var finishing:Bool = false;

  public function new()
  {
    var params = funkin.ui.debug.results.ResultsDebugSubState.createTestParams();
    params.title = 'Origin compatibility results';
    params.songId = '__origin_results_check';
    params.characterId = option('character', 'bf');
    params.difficultyId = 'normal';
    params.variationId = 'default';
    params.isNewHighscore = false;
    var completion = switch (option('rank', 'good'))
    {
      case 'loss': 0;
      case 'good': 65;
      case 'great': 85;
      case 'excellent': 95;
      case 'perfect', 'gold': 100;
      case 'empty': 0;
      default: throw 'Unknown result check rank';
    };
    params.scoreData.tallies = {
      sick: option('rank', 'good') == 'gold' ? 100 : 0,
      good: option('rank', 'good') == 'gold' ? 0 : completion,
      bad: 0, shit: 0, missed: 0, combo: 0, maxCombo: 0,
      totalNotesHit: completion, totalNotes: option('rank', 'good') == 'empty' ? 0 : 100
    };
    super(params);
  }

  override public function create():Void
  {
    FlxG.autoPause = false;
    super.create();
    for (entry in characterAtlasAnimations) sprites.push(entry.sprite);
    for (entry in characterSparrowAnimations) sprites.push(entry.sprite);
    require(sprites.length > 0, 'character results animations were created');
    for (index in 0...sprites.length)
    {
      framesSeen.push([]);
      finishes.push(0);
      var slot = index;
      sprites[index].animation.onFinish.add(_ -> finishes[slot]++);
    }
    trace('[Origin results check] START character=${params.characterId} owner=$playerCharacterId rank=$rank atlas=${characterAtlasAnimations.length} sparrow=${characterSparrowAnimations.length}');
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    if (finishing) return;
    elapsedTime += elapsed;
    for (index in 0...sprites.length)
    {
      var animation = sprites[index].animation.curAnim;
      if (sprites[index].visible && animation != null)
        framesSeen[index].set('${animation.name}:${animation.curFrame}', true);
    }
    var music = introMusicAudio ?? resultsMusic ?? FlxG.sound.music;
    if (music != null && music.playing)
    {
      if (previousMusicTime < 0) previousMusicTime = music.time;
      else if (music.time > previousMusicTime + 20) musicAdvanced = true;
    }
    if (elapsedTime >= 20)
    {
      require(drawn >= 60, 'native results screen was drawn');
      require(musicAdvanced, 'real results music advanced');
      var metadata = funkin.data.song.SongRegistry.instance.parseMusicData(getMusicPath(playerCharacter, rank));
      require(metadata != null && metadata.timeChanges.length > 0 && metadata.timeChanges[0].bpm > 0,
        'results audio and authored tempo metadata resolve together');
      for (index in 0...sprites.length)
      {
        var sprite = sprites[index];
        require(sprite.visible && framesSeen[index].count() > 1, 'animation $index became visible and advanced');
        var bounds = sprite.getScreenBounds();
        trace('[Origin results check] ANIMATION index=$index atlas=${sprite.isAnimate} frames=${framesSeen[index].count()} finishes=${finishes[index]} current=${sprite.animation.curAnim?.name} position=${sprite.x},${sprite.y} size=${sprite.width},${sprite.height} bounds=$bounds');
        bounds.put();
      }
      require(funkin.modding.ScriptGuard.brokenCount == 0, 'no broken results script');
      finishing = true;
      var oldMusic = [introMusicAudio, resultsMusic, FlxG.sound.music];
      FlxG.switchState(() -> new flixel.FlxState());
      haxe.Timer.delay(() ->
      {
        for (sprite in sprites) require(sprite.animation == null, 'results renderer destroyed on state exit');
        for (sound in oldMusic) if (sound != null) require(!sound.playing, 'results audio stopped on state exit');
        trace('[Origin results check] CHECKS PASSED character=${params.characterId} rank=$rank animations=${sprites.length}');
        Sys.stdout().flush();
        Sys.exit(0);
      }, 600);
    }
  }

  override public function draw():Void
  {
    super.draw();
    drawn++;
  }

  static function option(name:String, fallback:String):String
  {
    var prefix = '--origin-result-$name=';
    var argument = Sys.args().find(value -> StringTools.startsWith(value, prefix));
    return argument == null ? fallback : argument.substr(prefix.length);
  }

  static function require(condition:Bool, message:String):Void
  {
    if (!condition)
    {
      trace('[Origin results check] FAIL $message');
      Sys.stdout().flush();
      Sys.exit(1);
    }
    trace('[Origin results check] PASS $message');
  }
}
#end
