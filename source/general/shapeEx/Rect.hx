package general.shapeEx;

class Rect extends FlxSprite
{
	public var mainRound:Float;
	public function new(X:Float = 0, Y:Float = 0, width:Float = 0, height:Float = 0, roundWidth:Float = 0, roundHeight:Float = 0,
			Color:FlxColor = FlxColor.WHITE, ?Alpha:Float = 1, ?lineStyle:Int = 0, ?lineColor:FlxColor = FlxColor.WHITE,
			?noCache:Bool = false)
	{
		super(X, Y);

		this.mainRound = roundWidth;

		var key:String = 'rect-w'+Std.int(width)+'-h:'+Std.int(height)+'-rw:'+Std.int(roundWidth)+'-rh:'+Std.int(roundHeight);

		if (noCache)
		{
			// ★★ 需要"自己裁帧"的 Rect 必须传 noCache = true ★★
			//   普通 Rect 的帧走 Cache，键只按「宽-高-圆角」算 ——
			//   **同尺寸的所有 Rect 共用同一个 FlxFrame 对象**。
			//   而进度条填充是靠 `sprite._frame.frame.width = …` 把帧裁短来画的，
			//   一改就是"所有人一起改"：同屏所有同尺寸的条会同时变宽变窄
			//   （实测：帧数上限 2000 时把画面质量 1/3 的条也画成满格），
			//   而且填充（不透明 mainColor）和底槽（黑 40%）永远一样宽 → 底槽根本露不出来。
			//   这里单独解一张**私有** graphic（不注册进 Cache），只给这一个 sprite 用。
			var g:FlxGraphic = FlxGraphic.fromBitmapData(drawRect(width, height, roundWidth, roundHeight, lineStyle, lineColor), true, null, false);
			g.persist = true;
			g.destroyOnNoUse = true;
			frames = g.imageFrame;
		}
		else
		{
			if (!Cache.checkFrame(key)) addCache(width, height, roundWidth, roundHeight, lineStyle, lineColor);
			frames = Cache.getFrame(key);
		}
		antialiasing = ClientPrefs.data.antialiasing;
		color = Color;
		alpha = Alpha;
	}
	
	function addCache(width:Float = 0, height:Float = 0, roundWidth:Float = 0, roundHeight:Float = 0, lineStyle:Int, lineColor:FlxColor) {
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(drawRect(width, height, roundWidth, roundHeight, lineStyle, lineColor));
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = true;

		Cache.setFrame('rect-w'+Std.int(width)+'-h:'+Std.int(height)+'-rw:'+Std.int(roundWidth)+'-rh:'+Std.int(roundHeight), {graphic:newGraphic, frame:null});
	}

	function drawRect(width:Float, height:Float, roundWidth:Float, roundHeight:Float, lineStyle:Int, lineColor:FlxColor):BitmapData
	{
		var shape:Shape = new Shape();

		shape.graphics.beginFill(0xFFFFFF);
		shape.graphics.drawRoundRect(0, 0, Std.int(width), Std.int(height), roundWidth, roundHeight);
		shape.graphics.endFill();

		var bitmap:BitmapData = new BitmapData(Std.int(width), Std.int(height), true, 0);
		bitmap.draw(shape);
		if (lineStyle > 0) drawLine(bitmap, lineStyle, roundWidth, roundHeight, lineColor);
		return bitmap;
	}

	static var lineShape:Shape = null;
    function drawLine(bitmap:BitmapData, lineStyle:Int, roundWidth:Float, roundHeight:Float, lineColor:FlxColor)
	{
        if (lineShape == null) {
            lineShape = new Shape();
            var lineSize:Int = lineStyle;
            lineShape.graphics.beginFill(lineColor);
            lineShape.graphics.lineStyle(1, lineColor, 1);
            lineShape.graphics.drawRoundRect(0, 0, bitmap.width, bitmap.height, roundWidth, roundHeight);
			lineShape.graphics.lineStyle(0, 0, 0);
            lineShape.graphics.drawRoundRect(lineSize, lineSize, bitmap.width - lineSize * 2, bitmap.height - lineSize * 2, roundWidth - lineSize * 2, roundHeight - lineSize * 2);
            lineShape.graphics.endFill();
        }

		bitmap.draw(lineShape);
	}
}
