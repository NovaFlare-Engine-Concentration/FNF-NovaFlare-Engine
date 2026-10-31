package moonchart.backend;

import moonchart.formats.*;
import moonchart.formats.BasicFormat.DynamicFormat;
import moonchart.formats.fnf.*;
import moonchart.formats.fnf.legacy.*;

enum abstract PossibleValue(Int) from Int to Int
{
	var FALSE;
	var TRUE;
	var POSSIBLE;
}

enum abstract Format(String) from String to String
{
	var FNF_LEGACY;
	var FNF_LEGACY_PSYCH;
	var FNF_LEGACY_TROLL;
	var FNF_LEGACY_NMV;
	var FNF_LEGACY_FPS_PLUS;
	var FNF_KADE;
	var FNF_MARU;
	var FNF_CODENAME;
	var FNF_LUDUM_DARE;
	var FNF_VSLICE;
	var GUITAR_HERO;
	var OSU_MANIA;
	var QUAVER;
	var STEPMANIA;
	var STEPMANIA_SHARK;
	var MIDI;

	/**
	 * Returns the hardcoded list of format data by default Moonchart.
	 * To add extra formats for custom implementations use ``moonchart.backend.FormatDetector.registerFormat``.
	 */
	public static function getList():Array<FormatData>
	{
		return [
			FNFLegacy.__getFormat(),
			FNFPsych.__getFormat(),
			FNFTroll.__getFormat(),
			FNFNmv.__getFormat(),
			FNFFpsPlus.__getFormat(),
			FNFKade.__getFormat(),
			FNFCodename.__getFormat(),
			FNFLudumDare.__getFormat(),
			FNFVSlice.__getFormat(),
			GuitarHero.__getFormat(),
			OsuMania.__getFormat(),
			Quaver.__getFormat(),
			StepMania.__getFormat(),
			StepManiaShark.__getFormat(),
			Midi.__getFormat()
		];
	}
}

typedef FormatData =
{
	ID:Format,
	name:String,
	description:String,
	extension:String,
	hasMetaFile:PossibleValue,
	?metaFileExtension:String,
	?packedExtension:String,

	/**
	 * Special values are an array of strings that the format detector
	 * may use if theres conflicts between formats of the same extension.
	 *
	 * Note that, to skip unnecesary parsing, this will check for RAW parts of the string.
	 * In other words, if you want to check for a value in a JSON file, you should format the value.
	 * Like this: ``'"someJsonValue":'``
	 *
	 * You can also set how important these values are with a prefix, heres the list of available prefixes:
	 * `(blank)`: Value MUST be in the chart
	 * `_`: Important value that MUST be in the chart
	 * `?`: Value that can OPTIONALLY be inside the chart
	 */
	?specialValues:Array<String>,

	?findMeta:Array<String>->String,
	?formatFile:(String, String) -> Array<String>,
	handler:Class<DynamicFormat>
}
