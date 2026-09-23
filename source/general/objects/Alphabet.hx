package general.objects;

enum Alignment
{
	LEFT;
	CENTER;
	CENTERED;
	RIGHT;
}

class Alphabet extends FlxSpriteGroup
{
	public var text(default, set):String;

	public var bold:Bool = false;
	public var letters:Array<FlxText> = [];

	public var isMenuItem:Bool = false;
	public var targetY:Int = 0;
	public var changeX:Bool = true;
	public var changeY:Bool = true;

	public var alignment(default, set):Alignment = LEFT;
	public var scaleX(default, set):Float = 1;
	public var scaleY(default, set):Float = 1;
	public var rows:Int = 0;

	public var distancePerItem:FlxPoint = FlxPoint.get(20, 120);
	public var startPosition:FlxPoint = FlxPoint.get(0, 0); // for the calculations

	/** 字体大小，默认 72 */
	public var fontSize:Int = 72;

	/** 每行的总宽度，用于对齐计算 */
	private var rowWidths:Array<Float> = [];
	/** 每个字母的对齐偏移量 */
	private var letterAlignOffsets:Array<Float> = [];
	/** 每个字母所在行号 */
	private var letterRows:Array<Int> = [];

	/** 字母描边样式 */
	public var borderStyle:FlxTextBorderStyle = OUTLINE;
	/** 字母描边颜色 */
	public var borderColor:FlxColor = FlxColor.BLACK;
	/** 字母描边宽度 */
	public var borderSize:Float = 1;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true)
	{
		super(x, y);

		this.startPosition.x = x;
		this.startPosition.y = y;
		this.bold = bold;
		if (text != null)
			this.text = text;
		else
			this.text = '';

		moves = false;
		immovable = true;
	}

	/** 返回当前语言对应的字体文件路径 */
	public static function getFont():String
	{
		return Paths.font(Language.get('fontName', 'main') + '.ttf');
	}

	public function setAlignmentFromString(align:String)
	{
		switch (align.toLowerCase().trim())
		{
			case 'right':
				alignment = RIGHT;
			case 'center' | 'centered':
				alignment = CENTERED;
			default:
				alignment = LEFT;
		}
	}

	/** 兼容新版单文本接口：整段文字渲染宽度(含 scale)。逐字版下等价于 width */
	public var textWidth(get, never):Float;
	function get_textWidth():Float
	{
		return width;
	}

	/** 兼容新版单文本接口：整段文字渲染高度(含 scale)。逐字版下等价于 height */
	public var textHeight(get, never):Float;
	function get_textHeight():Float
	{
		return height;
	}

	private function set_alignment(align:Alignment)
	{
		alignment = align;
		updateAlignment();
		return align;
	}

	private function updateAlignment()
	{
		for (i in 0...letters.length)
		{
			var letter:FlxText = letters[i];
			var newOffset:Float = 0;
			var rowWidth:Float = (letterRows[i] < rowWidths.length) ? rowWidths[letterRows[i]] : 0;
			switch (alignment)
			{
				case CENTER | CENTERED:
					newOffset = rowWidth / 2;
				case RIGHT:
					newOffset = rowWidth;
				default:
					newOffset = 0;
			}

			letter.offset.x -= letterAlignOffsets[i];
			letterAlignOffsets[i] = newOffset * scale.x;
			letter.offset.x += letterAlignOffsets[i];
		}
	}

	private function set_text(newText:String)
	{
		newText = newText.replace('\\n', '\n');
		clearLetters();
		createLetters(newText);
		updateAlignment();
		this.text = newText;
		return newText;
	}

	public function clearLetters()
	{
		var i:Int = letters.length;
		while (i > 0)
		{
			--i;
			var letter:FlxText = letters[i];
			if (letter != null)
			{
				letter.kill();
				letters.remove(letter);
				remove(letter);
			}
		}
		letters = [];
		rowWidths = [];
		letterAlignOffsets = [];
		letterRows = [];
		rows = 0;
	}

	public function setScale(newX:Float, newY:Null<Float> = null)
	{
		var lastX:Float = scale.x;
		var lastY:Float = scale.y;
		if (newY == null)
			newY = newX;
		@:bypassAccessor
		scaleX = newX;
		@:bypassAccessor
		scaleY = newY;

		// 必须 bypass: FlxSpriteGroup 的 scale 会传播给子物体,
		// 逐字版靠改 letter 字号/位置缩放, 再传播会双重缩放
		@:bypassAccessor
		scale.x = newX;
		@:bypassAccessor
		scale.y = newY;
		softReloadLetters(newX / lastX, newY / lastY);
	}

	private function set_scaleX(value:Float)
	{
		if (value == scaleX)
			return value;

		var ratio:Float = value / scale.x;
		@:bypassAccessor
		scale.x = value;
		@:bypassAccessor
		scaleX = value;
		softReloadLetters(ratio, 1);
		return value;
	}

	private function set_scaleY(value:Float)
	{
		if (value == scaleY)
			return value;

		var ratio:Float = value / scale.y;
		@:bypassAccessor
		scale.y = value;
		@:bypassAccessor
		scaleY = value;
		softReloadLetters(1, ratio);
		return value;
	}

	public function softReloadLetters(ratioX:Float = 1, ratioY:Null<Float> = null)
	{
		if (ratioY == null)
			ratioY = ratioX;

		for (i in 0...letters.length)
		{
			var letter = letters[i];
			if (letter != null)
			{
				letter.x = (letter.x - x) * ratioX + x;
				letter.y = (letter.y - y) * ratioY + y;
				letter.size = Std.int(fontSize * scaleX);
			}
		}
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var lerpVal:Float = Math.exp(-elapsed * 9.6);
			if (changeX)
				x = FlxMath.lerp((targetY * distancePerItem.x) + startPosition.x, x, lerpVal);
			if (changeY)
				y = FlxMath.lerp((targetY * 1.3 * distancePerItem.y) + startPosition.y, y, lerpVal);
		}
		super.update(elapsed);
	}

	public function snapToPosition()
	{
		if (isMenuItem)
		{
			if (changeX)
				x = (targetY * distancePerItem.x) + startPosition.x;
			if (changeY)
				y = (targetY * 1.3 * distancePerItem.y) + startPosition.y;
		}
	}

	private static var Y_PER_ROW:Float = 85;

	private function createLetters(newText:String)
	{
		var xPos:Float = 0;
		rows = 0;
		rowWidths = [];

		for (character in newText.split(''))
		{
			if (character != '\n')
			{
				var displayChar:String = (character == ' ' || (bold && character == '_')) ? ' ' : character;
				var letter:FlxText = new FlxText(xPos, rows * Y_PER_ROW * scale.y, 0, displayChar, Std.int(fontSize * scale.y));
				letter.setFormat(
					Paths.font(Language.get('fontName', 'main') + '.ttf'),
					Std.int(fontSize * scale.y),
					FlxColor.WHITE,
					LEFT,
					borderStyle,
					borderColor
				);
				letter.borderSize = borderSize;
				letter.antialiasing = ClientPrefs.data.antialiasing;
				letter.bold = bold;
				letter.scrollFactor.set(scrollFactor.x, scrollFactor.y);

				// 空格特殊处理：缩小宽度
				if (character == ' ')
				{
					letter.text = ' ';
					letter.size = Std.int(fontSize * scale.y * 0.5);
				}

				add(letter);
				letters.push(letter);
				letterAlignOffsets.push(0);
				letterRows.push(rows);

				xPos += letter.width + 2 * scale.x;
				rowWidths[rows] = xPos;
			}
			else
			{
				xPos = 0;
				rows++;
			}
		}

		if (letters.length > 0)
			rows++;
	}

	override function destroy()
	{
		distancePerItem.put();
		startPosition.put();
		letters = FlxDestroyUtil.destroyArray(letters);
		active = false;
		super.destroy();
	}
}
