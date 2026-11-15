package funkin.play.scoring;

import flixel.util.FlxColor;
import funkin.save.Save.SaveScoreData;
import funkin.save.Save.SaveScoreTallyData;

/** Historical scoring systems remain available to Origin mod scripts. */
enum abstract ScoringSystem(String)
{
  public var LEGACY;
  public var WEEK7;
  public var PBOT1;
}

/**
 * A static class which holds any functions related to scoring.
 */
class Scoring
{
  // Public values retained from the official pre-miniaudio scoring API.
  public static final LEGACY_HIT_WINDOW:Float = (10 / 60) * 1000;
  public static final LEGACY_SICK_THRESHOLD:Float = 0.2;
  public static final LEGACY_GOOD_THRESHOLD:Float = 0.75;
  public static final LEGACY_BAD_THRESHOLD:Float = 0.9;
  public static final LEGACY_SHIT_THRESHOLD:Float = 1.0;
  public static final LEGACY_SICK_SCORE:Int = 350;
  public static final LEGACY_GOOD_SCORE:Int = 200;
  public static final LEGACY_BAD_SCORE:Int = 100;
  public static final LEGACY_SHIT_SCORE:Int = 50;
  public static final LEGACY_MISS_SCORE:Int = -10;
  public static final WEEK7_HIT_WINDOW:Float = LEGACY_HIT_WINDOW;
  public static final WEEK7_BAD_THRESHOLD:Float = 0.8;
  public static final WEEK7_GOOD_THRESHOLD:Float = 0.55;
  public static final WEEK7_SICK_THRESHOLD:Float = 0.2;
  public static final WEEK7_MISS_SCORE:Int = -10;
  public static final WEEK7_SHIT_SCORE:Int = 50;
  public static final WEEK7_BAD_SCORE:Int = 100;
  public static final WEEK7_GOOD_SCORE:Int = 200;
  public static final WEEK7_SICK_SCORE:Int = 350;

  static function historicalScore(msTiming:Float, week7:Bool):Int
  {
    var timing = Math.abs(msTiming);
    var good = week7 ? WEEK7_GOOD_THRESHOLD : LEGACY_GOOD_THRESHOLD;
    var bad = week7 ? WEEK7_BAD_THRESHOLD : LEGACY_BAD_THRESHOLD;
    if (timing < LEGACY_HIT_WINDOW * LEGACY_SICK_THRESHOLD) return LEGACY_SICK_SCORE;
    if (timing < LEGACY_HIT_WINDOW * good) return LEGACY_GOOD_SCORE;
    if (timing < LEGACY_HIT_WINDOW * bad) return LEGACY_BAD_SCORE;
    if (timing < LEGACY_HIT_WINDOW) return LEGACY_SHIT_SCORE;
    return 0;
  }

  static function historicalJudgement(msTiming:Float, week7:Bool):String
  {
    var timing = Math.abs(msTiming);
    var good = week7 ? WEEK7_GOOD_THRESHOLD : LEGACY_GOOD_THRESHOLD;
    var bad = week7 ? WEEK7_BAD_THRESHOLD : LEGACY_BAD_THRESHOLD;
    if (timing <= LEGACY_HIT_WINDOW * LEGACY_SICK_THRESHOLD) return 'sick';
    if (timing <= LEGACY_HIT_WINDOW * good) return 'good';
    if (timing <= LEGACY_HIT_WINDOW * bad) return 'bad';
    if (timing <= LEGACY_HIT_WINDOW) return 'shit';
    FlxG.log.warn('Missed note: Bad timing ($timing > $LEGACY_HIT_WINDOW)');
    return 'miss';
  }


