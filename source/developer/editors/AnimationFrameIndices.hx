package developer.editors;

class AnimationFrameIndices
{
	static final DECIMAL = ~/^\d+$/;

	public static function parse(text:String):Null<Array<Int>>
	{
		if (StringTools.trim(text) == '') return [];
		var indices:Array<Int> = [];
		for (entry in text.split(','))
		{
			var token = StringTools.trim(entry);
			if (token == '') continue;
			if (!DECIMAL.match(token)) return null;
			var value = Std.parseFloat(token);
			if (value > 2147483647) return null;
			indices.push(Std.int(value));
		}
		return indices.length > 0 ? indices : null;
	}

	public static function format(indices:Null<Array<Int>>):String
	{
		return indices == null ? '' : indices.join(', ');
	}
}
