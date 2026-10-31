package moonchart;

import moonchart.backend.*;

class Moonchart
{
	/**
	 * Method used to initialize Moonchart formats for use with ``FormatDetector``
	 * It's recommended to call this at the start of your ``Main`` class of your implementation
	 * @param initFormats (Optional) An array of all the custom formats ``FormatData`` you want to register
	 */
	public static function init(?initFormats:Array<FormatData>):Void
	{
		FormatDetector.init(initFormats);
	}

	/**
	 * If to check for case sensitivity when formatting the difficulty while resolving a chart's notes.
	 */
	public static var CASE_SENSITIVE_DIFFS:Bool = false;

	/**
	 * If to check for space sensitivity when formatting the difficulty while resolving a chart's notes.
	 */
	public static var SPACE_SENSITIVE_DIFFS:Bool = false;

	/**
	 * Default difficulty name when the conversion song difficulty is unknown.
	 * Used as a safe fallback when possible when resolving a chart's notes.
	 */
	public static var DEFAULT_DIFF:String = "default_diff";

	/**
	 * Default artist used when the conversion song artist is unknown.
	 */
	public static var DEFAULT_ARTIST:String = "Unknown";

	/**
	 * Default album used when the conversion song album is unknown.
	 */
	public static var DEFAULT_ALBUM:String = "Unknown";

	/**
	 * Default charter used when the conversion song charter is unknown.
	 */
	public static var DEFAULT_CHARTER:String = "Unknown";

	/**
	 * Default title used when the conversion song title is unknown.
	 */
	public static var DEFAULT_TITLE:String = "Unknown";
}