  /**
   * Determine the score a note receives under a given scoring system.
   * @param msTiming The difference between the note's time and when it was hit.
   * @return The score the note receives.
   */
  public static function scoreNote(msTiming:Float, scoringSystem:ScoringSystem = PBOT1):Int
  {
    switch (scoringSystem)
    {
      case LEGACY: return historicalScore(msTiming, false);
      case WEEK7: return historicalScore(msTiming, true);
      case PBOT1: {}
      default:
        FlxG.log.error('Unknown scoring system: $scoringSystem');
        return 0;
    }
    // Absolute value because otherwise late hits are always given the max score.
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      case(_ > PBOT1_MISS_THRESHOLD) => true:
        PBOT1_MISS_SCORE;
      case(_ < PBOT1_PERFECT_THRESHOLD) => true:
        PBOT1_MAX_SCORE;
      default:
        // Fancy equation.
        var factor:Float = 1.0 - (1.0 / (1.0 + Math.exp(-PBOT1_SCORING_SLOPE * (absTiming - PBOT1_SCORING_OFFSET))));

        var score:Int = Std.int(PBOT1_MAX_SCORE * factor + PBOT1_MIN_SCORE);

        score;
    }
  }

  /**
   * Determine the judgement a note receives under a given scoring system.
   * @param msTiming The difference between the note's time and when it was hit.
   * @return The judgement the note receives.
   */
  public static function judgeNote(msTiming:Float, scoringSystem:ScoringSystem = PBOT1):String
  {
    switch (scoringSystem)
    {
      case LEGACY: return historicalJudgement(msTiming, false);
      case WEEK7: return historicalJudgement(msTiming, true);
      case PBOT1: {}
      default:
        FlxG.log.error('Unknown scoring system: $scoringSystem');
        return 'miss';
    }
    var absTiming:Float = Math.abs(msTiming);

    return switch (absTiming)
    {
      // case(_ <= PBOT1_KILLER_THRESHOLD) => true:
      //   'killer';
      case(_ <= PBOT1_SICK_THRESHOLD) => true:
        'sick';
      case(_ <= PBOT1_GOOD_THRESHOLD) => true:
        'good';
      case(_ <= PBOT1_BAD_THRESHOLD) => true:
        'bad';
      case(_ <= PBOT1_SHIT_THRESHOLD) => true:
        'shit';
      default:
        FlxG.log.warn('Missed note: Bad timing ($absTiming < $PBOT1_SHIT_THRESHOLD)');
        'miss';
    }
  }

  public static function getMissScore(scoringSystem:ScoringSystem = PBOT1):Int
  {
    return switch (scoringSystem)
    {
      case LEGACY: LEGACY_MISS_SCORE;
      case WEEK7: WEEK7_MISS_SCORE;
      case PBOT1: PBOT1_MISS_SCORE;
      default:
        FlxG.log.error('Unknown scoring system: $scoringSystem');
        0;
    };
  }

  /**
   * The maximum score a note can receive.
   */
  public static final PBOT1_MAX_SCORE:Int = 500;

  /**
   * The offset of the sigmoid curve for the scoring function.
   */
  public static final PBOT1_SCORING_OFFSET:Float = 54.99;

  /**
   * The slope of the sigmoid curve for the scoring function.
   */
  public static final PBOT1_SCORING_SLOPE:Float = 0.080;

  /**
   * The minimum score a note can receive while still being considered a hit.
   */
  public static final PBOT1_MIN_SCORE:Float = 9.0;

  /**
   * The score a note receives when it is missed.
   */
  public static final PBOT1_MISS_SCORE:Int = -100;

  /**
   * The threshold at which a note hit is considered perfect and always given the max score.
   */
  public static final PBOT1_PERFECT_THRESHOLD:Float = 5.0; // 5ms

  /**
   * The threshold at which a note hit is considered missed.
   * `160ms`
   */
  public static final PBOT1_MISS_THRESHOLD:Float = 160.0;

  /**
   * The time within which a note is considered to have been hit with the Killer judgement.
   * `~7.5% of the hit window, or 12.5ms`
   */
  public static final PBOT1_KILLER_THRESHOLD:Float = 12.5;

  /**
   * The time within which a note is considered to have been hit with the Sick judgement.
   * `~25% of the hit window, or 45ms`
   */
  public static final PBOT1_SICK_THRESHOLD:Float = 45.0;

  /**
   * The time within which a note is considered to have been hit with the Good judgement.
   * `~55% of the hit window, or 90ms`
   */
  public static final PBOT1_GOOD_THRESHOLD:Float = 90.0;

  /**
   * The time within which a note is considered to have been hit with the Bad judgement.
   * `~85% of the hit window, or 135ms`
   */
  public static final PBOT1_BAD_THRESHOLD:Float = 135.0;

  /**
   * The time within which a note is considered to have been hit with the Shit judgement.
   * `100% of the hit window, or 160ms`
   */
  public static final PBOT1_SHIT_THRESHOLD:Float = 160.0;

  public static function calculateRank(scoreData:Null<SaveScoreData>):Null<ScoringRank>
  {
    if (scoreData?.tallies.totalNotes == 0 || scoreData == null) return null;

    // we can return null here, meaning that the player hasn't actually played and finished the song (thus has no data)
    if (scoreData.tallies.totalNotes == 0) return null;

    // Perfect (Gold) is a Sick Full Clear
    if (scoreData.tallies.sick == scoreData.tallies.totalNotes)
    {
      return ScoringRank.PERFECT_GOLD;
    }

    // Else, use the standard grades

    // Final Grade = (Sick + Good - Miss) / (Total Notes)

    var completionAmount:Float = Scoring.tallyCompletion(scoreData.tallies);

    if (completionAmount == Constants.RANK_PERFECT_THRESHOLD)
    {
      return ScoringRank.PERFECT;
    }
    else if (completionAmount >= Constants.RANK_EXCELLENT_THRESHOLD)
    {
      return ScoringRank.EXCELLENT;
    }
    else if (completionAmount >= Constants.RANK_GREAT_THRESHOLD)
    {
      return ScoringRank.GREAT;
    }
    else if (completionAmount >= Constants.RANK_GOOD_THRESHOLD)
    {
      return ScoringRank.GOOD;
    }
    else
    {
      return ScoringRank.SHIT;
    }
  }

  /**
   * Calculates the "completion" of a song, based on how many GOOD and SICK notes were hit, minus how many were missed
   * Top secret funkin crew patented algorithm
   * TODO: Could possibly move more of the "tallying" related handling here.
   *       In FreeplayState we make sure it's clamped between 0 and 1, and we probably always want to assume that?
   *
   * @param tallies
   * @return Float Completion, as a float value between 0 and 1. If `tallies` is `null`, we return 0;
   */
  public static function tallyCompletion(?tallies:SaveScoreTallyData):Float
  {
    if (tallies == null) return 0.0;
    return ((
      tallies.sick
      + tallies.good
      - tallies.missed
    ) / tallies.totalNotes).clamp(0, 1); // Needs to be clamped to make sure Perfect ranks are saved properly
  }
}

