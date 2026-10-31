package moonchart.parsers;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import haxe.io.Output;
import moonchart.backend.Util;

typedef MidiFormat =
{
	header:String,
	headerLength:Int,
	format:Int,
	division:Int,
	tracks:Array<MidiTrack>
}

typedef MidiTrack = Array<MidiEvent>;

/**
 * Mostly a copy of https://gitlab.com/haxe-grig/grig.midi/
 * All credits to the original authors
 */
class MidiParser extends BasicParser<MidiFormat>
{
	var tracks:Array<MidiTrack> = [];
	var input:BytesInput;

	// TODO:
	override function encode(data:MidiFormat):Bytes
	{
		var output:Output = new BytesOutput();

		// Write metadata
		output.bigEndian = true;
		output.writeString(data.header);
		output.writeInt32(data.headerLength);
		output.writeUInt16(data.format);
		output.writeUInt16(tracks.length);
		output.writeUInt16(data.division);

		// Write tracks
		for (track in data.tracks)
		{
			output.writeString("MTrk");

			var trackOutput:Output = new BytesOutput();
			trackOutput.bigEndian = true;

			var previousTime:Int = 0;
			for (midiEvent in track)
			{
				var absTime:Int = tickEvent(midiEvent);
				writeVariableBytes(trackOutput, Std.int(absTime - previousTime));
				previousTime = absTime;
				encodeEvent(midiEvent, trackOutput);
			}

			var trackBytes = cast(trackOutput, BytesOutput).getBytes();
			output.writeInt32(trackBytes.length);
			output.writeBytes(trackBytes, 0, trackBytes.length);

			trackOutput.close();
			output.flush();
		}

		return cast(output, BytesOutput).getBytes();
	}

	public function parseBytes(bytes:Bytes):MidiFormat
	{
		tracks.resize(0);

		input = new BytesInput(bytes);
		input.bigEndian = true;

		var header:String = input.readString(4);
		if (header != "MThd")
			throw 'Invalid midi header ($header)';

		var headerLength = input.readInt32();
		if (headerLength != 6)
			throw 'Invalid midi header length ($headerLength)';

		var format = input.readUInt16();
		var tracksLength:Int = input.readUInt16();
		var division = input.readUInt16();

		for (i in 0...tracksLength)
		{
			var track:MidiTrack = new MidiTrack();
			parseTrack(track);
			tracks.push(track);
		}

		return {
			header: header,
			headerLength: headerLength,
			format: format,
			division: division,
			tracks: tracks
		}
	}

	function parseTrack(track:MidiTrack)
	{
		var header:String = input.readString(4);
		if (header != "MTrk")
			throw 'Invalid midi track header ($header)';

		var size:Int = input.readInt32();
		var absoluteTime:Int = 0;
		var lastFlag:Int = 0;

		while (size > 0)
		{
			var variableBytes = readVariableBytes(input);
			size -= variableBytes.length;

			var delta:Int = variableBytes.value;
			absoluteTime += delta;

			var flag = input.readByte();
			size--;

			switch (flag)
			{
				case 0xFF:
					var type = input.readByte();
					var metaLength = readVariableBytes(input);
					size = size - 1 - metaLength.length - metaLength.value;

					var event = MidiEventType.getEvent(type, absoluteTime, metaLength.value, input);
					if (event != null)
						track.push(event);

				case 0xF0:
					var messageBytes = [flag];
					while (true)
					{
						var byte = input.readByte();
						messageBytes.push(byte);
						size--;
						if (byte == 0xF7)
						{
							break;
						}
					}
					track.push(MESSAGE(messageBytes, absoluteTime));
				default:
					var messageType = MidiMessageType.ofByte(flag);
					var messageBytes:Array<Int> = [];
					var runningStatus = false;
					if (messageType == UNKNOWN)
					{
						messageBytes[0] = lastFlag;
						messageType = MidiMessageType.ofByte(lastFlag);
						runningStatus = true;
					}
					else
					{
						messageBytes[0] = flag;
						lastFlag = flag;
					}

					var messageSize = MidiMessageType.sizeForMessageType(messageType);
					if (runningStatus)
						messageSize--;

					for (i in 1...messageSize)
					{
						messageBytes[i] = input.readByte();
						size--;
					}

					track.push(MESSAGE(messageBytes, absoluteTime));
			}
		}
	}

