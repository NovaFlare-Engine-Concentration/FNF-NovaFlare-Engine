This editor is adapted from [FNF-PsychEngine-Mobile-1.0.4-Archive](https://github.com/kittycathy233/FNF-PsychEngine-Mobile-1.0.4-Archive), commit `8e33eafecb7e3460a35cd73583fb02476dbf3c33`. The upstream license is included in this directory.

NovaFlare keeps song-wide timing, extra-key lanes and its own editor playtest. Legacy Psych charts use section-relative lanes on disk; the editor converts them to absolute lanes while editing and converts a copy back when saving. Section data and notes beyond the audio duration must not be discarded.

In the Song tab, use **Keys per Side** to choose a mode supported by NovaFlare (1K–10K with the default configuration). Changing modes preserves each note's side and lane. Move notes off lanes that will be removed before reducing the key count. Key count changes can be undone and clear the copied notes.

Click or tap a note and release to delete it. Drag directly to move a note. Use Shift+click on desktop or hold S while tapping on mobile to select multiple notes, then drag one selected note to move the group. Right-click or Escape cancels a mouse drag. Dragging follows the tempo map and retains undo data.

In Vortex mode, 1–8 address the available lanes in 1K–4K charts. For 5K and above, use 1–0 for the player's lanes and Shift+1–0 for the opponent's lanes.