enum abstract ScoringRank(String)
{
  public var PERFECT_GOLD;
  public var PERFECT;
  public var EXCELLENT;
  public var GREAT;
  public var GOOD;
  public var SHIT;

  /** Results music names exposed by Origin v0.4.0-v0.4.1. */
  public function getMusicPath():String
  {
    return switch (abstract)
    {
      case PERFECT_GOLD | PERFECT: 'resultsPERFECT';
      case EXCELLENT: 'resultsEXCELLENT';
      case GREAT | GOOD: 'resultsNORMAL';
      case SHIT: 'resultsSHIT';
      default: 'resultsNORMAL';
    };
  }

  public function hasMusicIntro():Bool
  {
    return switch (abstract)
    {
      case EXCELLENT | SHIT: true;
      default: false;
    };
  }

  public function shouldMusicLoop():Bool
  {
    return switch (abstract)
    {
      case PERFECT_GOLD | PERFECT | EXCELLENT | GREAT | GOOD: true;
      default: false;
    };
  }

  /**
   * Converts ScoringRank to an integer value for comparison.
   * Better ranks should be tied to a higher value.
   */
  static function getValue(rank:Null<ScoringRank>):Int
  {
    if (rank == null) return -1;
    switch (rank)
    {
      case PERFECT_GOLD:
        return 5;
      case PERFECT:
        return 4;
      case EXCELLENT:
        return 3;
      case GREAT:
        return 2;
      case GOOD:
        return 1;
      case SHIT:
        return 0;
      default:
        return -1;
    }
  }

