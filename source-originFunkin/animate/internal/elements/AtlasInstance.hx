package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.elements.Element;
import animate.internal.filters.Blend;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

#if FLX_DEBUG
import flixel.FlxG;
import flixel.util.FlxColor;
#end
#if flash
import flixel.graphics.FlxGraphic;
#end

@:access(openfl.geom.Point)
@:access(openfl.geom.Matrix)
@:access(flixel.FlxCamera)
@:access(flixel.graphics.frames.FlxFrame)
class AtlasInstance extends AnimateElement<AtlasInstanceJson>
{
	public var frame:FlxFrame;

	var tileMatrix:FlxMatrix;
	var sourceFrame:FlxFrame;

	public function new(?data:AtlasInstanceJson, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent, frame);

		this.tileMatrix = new FlxMatrix();
		this.elementType = ATLAS;

		if (data != null)
		{
			this.frame = parent.getByName(data.N);
			this.sourceFrame = this.frame;
			this.matrix = data.MX.toMatrix();

			#if flash
			// FlxFrame.paint doesnt work for rotated frames lol
			var bitmap = this.frame.checkInputBitmap(null, null, this.frame.angle);
			var mat = this.frame.prepareBlitMatrix(FlxFrame._matrix, true);
			bitmap.draw(this.frame.parent.bitmap, mat, null, null, this.frame.getDrawFrameRect(mat, FlxFrame._rect));
			this.frame = FlxGraphic.fromBitmapData(bitmap).imageFrame.frame;
			#else
			// new flixel broke the tileMatrix on hashlink, gotta manually do this shit
			// TODO: remove this when it gets fixed on flixel 6.1.1 or something
			this.frame.prepareBlitMatrix(tileMatrix, false);
			#end
		}
	}

	/**
	 * Replaces the frame used to render the atlas instance.
	 *
	 * @param frame 		New ``FlxFrame`` to replace the existing one.
	 * 						Set to ``null`` to go back to the original frame.
	 * @param adjustScale 	If to rescale the new frame to fit the dimensions of the old one.
	 */
	public function replaceFrame(?frame:Null<FlxFrame>, adjustScale:Bool = true):Void
	{
		var copyFrame:FlxFrame = (frame ?? this.sourceFrame).copyTo();

		// TODO: account for frame rotations
		// Scale adjustment
		if (adjustScale)
		{
			tileMatrix.a = sourceFrame.frame.width / copyFrame.frame.width;
			tileMatrix.d = sourceFrame.frame.height / copyFrame.frame.height;
		}

		this.frame = copyFrame;

		if (this.parentFrame != null)
			this.parentFrame.setDirty();
	}

	override function destroy():Void
	{
		super.destroy();
		frame = null;
		sourceFrame = null;
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (frame == null || frame.frame == null) // should add a warn here
			return;

		_mat.copyFrom(tileMatrix);
		_mat.concat(matrix);
		_mat.concat(parentMatrix);

		if (!isOnScreen(camera, _mat))
			return;

		if (camera.pixelPerfectRender)
		{
			_mat.tx = Math.floor(_mat.tx);
			_mat.ty = Math.floor(_mat.ty);
		}

		#if flash
		drawPixelsFlash(camera, _mat, transform, blend, antialiasing);
		#else
		camera.drawPixels(frame, null, _mat, transform, blend, antialiasing, shader);
		#end

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug && FlxAnimate.drawDebugLimbs && !Frame.__isDirtyCall)
			drawBoundingBox(camera, _bounds);
		#end
	}

	#if flash
	@:access(flixel.FlxCamera)
	inline function drawPixelsFlash(cam:FlxCamera, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool):Void
	{
		final smooth:Bool = (cam.antialiasing || antialiasing);
		final mat = cam._helperMatrix;

		mat.copyFrom(matrix);
		cam._useBlitMatrix ? mat.concat(cam._blitMatrix) : mat.translate(-cam.viewMarginLeft, -cam.viewMarginTop);
		cam.buffer.draw(frame.parent.bitmap, cam._helperMatrix, transform, blend, null, smooth);
	}
	#end

	var _bounds:FlxRect = FlxRect.get();

	public function isOnScreen(camera:FlxCamera, matrix:FlxMatrix):Bool
	{
		if (Frame.__isDirtyCall)
			return true;

		var bounds = _bounds;
		bounds.x = 0.0;
		bounds.y = 0.0;
		bounds.width = frame.frame.width;
		bounds.height = frame.frame.height;

		Timeline.applyMatrixToRect(bounds, matrix);

		#if (flixel >= "5.2.0")
		// manually inlining this because we dont need the bounds.putWeak part
		return (bounds.right > camera.viewMarginLeft)
			&& (bounds.x < camera.viewMarginRight)
			&& (bounds.bottom > camera.viewMarginTop)
			&& (bounds.y < camera.viewMarginBottom);
		#else
		var point = FlxPoint.get(bounds.x, bounds.y);
		var result = camera.containsPoint(point, bounds.width, bounds.height);
		point.put();
		return result;
		#end
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):FlxRect
	{
		rect = super.getBounds(0, rect);

		if (frame != null)
			rect.set(0, 0, frame.frame.width, frame.frame.height);

		Timeline.applyMatrixToRect(rect, tileMatrix);
		Timeline.applyMatrixToRect(rect, this.matrix);
		Timeline.applyMatrixToRect(rect, matrix);

		return rect;
	}

	#if (FLX_DEBUG && flash)
	static final _fillRect = new openfl.geom.Rectangle();
	#end

	#if FLX_DEBUG
	public static inline function drawBoundingBox(camera:FlxCamera, bounds:FlxRect, ?color:FlxColor = FlxColor.BLUE):Void
	{
		#if flash
		var cBounds = camera.transformRect(bounds.copyTo(FlxRect.get()));
		FlxG.signals.postDraw.addOnce(() ->
		{
			var buffer = FlxG.camera.buffer;
			_fillRect.setTo(cBounds.x, cBounds.y, cBounds.width, 1);
			buffer.fillRect(_fillRect, color);
			_fillRect.setTo(cBounds.x, cBounds.y + cBounds.height - 1, cBounds.width, 1);
			buffer.fillRect(_fillRect, color);
			_fillRect.setTo(cBounds.x, cBounds.y, 1, cBounds.height);
			buffer.fillRect(_fillRect, color);
			_fillRect.setTo(cBounds.x + cBounds.width - 1, cBounds.y, 1, cBounds.height);
			buffer.fillRect(_fillRect, color);
			cBounds.put();
		});
		#else

		final view:FlxRect = #if (flixel >= "5.2.0") camera.getViewMarginRect() #else FlxRect.get(camera.viewOffsetX, camera.viewOffsetY, camera.viewOffsetWidth, camera.viewOffsetHeight) #end;
		final rect = bounds.copyTo(FlxRect.get());
		view.left -= 2;
		view.top -= 2;
		view.right += 2;
		view.bottom += 2;
		view.intersection(rect, rect);

		if (rect.width > 0 && rect.height > 0)
		{
			final gfx = camera.debugLayer.graphics;
			gfx.lineStyle(1, color, 0.75, false, null, null, MITER, 255);
			gfx.drawRect(rect.x + 0.5, rect.y + 0.5, rect.width - 1.0, rect.height - 1.0);
		}

		view.put();
		rect.put();
		#end
	}
	#end

	public function toString():String
	{
		return '{frame: ${frame?.name}, matrix: $matrix}';
	}
}

@:noCompletion
class BakedInstance extends AtlasInstance
{
	public var blend:BlendMode = null;

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader)
	{
		var b = Blend.resolve(this.blend, blend);
		super.draw(camera, index, frameIndex, parentMatrix, transform, b, antialiasing, shader);
	}
}
