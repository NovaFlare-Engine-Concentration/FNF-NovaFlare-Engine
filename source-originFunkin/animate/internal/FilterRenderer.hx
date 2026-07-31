package animate.internal;

import animate.FlxAnimateFrames.FilterQuality;
import animate.internal.elements.AtlasInstance;
import animate.internal.elements.MovieClipInstance;
import animate.internal.filters.StackBlur;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
#if !flash
import animate.internal.filters.MaskShader;
import openfl.display.Graphics;
import openfl.display.OpenGLRenderer;
import openfl.display.Shader;
import openfl.display._internal.Context3DGraphics;
#else
import animate.internal.elements.AtlasInstance.BakedInstance;
import flixel.util.FlxColor;
#end

// TODO: make renderer use textures instead of full bitmaps
#if !flash
@:access(flixel.FlxCamera)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display.Stage)
@:access(openfl.display3D.Context3D)
@:access(openfl.geom.Rectangle)
@:access(openfl.geom.Point)
@:access(openfl.display.internal.DrawCommandBuffer)
@:access(openfl.display.Graphics)
@:access(openfl.geom.ColorTransform)
@:access(openfl.display.BitmapData)
@:access(openfl.filters.BitmapFilter)
@:access(lime.graphics.Image)
@:access(openfl.display3D.textures.TextureBase)
@:access(animate.internal.elements.MovieClipInstance)
#end
class FilterRenderer
{
	#if !flash
	public static function maskFrame(frame:Frame, currentFrame:Int, layer:Layer):Null<AtlasInstance>
	{
		var masker = layer.parentLayer;
		if (masker == null || frame.elements.length <= 0)
			return null;

		var maskerFrame = masker.getFrameAtIndex(currentFrame);
		if (maskerFrame == null || maskerFrame.elements.length <= 0)
			return null;

		var maskerBounds = maskerFrame.getBounds(currentFrame - maskerFrame.index);
		if (maskerBounds.isEmpty) // Has no masker, render as normal
			return null;

		var maskedBounds = frame.getBounds(currentFrame - frame.index);
		if (maskedBounds.isEmpty) // Empty instance, nothing to add here
			return new AtlasInstance();

		var masked:Null<BitmapData> = renderToBitmap((cam, mat) ->
		{
			frame._drawElements(cam, currentFrame, mat, null, NORMAL, true, null);
			cam.render();
			if (cam.canvas.graphics.__bounds != null)
				cam.canvas.graphics.__bounds = maskedBounds.copyToFlash(new Rectangle());
		});

		// Nothing was rendered on the mask
		if (masked == null)
			return new AtlasInstance();

		var masker:Null<BitmapData> = renderToBitmap((cam, mat) ->
		{
			maskerFrame._drawElements(cam, currentFrame, mat, null, NORMAL, true, null);
			cam.render();
			cam.canvas.graphics.__bounds = maskerBounds.copyToFlash(new Rectangle());
		});

		var intersectX = Math.max(maskerBounds.x, maskedBounds.x);
		var intersectY = Math.max(maskerBounds.y, maskedBounds.y);
		var intersectWidth = Math.min(maskerBounds.right, maskedBounds.right) - intersectX;
		var intersectHeight = Math.min(maskerBounds.bottom, maskedBounds.bottom) - intersectY;

		// copy masker channel
		var rect = Rectangle.__pool.get();
		rect.setTo(intersectX - maskerBounds.x, intersectY - maskerBounds.y, intersectWidth, intersectHeight);

		var blend:BlendMode = NORMAL;
		if (frame.elements.length == 1)
		{
			var element = frame.elements[0];
			if (element.elementType == MOVIECLIP)
				blend = element.toMovieClipInstance().blend;
		}

		var frame = FlxGraphic.fromBitmapData(masked).imageFrame.frame;
		frame.parent.persist = true;
		frame.parent.destroyOnNoUse = false;
		MaskShader.maskAlpha(masked, masker, rect);

		Rectangle.__pool.release(rect);

		// create result masked atlas instance
		var element = new BakedInstance();
		element.frame = frame;
		element.blend = blend;
		element.matrix = new FlxMatrix(1, 0, 0, 1, intersectX, intersectY);

		// we wont need to keep the masker anymore
		FlxDestroyUtil.dispose(masker);

		return element;
	}

