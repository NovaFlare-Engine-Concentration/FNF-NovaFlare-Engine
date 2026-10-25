package moonchart.formats.fnf.legacy;

import moonchart.backend.FormatData;
import moonchart.backend.Util.OneOfArray;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFPsych;

// TODO:
// implement event / note type translation
// parse metadata, lyrics & extra files
// include file naming scheme for FormatDetector
class FNFNmv extends FNFPsychBasic<NmvJsonFormat>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_LEGACY_NMV,
			name: "FNF (Nightmare Vision)",
			description: "I'm Nightmare Freddy and I'm in your bed",
			extension: "json",
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
			specialValues: ['?"arrowSkins":', '?"keys":', '?"lanes":'],
			handler: FNFNmv
		}
	}

	public static inline var NMV_DEFAULT_NOTE_SKIN:String = "default";

	public function new(?data:NmvJsonFormat)
	{
		super(data);
		this.legacyExport = true;
		this.legacyPsychOutputFormat = "nmv2";
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFPsychBasic<NmvJsonFormat>
	{
		var basic = super.fromBasicFormat(chart, diff);
		var song = basic.data.song;

		song.lanes = OneOfArray.nullResolve(chart.meta.extraData.get(BasicMetaValues.STRUMLINE_LANES), 4);
		song.keys = OneOfArray.nullResolve(chart.meta.extraData.get(BasicMetaValues.STRUMLINE_KEYS), 4);

		var skins = ((chart.meta.extraData.get(BasicMetaValues.SONG_NOTE_SKIN) ?? NMV_DEFAULT_NOTE_SKIN) : OneOfArray<String>).resolve();
		while (skins.length < song.lanes)
			skins.push(NMV_DEFAULT_NOTE_SKIN);

		song.arrowSkins = skins;

		song.format = "nmv2";

		return basic;
	}

	override function getChartMeta():BasicMetaData
	{
		var meta = super.getChartMeta();

		meta.extraData.set(BasicMetaValues.LANES_LENGTH, data.song.lanes * data.song.keys);
		meta.extraData.set(BasicMetaValues.STRUMLINE_LANES, data.song.lanes);
		meta.extraData.set(BasicMetaValues.STRUMLINE_KEYS, data.song.keys);
		meta.extraData.set(BasicMetaValues.SONG_NOTE_SKIN, data.song.arrowSkins);

		return meta;
	}
}

typedef NmvMetadata =
{
	composer:String,
	fontSize:Int,
	description:String
}

typedef NmvJsonFormat = PsychJsonFormat &
{
	keys:Int,
	arrowSkins:Array<String>,
	lanes:Int
}

typedef NmvLyricsJson =
{
	stuff:Array<{lyric:String, timestamp:Float, color:String}>
}