	static function readVariableBytes(input:BytesInput)
	{
		var length:Int = 0;
		var value:Int = input.readByte();
		length++;

		if (value & 0x80 != 0)
		{
			value = value & 0x7F;
			while (true)
			{
				var newByte = input.readByte();
				length++;
				value = (value << 7) + (newByte & 0x7F);
				if (newByte & 0x80 == 0)
				{
					break;
				}
			}
		}

		return {value: value, length: length};
	}

	static function encodeEvent(event:MidiEvent, output:Output)
	{
		switch (event)
		{
			case TEMPO_CHANGE(tempo, tick):
				output.writeByte(0xFF);
				output.writeByte(0x51);
				output.writeByte(0x03);
				output.writeUInt24(Std.int(60000000 / tempo));

			case TIME_SIGNATURE(num, den, clock, quarter, tick):
				output.writeByte(0xFF);
				output.writeByte(0x58);
				output.writeByte(0x04);
				output.writeByte(num);
				output.writeByte(den);
				output.writeByte(clock);
				output.writeByte(quarter);

			case KEY_SIGNATURE(numSharps, isMinor, tick):
				output.writeByte(0xFF);
				output.writeByte(0x59);
				output.writeByte(0x02);
				output.writeByte(numSharps);
				output.writeByte(isMinor ? 1 : 0);

			case MESSAGE(byteArray, tick):
				for (byte in byteArray)
					output.writeByte(byte);

			case END_TRACK(tick):
				output.writeByte(0xFF);
				output.writeByte(0x2F);
				output.writeByte(0x00);

			case TEXT(text, tick, type):
				output.writeByte(0xFF);
				output.writeByte(type);

				var bytes = Bytes.ofString(text, UTF8);
				writeVariableBytes(output, bytes.length, null);
				output.writeBytes(bytes, 0, bytes.length);
		}
	}

	static function writeVariableBytes(output:Output, value:Int, lengthToWrite:Null<Int> = null):Void
	{
		var byte:Int = 0;
		var started:Bool = false;
		var shiftAmount:Int = 4; // Supporting at max 32-bit integers
		var lengthWritten:Int = 0;

		while (true)
		{
			byte = (value >> (7 * shiftAmount)) & 0x7f;
			shiftAmount -= 1;
			if (byte == 0 && !started && shiftAmount >= 0)
				continue;
			started = true;
			lengthWritten += 1;

			var isFinalByte:Bool = false;
			if (lengthToWrite != null)
			{
				if (lengthWritten > lengthToWrite)
				{
					throw "Exceeded maximum write amount";
				}
				else if (lengthWritten == lengthToWrite)
				{
					isFinalByte = true;
				}
			}
			else if (shiftAmount < 0)
			{
				isFinalByte = true;
			}

			if (!isFinalByte)
			{
				byte |= 0x80;
			}

			output.writeByte(byte);

			if (isFinalByte)
			{
				break;
			}
		}
	}

	static function tickEvent(event:MidiEvent):Int
	{
		return switch (event)
		{
			case TEMPO_CHANGE(tempo, tick): tick;
			case TIME_SIGNATURE(num, den, clock, quarter, tick): tick;
			case KEY_SIGNATURE(numSharps, isMinor, tick): tick;
			case MESSAGE(byteArray, tick): tick;
			case END_TRACK(tick): tick;
			case TEXT(text, tick, type): tick;
		}
	}
}

enum MidiEvent
{
	TEMPO_CHANGE(tempo:Int, tick:Int);
	TIME_SIGNATURE(num:Int, den:Int, clock:Int, quarter:Int, tick:Int);
	KEY_SIGNATURE(numSharps:Int, isMinor:Bool, tick:Int);
	MESSAGE(byteArray:Array<Int>, tick:Int);
	END_TRACK(tick:Int);
	TEXT(text:String, tick:Int, type:MidiTextType);
}

enum abstract MidiTextType(MidiEventType) from MidiEventType to MidiEventType from Int to Int
{
	var TEXT_EVENT = 0x01;
	var TRACK_NAME_EVENT = 0x03;
}

