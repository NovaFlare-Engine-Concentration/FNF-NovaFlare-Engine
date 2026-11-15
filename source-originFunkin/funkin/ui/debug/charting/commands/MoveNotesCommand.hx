package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to move a set of notes by a given time offset,
 * and shift them by a given number of columns.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MoveNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var movedNotes:Array<SongNoteData>;
  var originalNoteSnapshots:Array<SongNoteData>;
  var offset:Float;
  var columns:Int;
  var setPos:Bool;

  public function new(notes:Array<SongNoteData>, offset:Float, columns:Int, setPos:Bool = false, offsetInSteps:Bool = false)
  {
    // Clone the notes to prevent editing from affecting the history.
    this.notes = notes.copy();
    this.originalNoteSnapshots = [for (note in notes) MoveNoteHistory.snapshot(note)];
    if (offsetInSteps)
    {
      this.offset = Conductor.instance.getStepTimeInMs(offset);
    }
    else
    {
      this.offset = offset;
    }
    this.columns = columns;
    this.setPos = setPos;
    this.movedNotes = [];
  }

  /**
   * Perform the action, moving the notes.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = MoveNoteHistory.remove(state.currentSongChartNoteData, notes);

    var firstMove = movedNotes.length == 0;
    var noteIndex = 0;

    for (note in originalNoteSnapshots)
    {
      // Each execution gets a fresh copy; history remains independent.
      var resultNote = MoveNoteHistory.snapshot(note);
      // If setting position, use the offset as the resulting time
      if (setPos)
      {
        resultNote.time = offset.clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));
      }
      else
      {
        resultNote.time = (resultNote.time + offset).clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));
      }
      resultNote.data = ChartEditorState.gridColumnToNoteData(
        (ChartEditorState.noteDataToGridColumn(resultNote.data) + columns).clamp(0, ChartEditorState.STRUMLINE_SIZE * 2 - 1)
      );

      if (firstMove)
      {
        movedNotes.push(resultNote);
      }
      else
      {
        // Later history commands may retain this object across undo/redo.
        var existing = movedNotes[noteIndex];
        existing.time = resultNote.time;
        existing.data = resultNote.data;
        existing.length = resultNote.length;
        existing.kind = resultNote.kind;
        existing.params = resultNote.params;
      }
      noteIndex++;
    }

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(movedNotes);
    state.currentNoteSelection = movedNotes;

    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, moving the notes back to their original positions.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = MoveNoteHistory.remove(state.currentSongChartNoteData, movedNotes);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);

    state.currentNoteSelection = notes;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  /**
   * Whether the command should display in the undo/redo menu.
   * This should be `false` if no real actions were actually performed.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    var len:Int = notes.length;
    return 'Move $len Notes';
  }
}
#end