  // Yes, we really need a different function for each comparison operator.
  @:op(A > B)
  static function compareGT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 > temp2;
  }

  // Greater than or equal to comparison
  @:op(A >= B)
  static function compareGTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 >= temp2;
  }

  // Less than comparison
  @:op(A < B)
  static function compareLT(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 < temp2;
  }

  // Less than or equal to comparison
  @:op(A <= B)
  static function compareLTEQ(a:Null<ScoringRank>, b:Null<ScoringRank>):Bool
  {
    if (a != null && b == null) return true;
    if (a == null || b == null) return false;

    var temp1:Int = getValue(a);
    var temp2:Int = getValue(b);

    return temp1 <= temp2;
  }

  // @:op(A == B) isn't necessary!

  /**
   * Delay in seconds
   */
  public function getMusicDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        return 95 / 24;
      case EXCELLENT:
        return 0;
      case GREAT:
        return 5 / 24;
      case GOOD:
        return 3 / 24;
      case SHIT:
        return 2 / 24;
      default:
        return 2 / 24;
    }
  }

  public function getBFDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        return 95 / 24;
      case EXCELLENT:
        return 97 / 24;
      case GREAT:
        return 95 / 24;
      case GOOD:
        return 95 / 24;
      case SHIT:
        return 95 / 24;
      default:
        return 95 / 24;
    }
  }

  public function getFlashDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        return 129 / 24;
      case EXCELLENT:
        return 122 / 24;
      case GREAT:
        return 109 / 24;
      case GOOD:
        return 107 / 24;
      case SHIT:
        return 186 / 24;
      default:
        return 186 / 24;
    }
  }

  public function getHighscoreDelay():Float
  {
    switch (abstract)
    {
      case PERFECT_GOLD | PERFECT:
        return 140 / 24;
      case EXCELLENT:
        return 140 / 24;
      case GREAT:
        return 129 / 24;
      case GOOD:
        return 127 / 24;
      case SHIT:
        return 207 / 24;
      default:
        return 207 / 24;
    }
  }

  public function getFreeplayRankIconAsset():String
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return 'PERFECTSICK';
      case PERFECT:
        return 'PERFECT';
      case EXCELLENT:
        return 'EXCELLENT';
      case GREAT:
        return 'GREAT';
      case GOOD:
        return 'GOOD';
      case SHIT:
        return 'LOSS';
      default:
        return 'LOSS';
    }
  }

  public function getHorTextAsset():String
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return Paths.image('ui/results/rank-text/scroll-perfect');
      case PERFECT:
        return Paths.image('ui/results/rank-text/scroll-perfect');
      case EXCELLENT:
        return Paths.image('ui/results/rank-text/scroll-excellent');
      case GREAT:
        return Paths.image('ui/results/rank-text/scroll-great');
      case GOOD:
        return Paths.image('ui/results/rank-text/scroll-good');
      case SHIT:
        return Paths.image('ui/results/rank-text/scroll-loss');
      default:
        return Paths.image('ui/results/rank-text/scroll-loss');
    }
  }

  public function getVerTextAsset():String
  {
    switch (abstract)
    {
      case PERFECT_GOLD:
        return Paths.image('ui/results/rank-text/text-perfect');
      case PERFECT:
        return Paths.image('ui/results/rank-text/text-perfect');
      case EXCELLENT:
        return Paths.image('ui/results/rank-text/text-excellent');
      case GREAT:
        return Paths.image('ui/results/rank-text/text-great');
      case GOOD:
        return Paths.image('ui/results/rank-text/text-good');
      case SHIT:
        return Paths.image('ui/results/rank-text/text-loss');
      default:
        return Paths.image('ui/results/rank-text/text-loss');
    }
  }

  public function getRankingFreeplayColor():FlxColor
  {
    return switch (abstract)
    {
      case SHIT:
        0xFF6044FF;
      case GOOD:
        0xFFEF8764;
      case GREAT:
        0xFFEAF6FF;
      case EXCELLENT:
        0xFFFDCB42;
      case PERFECT:
        0xFFFF58B4;
      case PERFECT_GOLD:
        0xFFFFB619;
      default:
        0xFF6044FF;
    }
  }

  public function toString():String
  {
    return this;
  }
}
