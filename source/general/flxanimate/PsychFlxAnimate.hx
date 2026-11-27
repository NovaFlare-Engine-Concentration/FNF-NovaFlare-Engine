package general.flxanimate;

import flixel.util.FlxDestroyUtil;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.AnimationData;
import flxanimate.FlxAnimate as OriginalFlxAnimate;

class PsychFlxAnimate extends OriginalFlxAnimate
{
	var nextSequenceSymbol:Int = 0;
	final frameSequenceSymbols:Map<String, String> = [];

	public function addFrameSequence(sequence:AtlasFrameSequence):Bool
	{
		final symbols = anim.symbolDictionary;
		final source = symbols == null ? null : symbols.get(sequence.name);
		if (source == null || source.length <= 0 || sequence.indices.length == 0) return false;

		// flxanimate uses its registration name as a dictionary key, which can overwrite an exported symbol.
		var symbolName:String;
		do {
			symbolName = '__novaflare_frame_sequence_${nextSequenceSymbol++}';
		} while (symbolName == sequence.anim || symbols.exists(symbolName) || anim.existsByName(symbolName));
		anim.addBySymbolIndices(symbolName, sequence.name, sequence.indices, sequence.fps, sequence.loop);

		final registration = anim.getByName(symbolName);
		if (registration == null) return false;
		discardFrameSequence(sequence.anim);
		@:privateAccess anim.animsMap.remove(symbolName);
		@:privateAccess anim.animsMap.set(sequence.anim, registration);
		frameSequenceSymbols.set(sequence.anim, symbolName);
		return true;
	}

	public function discardFrameSequence(name:String):Void
	{
		final symbolName = frameSequenceSymbols.get(name);
		if (symbolName == null) return;
		final symbols = anim.symbolDictionary;
		final symbol = symbols == null ? null : symbols.get(symbolName);
		final registration = anim.getByName(name);
		if (registration != null && registration.instance.symbol.name == symbolName)
			@:privateAccess anim.animsMap.remove(name);
		if (anim.curInstance != null && anim.curInstance.symbol != null && anim.curInstance.symbol.name == symbolName)
			anim.curInstance = anim.stageInstance;
		if (symbol != null)
		{
			symbols.remove(symbolName);
			symbol.destroy();
		}
		frameSequenceSymbols.remove(name);
	}

	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null)
	{
		var animJson:AnimAtlas = null;
		if(myJson is String)
		{
			var trimmed:String = pathOrStr.trim();
			trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

			if(trimmed == '.json') myJson = File.getContent(myJson); //is a path
			animJson = cast haxe.Json.parse(_removeBOM(myJson));
		}
		else animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = pathOrStr;

		var trimmed:String = pathOrStr.trim();
		trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

		if(trimmed == '.json') //Path is json
		{
			myData = File.getContent(pathOrStr);
			isXml = false;
		}
		else if (trimmed.substr(1) == '.xml') //Path is xml
		{
			myData = File.getContent(pathOrStr);
			isXml = true;
		}
		myData = _removeBOM(myData);

		// Automatic if everything else fails
		switch(isXml)
		{
			case true:
				myData = Xml.parse(myData);
			case false:
				myData = haxe.Json.parse(myData);
			case null:
				try
				{
					myData = haxe.Json.parse(myData);
					isXml = false;
					//trace('JSON parsed successfully!');
				}
				catch(e)
				{
					myData = Xml.parse(myData);
					isXml = true;
					//trace('XML parsed successfully!');
				}
		}

		for (name in [for (name in frameSequenceSymbols.keys()) name]) discardFrameSequence(name);
		anim._loadAtlas(animJson);
		if(!isXml) frames = FlxAnimateFrames.fromSpriteMap(cast myData, img);
		else frames = FlxAnimateFrames.fromSparrow(cast myData, img);
		origin = anim.curInstance.symbol.transformationPoint;
	}

	override function draw()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}

	override function destroy()
	{
		try
		{
			super.destroy();
		}
		catch(e:haxe.Exception)
		{
			anim.curInstance = FlxDestroyUtil.destroy(anim.curInstance);
			anim.stageInstance = FlxDestroyUtil.destroy(anim.stageInstance);
			//anim.metadata = FlxDestroyUtil.destroy(anim.metadata);
			anim.metadata.destroy();
			anim.symbolDictionary = null;
		}
	}

	function _removeBOM(str:String) //Removes BOM byte order indicator
	{
		if (str.charCodeAt(0) == 0xFEFF) str = str.substr(1); //myData = myData.substr(2);
		return str;
	}

	public function pauseAnimation()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		anim.pause();
	}
	public function resumeAnimation()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		anim.play();
	}
}

typedef AtlasFrameSequence = {
	final anim:String;
	final name:String;
	final indices:Array<Int>;
	final fps:Int;
	final loop:Bool;
}

