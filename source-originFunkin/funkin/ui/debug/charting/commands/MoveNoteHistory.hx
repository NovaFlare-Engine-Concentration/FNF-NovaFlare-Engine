package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongNoteDataRaw;

/** Independent note snapshots and instance-aware removal for move history. */
class MoveNoteHistory
{
  public static function snapshot(note:SongNoteData):SongNoteData
  {
    var result = note.clone();
    result.params = note.cloneParams();
    for (param in result.params) param.value = copyChartValue(param.value);
    return result;
  }

  /** Chart parameters are JSON values; copy nested arrays and plain objects. */
  public static function copyChartValue(value:Dynamic):Dynamic
  {
    if (Std.isOfType(value, Array))
    {
      var source:Array<Dynamic> = cast value;
      return [for (item in source) copyChartValue(item)];
    }
    return switch (Type.typeof(value))
    {
      case TObject:
        var result:Dynamic = {};
        for (field in Reflect.fields(value)) Reflect.setField(result, field, copyChartValue(Reflect.field(value, field)));
        result;
      default: value;
    }
  }

  public static function remove(current:Array<SongNoteData>, selected:Array<SongNoteData>):Array<SongNoteData>
  {
    var remaining = current.copy();
    for (note in selected)
    {
      var index = -1;
      for (i in 0...remaining.length)
      {
        var a:SongNoteDataRaw = cast remaining[i];
        var b:SongNoteDataRaw = cast note;
        if (a == b) { index = i; break; }
      }
      if (index < 0)
      {
        for (i in 0...remaining.length)
          if (remaining[i] == note) { index = i; break; }
      }
      if (index >= 0) remaining.splice(index, 1);
    }
    return remaining;
  }
}
#end
