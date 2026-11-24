package developer.display;

class Watermark extends Bitmap
{
	private var lastStageHeight:Int = -1;
	private var lastScale:Float = -1;
	private var lastBitmapWidth:Int = -1;
	private var lastBitmapHeight:Int = -1;

	public function new(x:Float = 10, y:Float = 10, Alpha:Float = 0.5, ?sourceBitmapData:BitmapData)
	{
		super();

		if (sourceBitmapData != null)
		{
			bitmapData = sourceBitmapData;
		}
		else
		{
			var image:String = Paths.modFolders('images/menuExtend/Others/watermark.png');
			bitmapData = BitmapData.fromFile(image);
		}

		this.x = x;
		this.y = y;
		this.alpha = Alpha;
	}

	public function updateLayout():Void
	{
		if (bitmapData == null) return;
		var stageHeight = Lib.current.stage.stageHeight;
		var scale = ClientPrefs.data.watermarkScale;
		if (stageHeight == lastStageHeight && scale == lastScale
			&& bitmapData.width == lastBitmapWidth && bitmapData.height == lastBitmapHeight) return;
		lastStageHeight = stageHeight;
		lastScale = scale;
		lastBitmapWidth = bitmapData.width;
		lastBitmapHeight = bitmapData.height;
		var originalWidth = bitmapData.imageSourceWidth > 0 ? bitmapData.imageSourceWidth : bitmapData.width;
		var originalHeight = bitmapData.imageSourceHeight > 0 ? bitmapData.imageSourceHeight : bitmapData.height;
		scaleX = scale * originalWidth / bitmapData.width;
		scaleY = scale * originalHeight / bitmapData.height;
		this.x = 5;
		this.y = stageHeight - 5 - scale * originalHeight;
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		if (visible) updateLayout();
	}
}

class FPSBG extends Bitmap
{
	public function new(width:Int = 140, height:Int = 60, round:Int = 10, alpha:Float = 0.4)
	{
		super();

		var color:FlxColor = FlxColor.fromRGB(100, 100, 100, 255);

		var shape:Shape = new Shape();
		shape.graphics.beginFill(color);
		shape.graphics.drawRoundRect(0, 0, width, height, round, round);
		shape.graphics.endFill();

		var BitmapData:BitmapData = new BitmapData(width, height, 0x00FFFFFF);
		BitmapData.draw(shape);

		this.bitmapData = BitmapData;
		this.alpha = alpha;
	} // 说真的，haxe怎么写个贴图在openfl层这么麻烦
}
