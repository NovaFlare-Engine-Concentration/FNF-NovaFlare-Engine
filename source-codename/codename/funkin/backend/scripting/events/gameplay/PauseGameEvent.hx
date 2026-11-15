package codename.funkin.backend.scripting.events.gameplay;

import codename.funkin.backend.scripting.events.CancellableEvent;
import codename.funkin.backend.utils.FunkinParentDisabler.ParentDisableable;

/** Imported from CNE 2289c833 with NovaFlare's codename namespace. */
final class PauseGameEvent extends CancellableEvent {
	public var excludeList:Array<ParentDisableable>;
	public var allowGitaroo:Bool;
}
