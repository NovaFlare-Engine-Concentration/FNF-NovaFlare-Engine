package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to move a set of notes and events by a given time offset,
 * and shift them by a given number of columns.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MoveItemsCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var movedNotes:Array<SongNoteData>;
  var originalNoteSnapshots:Array<SongNoteData>;
  var events:Array<SongEventData>;
  var movedEvents:Array<SongEventData>;
  var originalEventSnapshots:Array<SongEventData>;
  var offset:Float;
  var columns:Int;

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>, offset:Float, columns:Int, offsetInSteps:Bool = false, roundStepTimeToNearestStep:Bool = false)
  {
    // Clone the notes to prevent editing from affecting the history.
    this.notes = notes.copy();
    this.originalNoteSnapshots = [for (note in notes) MoveNoteHistory.snapshot(note)];
    this.events = events.copy();
    this.originalEventSnapshots = [for (event in events) MoveEventHistory.snapshot(event)];
    if (offsetInSteps)
    {
      this.offset = Conductor.instance.getStepTimeInMs(offset);
    }
    else
    {
      this.offset = offset;
    }
    this.columns = columns;
    this.movedNotes = [];
    this.movedEvents = [];
  }

  /**
   * Perform the action, moving the notes and events.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = MoveNoteHistory.remove(state.currentSongChartNoteData, notes);
    state.currentSongChartEventData = MoveEventHistory.remove(state.currentSongChartEventData, events);

    var firstMove = movedNotes.length == 0;
    var noteIndex = 0;
    var firstEventMove = movedEvents.length == 0;
    var eventIndex = 0;

    for (note in originalNoteSnapshots)
    {
      // Each execution gets a fresh copy; history remains independent.
      var resultNote = MoveNoteHistory.snapshot(note);
      resultNote.time = (resultNote.time + offset).clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));
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

    for (event in originalEventSnapshots)
    {
      var resultEvent = MoveEventHistory.snapshot(event);
      resultEvent.time = (resultEvent.time + offset).clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));

      if (firstEventMove)
      {
        movedEvents.push(resultEvent);
      }
      else
      {
        var existing = movedEvents[eventIndex];
        existing.time = resultEvent.time;
        existing.eventKind = resultEvent.eventKind;
        existing.value = resultEvent.value;
        existing.editorLayer = resultEvent.editorLayer;
      }
      eventIndex++;
    }

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(movedNotes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(movedEvents);
    state.currentNoteSelection = movedNotes;
    state.currentEventSelection = movedEvents;

    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, moving the notes and events back to their original positions.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = MoveNoteHistory.remove(state.currentSongChartNoteData, movedNotes);
    state.currentSongChartEventData = MoveEventHistory.remove(state.currentSongChartEventData, movedEvents);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(events);

    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

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
    return (notes.length > 0 || events.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    var len:Int = notes.length + events.length;
    return 'Move $len Items';
  }
}
#end
