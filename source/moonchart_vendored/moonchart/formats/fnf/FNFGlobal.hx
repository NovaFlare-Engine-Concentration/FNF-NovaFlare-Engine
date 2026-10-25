package moonchart.formats.fnf;

import moonchart.backend.Resolver;
import moonchart.formats.BasicFormat.BasicEvent;
import moonchart.formats.BasicFormat.BasicNoteType;
import moonchart.formats.fnf.legacy.*;

abstract FNFLegacyNoteType(Dynamic) from Int to Int from String to String from Dynamic to Dynamic {}

enum abstract BasicFNFNoteType(String) from String to String from BasicNoteType to BasicNoteType
{
	var CHEER;
	var ALT_ANIM;
	var NO_ANIM;
	var GF_SING;
	var CENSOR;
}

enum abstract BasicFNFNoteSkin(String) from String to String
{
	var DEFAULT_SKIN = "";
	var PIXEL_SKIN;
}

enum abstract BasicFNFCamFocus(Int) from Int to Int
{
	var BF = 0;
	var DAD = 1;
	var GF = 2;
}

typedef BasicFNFCamFocusData =
{
	char:BasicFNFCamFocus,
	ease:String,
}

enum abstract BasicFNFEvent(String) from String to String
{
	var PLAY_ANIMATION;
	var ZOOM_CAMERA;
	var POSITION_CAMERA;
	var SET_CAMERA_BOP;
}

typedef BasicFNFPlayAnimEvent =
{
	var target:String;
	var anim:String;
	var force:Bool;
}

typedef BasicFNFZoomCameraEvent =
{
	var zoom:Float;
	var duration:Float;
	var ease:String;
	var mode:String;
}

typedef BasicFNFSetCameraBopEvent =
{
	var rate:Int;
	var offset:Int;
	var intensity:Float;
}

typedef BasicFNFPositionCameraEvent =
{
	var char:Int;
	var x:Float;
	var y:Float;
	var ease:String;
	var duration:Float;
	var isOffset:Bool;
}

/**
 * This class is **NOT** a Moonchart format, its made as a linker between other FNF formats
 * Since FNF formats have a lot of shared data but different ways to represent it
 */
class FNFGlobal
{
	/**
	 * Creates a ``FNFNoteTypeResolver`` instance for use with FNF Note types
	 * TODO: should prob make this a basic class with an FNF extension of it
	 */
	public static inline function createNoteTypeResolver(?defaultNote:String = BasicNoteType.DEFAULT):FNFNoteTypeResolver
	{
		return new FNFNoteTypeResolver(defaultNote, BasicNoteType.DEFAULT);
	}

	/**
	 * This is the main place where you want to store ways to resolve FNF cam movement events.
	 * The resolve method should always return a ``BasicFNFCamFocus``.
	 */
	public static var camFocus(get, null):Map<String, BasicEvent->BasicFNFCamFocus>;

	/**
	 * Resolves the cam target value from a cam focus event
	 */
	public static inline function resolveCamFocus(event:BasicEvent):BasicFNFCamFocus
	{
		return camFocus.get(event.name)(event);
	}

	/**
	 * Checks if an event is registered as a cam focus event
	 */
	public static inline function isCamFocus(event:BasicEvent):Bool
	{
		return camFocus.exists(event.name);
	}

	/**
	 * Removes internal funkin events from an array of events
	 * Such as cam focus events
	 */
	public static inline function filterEvents(events:Array<BasicEvent>):Array<BasicEvent>
	{
		return events.filter((e) -> return !isCamFocus(e));
	}

	private static function get_camFocus()
	{
		if (camFocus != null)
			return camFocus;

		camFocus = [];
		camFocus.set(FNFLegacy.FNF_LEGACY_MUST_HIT_SECTION_EVENT, (e) -> e.data.mustHitSection ? BF : DAD);
		camFocus.set(FNFVSlice.VSLICE_FOCUS_EVENT, (e) ->
		{
			return (e.data is Int) ? e.data : Std.parseInt(Std.string(e.data.char));
		});
		camFocus.set(FNFCodename.CODENAME_CAM_MOVEMENT, (e) ->
		{
			return switch (e.data.array[0])
			{
				case 0: DAD;
				case 1: BF;
				default: GF;
			}
		});

		return camFocus;
	}
}

class FNFNoteTypeResolver extends Resolver<FNFLegacyNoteType, BasicFNFNoteType>
{
	public var keepIfUnknown:Bool = true;

	override function toBasic(?ID:FNFLegacyNoteType):BasicFNFNoteType
	{
		if (ID == null)
			return defToBasic;

		var strID:String = Std.string(ID);
		if (!_to.exists(strID))
			return keepIfUnknown ? strID : defToBasic;

		return super.toBasic(ID);
	}
}
