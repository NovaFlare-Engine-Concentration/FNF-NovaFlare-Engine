package codename.funkin.backend.scripting.events.gameplay;

import codename.funkin.backend.scripting.events.CancellableEvent;

/** Imported from CNE 2289c833 with NovaFlare's codename namespace. */
final class BopZoomEvent extends CancellableEvent {
	/** Whether to use the camera zoom multiplier. */
	public var useZoomMultiplier:Bool;
	/** Skip the zoom when the multiplier reaches this limit. */
	public var maxZoomMultiplier:Float;
	/** Strength of the zoom. */
	public var zoomStrength:Float;
}