	public static function renderGfx(gfx:Graphics):Null<BitmapData>
	{
		if (gfx.__bounds == null)
			return null;

		var renderer = FilterRenderer.renderer;
		var context = renderer.__context3D;
		var cacheRTT = context.__state.renderToTexture;
		var cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil;
		var cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias;
		var cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

		var bounds = gfx.__bounds;
		var bmp = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0);

		renderer.__worldTransform.translate(-bounds.x, -bounds.y);
		renderer.setShader(renderer.__defaultShader);
		renderer.__setRenderTarget(bmp);
		context.setRenderToTexture(bmp.getTexture(context));

		Context3DGraphics.render(gfx, renderer);

		renderer.__worldTransform.identity();

		var gl = renderer.__gl;
		var renderBuffer = bmp.getTexture(context);

		@:privateAccess
		gl.readPixels(0, 0, bmp.width, bmp.height, renderBuffer.__format, gl.UNSIGNED_BYTE, bmp.image.data);
		bmp.image.version = 0;
		bmp.__textureVersion = -1;

		(cacheRTT != null) ? context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias,
			cacheRTTSurfaceSelector) : context.setRenderToBackBuffer();

		return bmp;
	}

	static function renderToBitmap(draw:(FlxCamera, FlxMatrix) -> Void):Null<BitmapData>
	{
		final lastDirtyCall:Bool = Frame.__isDirtyCall;
		Frame.__isDirtyCall = true;

		var cam = CamPool.get();
		var gfx = cam.canvas.graphics;
		draw(cam, new FlxMatrix());

		var bitmap:Null<BitmapData> = renderGfx(gfx);

		cam.clearDrawStack();
		gfx.clear();
		cam.put();

		Frame.__isDirtyCall = lastDirtyCall;

		return bitmap;
	}

	public static function bakeFilters(movieclip:MovieClipInstance, frameIndex:Int, filters:Array<BitmapFilter>, scale:FlxPoint,
			quality:FilterQuality = MEDIUM):AtlasInstance
	{
		var bitmap:BitmapData;
		var bounds:FlxRect;
		var filteredBounds:FlxRect;

		var resultFilteredBounds:FlxRect;
		var scaledFilters:Array<BitmapFilter> = [];

		bitmap = renderToBitmap((cam, mat) ->
		{
			bounds = movieclip.getBounds(frameIndex, null, null, false);
			@:privateAccess
			filteredBounds = expandFilterBounds(bounds.copyTo(FlxRect.get()), movieclip._filters);

			mat.setTo(1 / scale.x, 0, 0, 1 / scale.y, 0, 0);
			movieclip._drawTimeline(cam, frameIndex, 0, mat, null, NORMAL, false, null);
			cam.render();

			if (filters != null && filters.length > 0)
			{
				filters = filters.copy();

				for (i => filter in filters)
				{
					if (filter == null)
						continue;

					if (filter is BlurFilter)
					{
						final blur:BlurFilter = cast filter.clone();
						filters[i] = blur;

						#if desktop
						var copyBlur:BlurFilter = cast blur.clone();
						copyBlur.blurX /= scale.x;
						copyBlur.blurY /= scale.y;
						scaledFilters.push(copyBlur);

						// value... fresh from my ass
						final qualityFactor:Float = (quality == FilterQuality.HIGH) ? 1.25 : quality.getQualityFactor();
						blur.blurX = Math.pow(blur.blurX, 0.85) / (scale.x * qualityFactor);
						blur.blurY = Math.pow(blur.blurY, 0.85) / (scale.y * qualityFactor);
						#else
						blur.blurX /= scale.x;
						blur.blurY /= scale.y;
						scaledFilters.push(blur);
						#end
					}
					else
					{
						scaledFilters.push(filter);
					}
				}
			}

			var gfx = cam.canvas.graphics;
			var gfxBounds = gfx.__bounds;
			resultFilteredBounds = expandFilterBounds(FlxRect.get().copyFromFlash(gfxBounds), scaledFilters);
			resultFilteredBounds.copyToFlash(gfxBounds);
		});

		var frame = FlxGraphic.fromBitmapData(bitmap).imageFrame.frame;
		frame.parent.persist = true;
		frame.parent.destroyOnNoUse = false;
		filterFrame(frame, filters);

		// Small offset to account for pixel-innacuracies
		var xOffset:Float = ((resultFilteredBounds.width * scale.x) - filteredBounds.width) / 2;
		var yOffset:Float = ((resultFilteredBounds.height * scale.y) - filteredBounds.height) / 2;

		var mat = new FlxMatrix();
		mat.scale(scale.x, scale.y);
		mat.translate(filteredBounds.x - xOffset, filteredBounds.y - yOffset);

		var element = new AtlasInstance();
		element.frame = frame;
		element.matrix = mat;

		return element;
	}

	public static function filterFrame(frame:FlxFrame, ?filters:Array<BitmapFilter>, ?point:Point):Void
	{
		if (filters == null || filters.length <= 0)
			return;

		var filterFrame = new FlxFrame(FlxGraphic.fromRectangle(Math.ceil(frame.frame.width), Math.ceil(frame.frame.height), 0, true));
		filterFrame.parent.bitmap = applyFilter(filterFrame.parent.bitmap, frame.parent.bitmap, filters, point);
		filterFrame.frame = FlxRect.get(0, 0, filterFrame.parent.bitmap.width, filterFrame.parent.bitmap.height);

		// Remove & replace the original bitmap
		FlxDestroyUtil.dispose(frame.parent.bitmap);
		filterFrame.copyTo(frame);
	}

	/**
	 * Generates a new bitmap with filters from an input bitmap.
	 * @param target Optional, the bitmap data to use for output
	 * @param bitmap The input bitmap to use for filtering
	 * @param filters Array of the filters to apply to the bitmap
	 * @param point Optional, point used to offset the final rendered output
	 */
	public static function applyFilter(?target:BitmapData, bitmap:BitmapData, filters:Array<BitmapFilter>, ?point:Point):BitmapData
	{
		if (target == null)
		{
			var bounds = FlxRect.get().copyFromFlash(bitmap.rect);
			expandFilterBounds(bounds, filters);
			target = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0);
			point = (point == null) ? new Point(-bounds.x, -bounds.y) : new Point(point.x - bounds.x, point.y - bounds.y);
		}

		var _filterBmp1:BitmapData = null;
		var _filterBmp2:BitmapData = null;

		#if desktop
		var needsSecondBitmap:Bool = false;
		var needsPreserveObject:Bool = false;

		for (filter in filters)
		{
			if (filter != null)
			{
				if (filter.__needSecondBitmapData)
					needsSecondBitmap = true;
				if (filter.__preserveObject)
					needsPreserveObject = true;
			}
		}

		if (needsSecondBitmap)
			_filterBmp1 = new BitmapData(target.width, target.height, true, 0);

		if (needsPreserveObject)
			_filterBmp2 = new BitmapData(_filterBmp1.width, _filterBmp1.height, true, 0);
		#end

		return __applyFilter(target, _filterBmp1, _filterBmp2, bitmap, filters, point);
	}

	static function __applyFilter(target:BitmapData, ?target1:BitmapData, ?target2:BitmapData, bmp:BitmapData, filters:Array<BitmapFilter>, ?point:Point)
	{
		if (filters == null || filters.length == 0)
			return bmp;

		var bitmap:BitmapData = target;
		var bitmap2:BitmapData = target1 ?? bmp;
		var bitmap3:BitmapData = target2;

		renderer.__setBlendMode(NORMAL);
		renderer.__worldAlpha = 1;

		if (renderer.__worldTransform == null)
		{
			renderer.__worldTransform = new Matrix();
			renderer.__worldColorTransform = new ColorTransform();
		}

		renderer.__worldTransform.identity();
		renderer.__worldColorTransform.__identity();

		bmp.__renderTransform.identity();
		if (point != null)
		{
			bmp.__renderTransform.translate(point.x, point.y);
		}

		renderer.setShader(renderer.__defaultShader);
		renderer.__setRenderTarget(bitmap);
		renderer.__scissorRect(null);
		renderer.__renderFilterPass(bmp, renderer.__defaultDisplayShader, true);

		var point = Point.__pool.get();

		#if desktop
		for (filter in filters)
		{
			if (filter != null)
				bitmap = __renderGpuFilter(filter, bitmap, bitmap2, bitmap3);
		}
		#end

		var gl = renderer.__gl;
		var renderBuffer = bitmap.getTexture(renderer.__context3D);

		@:privateAccess
		gl.readPixels(0, 0, bitmap.width, bitmap.height, renderBuffer.__format, gl.UNSIGNED_BYTE, bitmap.image.data);
		bitmap.image.version = 0;
		bitmap.__textureVersion = -1;

		#if !desktop
		for (filter in filters)
		{
			if (filter != null)
				bitmap = __renderCpuFilter(filter, bitmap, point);
		}
		#end

		if (bitmap2 != bmp) // in case the filter reuses the bitmap due to not needing a second one
			FlxDestroyUtil.dispose(bitmap2);

		FlxDestroyUtil.dispose(bitmap3);

		Point.__pool.release(point);

		return bitmap;
	}

	static function __renderGpuFilter(filter:BitmapFilter, bitmap:BitmapData, bitmap2:BitmapData, bitmap3:BitmapData)
	{
		final preserveObject:Bool = filter.__preserveObject;
		final sourceBitmap:Null<BitmapData> = preserveObject ? bitmap3 : null;

		if (preserveObject)
		{
			renderer.__setRenderTarget(bitmap3);
			renderer.__renderFilterPass(bitmap, renderer.__defaultDisplayShader, filter.__smooth);
		}

		var shader:Shader = null;
		for (i in 0...filter.__numShaderPasses)
		{
			shader = filter.__initShader(renderer, i, sourceBitmap);
			renderer.__setBlendMode(filter.__shaderBlendMode);
			renderer.__setRenderTarget(bitmap2);
			renderer.__renderFilterPass(bitmap, shader, filter.__smooth);

			renderer.__setRenderTarget(bitmap);
			renderer.__renderFilterPass(bitmap2, renderer.__defaultDisplayShader, filter.__smooth);
		}

		filter.__renderDirty = false;

		return bitmap;
	}

	static function __renderCpuFilter(filter:BitmapFilter, bitmap:BitmapData, point:Point)
	{
		if (filter is BlurFilter)
		{
			StackBlur.applyFilter(bitmap, cast filter, point);
		}
		else if (filter is ColorMatrixFilter)
		{
			bitmap.applyFilter(bitmap, bitmap.rect, point, filter);
		}
		else
		{
			// TODO: this shit really confuses me, i gotta look into it
			// I think the bitmapdata is still in the gpu so it isnt accesible in the cpu?
			// But it doesnt happen for the color matrix filter, so... idk
			bitmap = bitmap.clone();
			bitmap.applyFilter(bitmap, bitmap.rect, point, filter);
		}

		return bitmap;
	}

	public static function renderWithShader(target:BitmapData, bitmap:BitmapData, shader:Shader):Void @:privateAccess
	{
		var renderer = FilterRenderer.renderer;
		renderer.setShader(renderer.__defaultShader);
		renderer.__setRenderTarget(target);

		target.__renderTransform.identity();
		renderer.__renderFilterPass(bitmap, shader, true);

		var gl = renderer.__gl;
		var renderBuffer = target.getTexture(renderer.__context3D);

		gl.readPixels(0, 0, target.width, target.height, renderBuffer.__format, gl.UNSIGNED_BYTE, target.image.data);
		target.image.version = 0;
		target.__textureVersion = -1;
	}

	static var renderer(get, null):OpenGLRenderer;

	static function get_renderer()
		return (renderer != null) ? renderer : (renderer = __createRenderer());

	static function __createRenderer():OpenGLRenderer
	{
		var renderer = new OpenGLRenderer(FlxG.game.stage.context3D);
		renderer.__worldTransform = new Matrix();
		renderer.__worldColorTransform = new ColorTransform();
		return renderer;
	}
	#else
	// Basic Flash filter baking impl
	// NOTE: this is NOWHERE near done lol, still needs some work, its not really a priority for me though
	public static function bakeFilters(movieclip:MovieClipInstance, frameIndex:Int, filters:Array<BitmapFilter>, scale:FlxPoint,
			quality:FilterQuality = MEDIUM):AtlasInstance
	{
		var filteredBounds:FlxRect = movieclip.getBounds(0);
		expandFilterBounds(filteredBounds, filters);

		@:privateAccess
		var bitmap:BitmapData = getBitmap((cam, mat) ->
		{
			movieclip._drawTimeline(cam, frameIndex, 0, mat, null, NORMAL, false, null);
		}, filteredBounds);

		var frame = FlxGraphic.fromBitmapData(bitmap).imageFrame.frame;
		frame.parent.persist = true;
		frame.parent.destroyOnNoUse = false;

		var rect = new Rectangle(0, 0, bitmap.width, bitmap.height);
		var point = new Point(0, 0);

		for (filter in filters)
			bitmap.applyFilter(bitmap, rect, point, filter);

		var mat = new FlxMatrix();
		mat.translate(filteredBounds.left, filteredBounds.top);

		var element = new AtlasInstance();
		element.frame = frame;
		element.matrix = mat;

		return element;
	}

	public static function maskFrame(frame:Frame, currentFrame:Int, layer:Layer):Null<AtlasInstance>
	{
		var masker = layer.parentLayer;
		if (masker == null)
			return null;

		var maskerFrame = masker.getFrameAtIndex(currentFrame);
		if (maskerFrame == null)
			return null;

		var maskerBounds = maskerFrame.getBounds(currentFrame - maskerFrame.index);
		if (maskerBounds.isEmpty) // Has no masker, render as normal
			return null;

		var maskedBounds = frame.getBounds(currentFrame - frame.index);
		if (maskedBounds.isEmpty) // Empty instance, nothing to add here
			return new AtlasInstance();

		var masker = getBitmap((cam, mat) -> maskerFrame._drawElements(cam, currentFrame, mat, null, NORMAL, false, null), maskerBounds);
		var masked = getBitmap((cam, mat) -> frame._drawElements(cam, currentFrame, mat, null, NORMAL, false, null), maskedBounds);

		var intersectX = Math.max(maskerBounds.x, maskedBounds.x);
		var intersectY = Math.max(maskerBounds.y, maskedBounds.y);

		var maskedBitmap = maskBitmap(masked, masker);
		var frame = FlxGraphic.fromBitmapData(maskedBitmap).imageFrame.frame;
		frame.parent.persist = true;
		frame.parent.destroyOnNoUse = false;

		var element = new AtlasInstance();
		element.frame = frame;
		element.matrix = new FlxMatrix(1, 0, 0, 1, intersectX, intersectY);

		FlxDestroyUtil.dispose(masker);

		return element;
	}

	static function getBitmap(draw:(FlxCamera, FlxMatrix) -> Void, rect:FlxRect, forceDirty:Bool = true)
	{
		var cam = CamPool.getForBounds(rect);

		if ((cam.buffer.width < rect.width) || (cam.buffer.height < rect.height))
		{
			var lastBuffer = cam.buffer;
			cam.buffer = new BitmapData(Math.ceil(Math.max(lastBuffer.width, rect.width)), Math.ceil(Math.max(lastBuffer.height, rect.height)));
			lastBuffer.dispose();
			lastBuffer.disposeImage();
		}

		cam.buffer.lock();
		cam.buffer.fillRect(new Rectangle(0, 0, cam.buffer.width, cam.buffer.height), FlxColor.TRANSPARENT);

		var mat = new FlxMatrix();
		mat.translate(-rect.left, -rect.top);

		final lastDirtyCall:Bool = Frame.__isDirtyCall;
		Frame.__isDirtyCall = forceDirty;
		draw(cam, mat);
		Frame.__isDirtyCall = lastDirtyCall;

		var bitmap = new BitmapData(Std.int(rect.width), Std.int(rect.height), true, 0);
		bitmap.copyPixels(cam.buffer, bitmap.rect, new Point(), null, null, true);
		cam.put();
		cam.buffer.unlock();

		return bitmap;
	}

	static function maskBitmap(masked:BitmapData, masker:BitmapData):BitmapData
	{
		masked.lock();
		masker.lock();

		for (y in 0...masked.height)
		{
			for (x in 0...masked.width)
			{
				var maskColor:FlxColor = masker.getPixel32(x, y);
				var maskAlpha = maskColor.alphaFloat;
				if (maskAlpha <= 0)
				{
					masked.setPixel32(x, y, FlxColor.TRANSPARENT);
					continue;
				}

				var finalColor:FlxColor = masked.getPixel32(x, y);
				finalColor.alphaFloat *= maskAlpha;
				masked.setPixel32(x, y, finalColor);
			}
		}

		masked.unlock();
		masker.unlock();

		return masked;
	}
	#end

	public static function expandFilterBounds(baseBounds:FlxRect, filters:Array<BitmapFilter>)
	{
		var inflate = #if flash new Rectangle(); #else Rectangle.__pool.get(); #end
		for (filter in filters)
		{
			var __leftExtension = 0;
			var __topExtension = 0;
			var __bottomExtension = 0;
			var __rightExtension = 0;

			if (filter is BlurFilter)
			{
				var blur:BlurFilter = cast filter;
				__leftExtension = __rightExtension = (blur.blurX > 0 ? Math.ceil(blur.blurX) : 0);
				__topExtension = __bottomExtension = (blur.blurY > 0 ? Math.ceil(blur.blurY) : 0);
			}
			else if (filter is GlowFilter)
			{
				var glow:GlowFilter = cast filter;
				if (!glow.inner)
				{
					__leftExtension = __rightExtension = (glow.blurX > 0 ? Math.ceil(glow.blurX) : 0);
					__topExtension = __bottomExtension = (glow.blurY > 0 ? Math.ceil(glow.blurY) : 0);
				}
			}
			else if (filter is DropShadowFilter)
			{
				var dropShadow:DropShadowFilter = cast filter;
				var __offsetX = Std.int(dropShadow.distance * FlxMath.fastCos(dropShadow.angle * Math.PI / 180));
				var __offsetY = Std.int(dropShadow.distance * FlxMath.fastSin(dropShadow.angle * Math.PI / 180));
				__topExtension = Math.ceil((__offsetY < 0 ? -__offsetY : 0) + dropShadow.blurY);
				__bottomExtension = Math.ceil((__offsetY > 0 ? __offsetY : 0) + dropShadow.blurY);
				__leftExtension = Math.ceil((__offsetX < 0 ? -__offsetX : 0) + dropShadow.blurX);
				__rightExtension = Math.ceil((__offsetX > 0 ? __offsetX : 0) + dropShadow.blurX);
			}
			#if flash
			else if (filter is flash.filters.GradientGlowFilter)
			{
				var gradientGlow:flash.filters.GradientGlowFilter = cast filter;
				var __offsetX = Std.int(gradientGlow.distance * FlxMath.fastCos(gradientGlow.angle * Math.PI / 180));
				var __offsetY = Std.int(gradientGlow.distance * FlxMath.fastSin(gradientGlow.angle * Math.PI / 180));
				__topExtension = Math.ceil((__offsetY < 0 ? -__offsetY : 0) + gradientGlow.blurY);
				__bottomExtension = Math.ceil((__offsetY > 0 ? __offsetY : 0) + gradientGlow.blurY);
				__leftExtension = Math.ceil((__offsetX < 0 ? -__offsetX : 0) + gradientGlow.blurX);
				__rightExtension = Math.ceil((__offsetX > 0 ? __offsetX : 0) + gradientGlow.blurX);
			}
			#else
			else
			{
				__topExtension = filter.__topExtension;
				__bottomExtension = filter.__bottomExtension;
				__leftExtension = filter.__leftExtension;
				__rightExtension = filter.__rightExtension;
			}
			#end

			inflate.x -= __leftExtension;
			inflate.width += __leftExtension + __rightExtension;
			inflate.y -= __topExtension;
			inflate.height += __topExtension + __bottomExtension;
		}

		baseBounds.x = Math.min(baseBounds.x, baseBounds.x + inflate.x);
		baseBounds.y = Math.min(baseBounds.y, baseBounds.y + inflate.y);
		baseBounds.width = Math.max(baseBounds.width, baseBounds.width + inflate.width);
		baseBounds.height = Math.max(baseBounds.height, baseBounds.height + inflate.height);

		#if !flash Rectangle.__pool.release(inflate); #end

		return baseBounds;
	}
}

class CamPool extends FlxCamera implements IFlxPooled
{
	public static var pool(get, null):FlxPool<CamPool>;

	inline static function get_pool():FlxPool<CamPool>
	{
		if (pool == null)
			pool = new FlxPool(#if (flixel >= "5.5.0") () -> new CamPool() #else CamPool #end);
		return pool;
	}

	public function new()
	{
		super();
		pixelPerfectRender = true;
	}

	// TODO: use this as a replacement of Frame.__isDirtyCall
	public static function getForBounds(rect:FlxRect)
	{
		var cam = get();
		cam.setSize(Math.ceil(Math.max(rect.width, cam.width)), Math.ceil(Math.max(rect.height, cam.height)));
		return cam;
	}

	public static function get()
	{
		return pool.get();
	}

	public function put()
	{
		pool.putUnsafe(this);
	}

	public function putWeak() {}

	override function destroy() {}

	private var _inPool:Bool;
}
