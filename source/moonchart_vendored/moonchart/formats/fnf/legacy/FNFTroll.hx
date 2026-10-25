package moonchart.formats.fnf.legacy;

import moonchart.backend.FormatData;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFPsych;

enum abstract FNFTrollNoteType(String) from String to String
{
	var TROLL_MINE = "Mine";
	var TROLL_ROLL = "Roll";
}

class FNFTroll extends FNFPsychBasic<TrollJsonFormat>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_LEGACY_TROLL,
			name: "FNF (Troll Engine)",
			description: "Rainbow Trololo",
			extension: "json",
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
			specialValues: ['?"tracks":', '?"hudSkin":', '?"keyCount:'],
			handler: FNFTroll
		}
	}

	public function new(?data:TrollJsonFormat)
	{
		super(data);
		this.bakedOffset = false;

		// Register FNF Troll note types
		noteTypeResolver.register(FNFTrollNoteType.TROLL_MINE, BasicNoteType.MINE);
		noteTypeResolver.register(FNFTrollNoteType.TROLL_ROLL, BasicNoteType.ROLL);
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFTroll
	{
		var basic = super.fromBasicFormat(chart, diff);
		var song = basic.data.song;

		song.tracks = {
			inst: ['Inst'],
			player: ['Voices-${song.player1}'],
			opponent: ['Voices-${song.player2}']
		}

		var lanes = chart.meta.extraData.get(LANES_LENGTH) ?? 4;
		song.keyCount = Std.int(Math.max(lanes, 8) / 2);

		song.metadata = {
			songName: chart.meta.title,
			artist: chart.meta.extraData.get(SONG_ARTIST),
			charter: chart.meta.extraData.get(SONG_CHARTER)
		}

		song.offset = (chart.meta.offset ?? 0.0);

		return cast basic;
	}

	override function getChartMeta():BasicMetaData
	{
		var meta = super.getChartMeta();
		meta.title = data.song?.metadata?.songName ?? data.song?.song ?? Moonchart.DEFAULT_TITLE;

		var extra = meta.extraData;
		extra.set(SONG_ARTIST, data.song?.metadata?.artist ?? Moonchart.DEFAULT_ARTIST);
		extra.set(SONG_CHARTER, data.song?.metadata?.charter ?? Moonchart.DEFAULT_CHARTER);

		meta.offset = data.song?.offset ?? 0.0;

		return meta;
	}
}

typedef TrollJsonFormat = PsychJsonFormat &
{
	// Troll-specific
	?hudSkin:String,
	?info:Array<String>,
	?metadata:TrollMetadata,
	?offset:Float,
	?tracks:TrollSongTracks,
	?keyCount:Int,

	// deprecated
	?extraTracks:Array<String>,
}

typedef TrollMetadata =
{
	?songName:String,
	?artist:String,
	?charter:String,
	?modcharter:String,
	?extraInfo:Array<String>,
}

typedef TrollSongTracks =
{
	var inst:Array<String>;
	var ?player:Array<String>;
	var ?opponent:Array<String>;
}
