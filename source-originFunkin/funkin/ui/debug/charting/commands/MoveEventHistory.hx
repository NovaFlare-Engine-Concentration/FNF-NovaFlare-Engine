package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;

/** Independent event snapshots and instance-aware removal for move history. */
class MoveEventHistory
{
  public static function snapshot(event:SongEventData):SongEventData
  {
    var result = event.clone();
    result.value = MoveNoteHistory.copyChartValue(event.value);
    return result;
  }

  public static function remove(current:Array<SongEventData>, selected:Array<SongEventData>):Array<SongEventData>
  {
    var remaining = current.copy();
    for (event in selected)
    {
      var index = -1;
      for (i in 0...remaining.length)
      {
        var a:SongEventDataRaw = cast remaining[i];
        var b:SongEventDataRaw = cast event;
        if (a == b) { index = i; break; }
      }
      if (index < 0)
      {
        for (i in 0...remaining.length)
          if (remaining[i] == event) { index = i; break; }
      }
      if (index >= 0) remaining.splice(index, 1);
    }
    return remaining;
  }
}
#end