enum abstract MidiEventType(Int) from Int to Int
{
	var SEQUENCE_EVENT = 0x00;
	var CHANNEL_PREFIX_EVENT = 0x20;
	var PORT_PREFIX_EVENT = 0x21;
	var END_TRACK_EVENT = 0x2F;
	var TEMPO_CHANGE_EVENT = 0x51;
	var OFFSET_EVENT = 0x54;
	var TIME_SIGNATURE_EVENT = 0x58;
	var KEY_SIGNATURE_EVENT = 0x59;
	var SEQUENCER_SPECIFIC_EVENT = 0x7F;

	public static function getEvent(type:MidiEventType, tick:Int, metaLength:Int, input:BytesInput):MidiEvent
	{
		return switch (type)
		{
			case TEXT_EVENT | TRACK_NAME_EVENT: TEXT(input.readString(metaLength), tick, type); // General text
			// case SEQUENCE_EVENT: null;
			// case CHANNEL_PREFIX_EVENT: null;
			// case PORT_PREFIX_EVENT: null;
			case END_TRACK_EVENT: END_TRACK(tick);
			case TEMPO_CHANGE_EVENT: TEMPO_CHANGE(Std.int(60000000 / input.readUInt24()), tick);
			// case OFFSET_EVENT: null;
			case TIME_SIGNATURE_EVENT: TIME_SIGNATURE(input.readByte(), input.readByte(), input.readByte(), input.readByte(), tick);
			case KEY_SIGNATURE_EVENT: KEY_SIGNATURE(input.readByte(), input.readByte() == 1, tick);
			// case SEQUENCER_SPECIFIC_EVENT: null;
			default:
				throw 'Invalid midi event type ($type)';
		}
	}
}

enum abstract MidiMessageType(Int) from Int to Int
{
	var NOTE_OFF = 0x80;
	var NOTE_ON = 0x90;
	var POLY_PRESSURE = 0xA0;
	var CONTROL_CHANGE = 0xB0;
	var PROGRAM_CHANGE = 0xC0;
	var PRESSURE = 0xD0;
	var PITCH = 0xE0;
	var SYS_EX = 0xF0;
	var TIME_CODE = 0xF1;
	var SONG_POSITION = 0xF2;
	var SONG_SELECT = 0xF3;
	var TUNE_REQUEST = 0xF6;
	var TIME_CLOCK = 0xF8;
	var START = 0xFA;
	var CONTINUE = 0xFB;
	var STOP = 0xFC;
	var KEEP_ALIVE = 0xFE;
	var RESET = 0xFF;
	var UNKNOWN = 0;

	public static function ofByte(byte:Int):MidiMessageType
	{
		return switch (byte >> 0x04)
		{
			case 0x8: NOTE_OFF;
			case 0x9: NOTE_ON;
			case 0xA: POLY_PRESSURE;
			case 0xB: CONTROL_CHANGE;
			case 0xC: PROGRAM_CHANGE;
			case 0xD: PRESSURE;
			case 0xE: PITCH;
			case 0xF: {
					switch (byte & 0xF)
					{
						case 0x0: SYS_EX;
						case 0x1: TIME_CODE;
						case 0x2: SONG_POSITION;
						case 0x3: SONG_SELECT;
						case 0x6: TUNE_REQUEST;
						case 0x8: TIME_CLOCK;
						case 0xA: START;
						case 0xB: CONTINUE;
						case 0xC: STOP;
						case 0xE: KEEP_ALIVE;
						case 0xF: RESET;
						default: UNKNOWN;
					}
				}
			default: UNKNOWN;
		}
	}

	public static function sizeForMessageType(type:MidiMessageType):Int
	{
		return switch (type)
		{
			case NOTE_ON: 3;
			case NOTE_OFF: 3;
			case POLY_PRESSURE: 3;
			case CONTROL_CHANGE: 3;
			case PROGRAM_CHANGE: 2;
			case PRESSURE: 2;
			case PITCH: 3;
			case TIME_CODE: 2;
			case SONG_POSITION: 3;
			case SONG_SELECT: 2;
			case TUNE_REQUEST: 1;
			case TIME_CLOCK: 1;
			case START: 1;
			case CONTINUE: 1;
			case STOP: 1;
			case KEEP_ALIVE: 1;
			case RESET: 1;
			case SYS_EX: throw "Cannot determine length of sysex messages ahead of time";
			case UNKNOWN: throw 'Unknown midi message type: $type';
		}
	}
}
