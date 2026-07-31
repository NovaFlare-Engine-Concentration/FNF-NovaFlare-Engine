package animate.internal;

import animate.FlxAnimateJson.LayerJson;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

class Layer implements IFlxDestroyable
{
	public var timeline:Null<Timeline>;
	public var frames:Null<Array<Frame>>;
	public var frameCount(get, never):Int;
	public var visible:Bool;
	public var name:String;
	public var layerType:LayerType;
	public var parentLayer:Null<Layer>;

	var frameIndices:Null<Array<Int>>;

	public function new(?timeline:Timeline)
	{
		this.frames = [];
		this.frameIndices = [];
		this.visible = true;
		this.timeline = timeline;
		this.name = "";
		this.layerType = NORMAL;
	}

	/**
	 * Applies a function to all the keyframes of the layer.
	 *
	 * @param callback The ``Frame->Void`` function to call for all the existing keyframes.
	 */
	public function forEachFrame(callback:Frame->Void)
	{
		if (frames != null)
		{
			for (frame in frames)
				callback(frame);
		}
	}

	/**
	 * Returns a frame of the layer at a specific index.
	 *
	 * @param index Index of the frame.
	 * @return		The ``Frame`` found at the index, null if it doesn't exist.
	 */
	public function getFrameAtIndex(index:Int):Null<Frame>
	{
		index = FlxMath.maxInt(index, 0);
		if (index > (frameCount - 1))
			return null;

		var frameIndex = frameIndices[index];
		return frames[frameIndex];
	}

	/**
	 * Sets the frame of the layer at a specific index as a keyframe.
	 * While keeping all the previous elements stored at the frame.
	 *
	 * @param index Index of the new keyframe.
	 */
	public function setKeyframe(index:Int)
	{
		var lastFrame = getFrameAtIndex(index);
		if (lastFrame == null || lastFrame.index == index) // already is a keyframe or doesnt exist
			return;

		setBlankKeyframe(index);
		var keyframe = getFrameAtIndex(index);

		keyframe.elements = lastFrame.elements.copy();
		keyframe.name = lastFrame.name;
	}

	/**
	 * Sets the frame of the layer at a specific index as an empty keyframe.
	 *
	 * @param index Index of the new keyframe.
	 */
	public function setBlankKeyframe(index:Int)
	{
		var lastFrame = getFrameAtIndex(index);

		var startIndex = lastFrame.index;
		var startDuration = lastFrame.duration;

		var keyframe = new Frame(this);
		keyframe.index = index;
		keyframe.duration = startDuration - (index - startIndex);

		frames.insert(frames.indexOf(lastFrame) + 1, keyframe);
		for (i in 0...keyframe.duration)
			frameIndices[index + i] = frames.length - 1;
	}

	/**
	 * Returns the bounds of the layer at a specific frame index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param rect					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @return						A ``FlxRect`` with the layer's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):FlxRect
	{
		rect ??= FlxRect.get();

		var frame = getFrameAtIndex(frameIndex);
		if (frame != null)
			return frame.getBounds((frameIndex - frame.index), rect, matrix, includeFilters, useCachedBounds);

		Timeline.applyMatrixToRect(rect, matrix);

		return rect;
	}

	public inline function iterator()
	{
		return frames.iterator();
	}

	public inline function keyValueIterator()
	{
		return frames.keyValueIterator();
	}

	@:allow(animate.internal.Timeline)
	function _loadJson(layer:LayerJson, parent:FlxAnimateFrames, ?layerIndex:Int, ?layers:Array<Layer>):Void
	{
		this.name = layer.LN;

		var clippedBy:Null<String> = layer.Clpb;
		var isMasked:Bool = clippedBy != null;

		if (isMasked && layerIndex != null && layers != null) // Set clipped by
		{
			var i = layerIndex - 1;
			var foundLayer:Bool = false;
			this.layerType = CLIPPED;

			while (i >= 0)
			{
				var aboveLayer = layers[i--];
				if (aboveLayer != null && aboveLayer.name == clippedBy && aboveLayer.layerType == CLIPPER)
				{
					parentLayer = aboveLayer;
					foundLayer = true;
					break;
				}
			}

			if (!foundLayer)
			{
				parentLayer = null;
				isMasked = false;
				visible = false;
			}
		}
		else // Set other layer types
		{
			final type:Null<String> = layer.LT;
			this.layerType = type != null ? switch (type)
			{
				case "Clp" | "Clipper": CLIPPER;
				case "Fld" | "Folder": FOLDER;
				default: NORMAL;
			} : NORMAL;
		}

		// Set clipper
		if (this.layerType == CLIPPER)
			visible = false;

		if (this.layerType != FOLDER)
		{
			for (i => frameJson in layer.FR)
			{
				var frame = new Frame(this);
				frame._loadJson(frameJson, parent);
				frames.push(frame);

				for (_ in 0...frame.duration)
					frameIndices.push(i);
			}
		}

		if (!isMasked)
			return;

		// Add settings from parent frames
		var _cacheOnLoad:Bool = false;
		@:privateAccess {
			if (parent != null && parent._settings != null)
				_cacheOnLoad = parent._settings.cacheOnLoad ?? false;
		}

		for (frame in frames)
		{
			if (frame.elements.length <= 0)
				continue;

			frame._dirty = true;
			frame._requireBake = true;

			// Cache all frames on start, if set by the settings
			if (_cacheOnLoad) // TODO: fix some size issues when using cacheOnLoad with masks
			{
				for (i in 0...frame.duration)
					frame._bakeFrame(i);
			}
		}
	}

	public function destroy():Void
	{
		parentLayer = null;

		if (frames != null)
		{
			for (frame in frames)
				frame.destroy();
		}

		frames = null;
		frameIndices = null;
	}

	inline function get_frameCount():Int
	{
		return frameIndices.length;
	}

	public function toString():String
	{
		return '{name: "$name", frameCount: $frameCount, layerType: $layerType}';
	}
}

enum abstract LayerType(Int) to Int
{
	var NORMAL;
	var CLIPPER;
	var CLIPPED;
	var FOLDER;

	public function toString():String
	{
		return switch (cast this : LayerType)
		{
			case CLIPPER: "clipper";
			case CLIPPED: "clipped";
			case FOLDER: "folder";
			case NORMAL: "normal";
		}
	}
}
