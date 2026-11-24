package games.objects;

import flixel.math.FlxRect;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class Bar extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var bg:FlxSprite;
	public var valueFunction:Void->Float = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = FlxPoint.get(3, 3);

	public function new(x:Float, y:Float, image:String = 'healthBar', valueFunction:Void->Float = null, boundX:Float = 0, boundY:Float = 1,
			?oldVersion:Bool = false, ?testBitmap:BitmapData = null)
	{
		super(x, y);

		this.valueFunction = valueFunction;
		setBounds(boundX, boundY);

		bg = new FlxSprite().loadGraphic(Paths.image(image));
		if (testBitmap != null) bg.pixels = testBitmap;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		barWidth = Std.int(bg.width - 6);
		barHeight = Std.int(bg.height - 6);

		leftBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		// leftBar.color = FlxColor.WHITE;
		leftBar.antialiasing = antialiasing = ClientPrefs.data.antialiasing;

		rightBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.WHITE);
		rightBar.color = FlxColor.BLACK;
		rightBar.antialiasing = ClientPrefs.data.antialiasing;

		checkForHollowShape();

		if (oldVersion)
		{
			add(bg);
			add(leftBar);
			add(rightBar);
		}
		else
		{
			add(leftBar);
			add(rightBar);
			add(bg);
		}

		regenerateClips();

		moves = false;
		immovable = true;
	}

	public var enabled:Bool = true;

	override function update(elapsed:Float)
	{
		if (!enabled)
		{
			super.update(elapsed);
			return;
		}

		if (valueFunction != null)
		{
			var value:Null<Float> = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
			percent = (value != null ? value : 0);
		}
		else
			percent = 0;
		super.update(elapsed);
	}

	public function setBounds(min:Float, max:Float)
	{
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(left:FlxColor = null, right:FlxColor = null)
	{
		if (left != null)
			leftBar.color = left;
		if (right != null)
			rightBar.color = right;
	}

	public function updateBar()
	{
		if (leftBar == null || rightBar == null)
			return;

		leftBar.setPosition(bg.x, bg.y);
		rightBar.setPosition(bg.x, bg.y);

		var leftSize:Float = 0;
		if (leftToRight)
			leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else
			leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		barCenter = leftBar.x + leftSize + barOffset.x;

		// flixel is retarded
		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
	}

	public function regenerateClips()
	{
		if (leftBar != null)
		{
			leftBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			leftBar.updateHitbox();
			leftBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		if (rightBar != null)
		{
			rightBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			rightBar.updateHitbox();
			rightBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		updateBar();
	}

	private function checkForHollowShape():Void
	{
		if (bg == null || bg.pixels == null)
			return;

		var bitmap:BitmapData = bg.pixels;
		var w:Int = bitmap.width;
		var h:Int = bitmap.height;
		
		var alphaThreshold:Int = 50; // Pixels with Alpha >= 50 stop the flood (act as border)
		
		var visited:openfl.Vector<Int> = new openfl.Vector<Int>(w * h, true);
		// Initialize vector to 0
		for (i in 0...visited.length) visited[i] = 0;

		var queue:Array<Int> = []; // Store indices (y * w + x)

		// Add all edge pixels to queue
		for (x in 0...w) {
			queue.push(x); // Top row (y=0)
			queue.push((h - 1) * w + x); // Bottom row
		}
		for (y in 1...h - 1) {
			queue.push(y * w); // Left col
			queue.push(y * w + (w - 1)); // Right col
		}

		var work:BitmapData = new BitmapData(w, h, true, 0x00000000);
		work.imageSourceWidth = bitmap.imageSourceWidth;
		work.imageSourceHeight = bitmap.imageSourceHeight;
		var idx:Int;
		var curX:Int, curY:Int;
		var pixelAlpha:Int;
		
		bitmap.lock();
		work.lock();

		while (queue.length > 0)
		{
			idx = queue.pop();
			
			if (visited[idx] == 1) continue;
			
			curX = idx % w;
			curY = Std.int(idx / w);
			
			// Check Alpha
			pixelAlpha = (bitmap.getPixel32(curX, curY) >> 24) & 0xFF;
			
			if (pixelAlpha >= alphaThreshold)
			{
				// Hit a wall (Border/Solid Object). Stop flooding this path.
				continue;
			}
			
			// It is passable (Low Alpha / Transparent). Mark as Outside.
			visited[idx] = 1;
			
			// Add neighbors
			if (curX > 0) queue.push(idx - 1);
			if (curX < w - 1) queue.push(idx + 1);
			if (curY > 0) queue.push(idx - w);
			if (curY < h - 1) queue.push(idx + w);
		}


		var alphaThreshold:Int = 50; // Definition of "Shell" boundary
		var wallThreshold:Int = 250; // Definition of "Solid Wall" that blocks Bar expansion
		var barQueue:Array<Int> = [];
		
		for (i in 0...w * h)
		{
			if (visited[i] == 0) // Inside the Shell
			{
				curX = i % w;
				curY = Std.int(i / w);
				pixelAlpha = (bitmap.getPixel32(curX, curY) >> 24) & 0xFF;

				if (pixelAlpha < alphaThreshold)
				{
					visited[i] = 2; // Mark as Bar
					barQueue.push(i);
				}
			}
		}
		
		while (barQueue.length > 0)
		{
			idx = barQueue.pop();
			
			curX = idx % w;
			curY = Std.int(idx / w);
			
			// Check neighbors
			var neighbors:Array<Int> = [];
			if (curX > 0) neighbors.push(idx - 1);
			if (curX < w - 1) neighbors.push(idx + 1);
			if (curY > 0) neighbors.push(idx - w);
			if (curY < h - 1) neighbors.push(idx + w);
			
			for (nIdx in neighbors)
			{
				if (visited[nIdx] == 0) // It is Shell/Inside (Not Outside, Not Visited)
				{
					var nX:Int = nIdx % w;
					var nY:Int = Std.int(nIdx / w);
					var nAlpha:Int = (bitmap.getPixel32(nX, nY) >> 24) & 0xFF;
					
					if (nAlpha <= wallThreshold)
					{
						// It is not a solid wall. It is part of the soft inner edge.
						visited[nIdx] = 2; // Mark as Bar
						barQueue.push(nIdx);
					}
				}
			}
		}
		
		for (x in 0...w)
		{
			for (y in 0...h)
			{
				idx = y * w + x;
				if (visited[idx] == 2) // Bar
				{
					work.setPixel32(x, y, 0xFFFFFFFF);
				}
				else // Outside (1) or Unreached Shell/Wall/Outer Glow (0)
				{
					work.setPixel32(x, y, 0x00000000);
				}
			}
		}

		bitmap.unlock();
		work.unlock();
		
		var barBounds:Rectangle = work.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFFFF, true);
		
		if (barBounds.width > 0 && barBounds.height > 0)
		{
			leftBar.pixels = work.clone();
			rightBar.pixels = work;

			barWidth = Std.int(bg.width);
			barHeight = Std.int(bg.height);
			barOffset.set(0, 0);

			leftBar.antialiasing = ClientPrefs.data.antialiasing;
			rightBar.antialiasing = ClientPrefs.data.antialiasing;
		}
		else
		{
			work.dispose();
		}
	}

	private function set_percent(value:Float)
	{
		var doUpdate:Bool = false;
		if (value != percent)
			doUpdate = true;
		percent = value;

		if (doUpdate)
			updateBar();
		return value;
	}

	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}

	override function destroy()
	{
		active = false;
		barOffset.put();
		super.destroy();

		bg = null;
		leftBar = null;
		rightBar = null;
	}
}
