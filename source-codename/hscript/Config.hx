package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
		#if !DOCUMENTATION
		"flixel",

		"codename.funkin",
		#if MODCHARTING_FEATURES
		"modchart.engine",
		"modchart.backend.standalone",
		#end
		#end
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		#if !DOCUMENTATION
		#if CODENAME_ENGINE_COMPAT
		// --- haxe stdlib ---
		"haxe.xml.Access",
		"haxe.CallStack",
		// --- flixel 5.9.0 abstracts (explicit public type paths; no package wildcards) ---
		"flixel.CollisionDragType",
		"flixel.FlxType",
		// --- flixel-addons / flixel-ui ---
		"flixel.addons.editors.pex.FlxPexParser.PexEmitterType",
		"flixel.addons.transition.FlxTransitionSprite.TransitionStatus",
		"flixel.addons.transition.TransitionData.TransitionType",
		"flixel.addons.ui.FlxUICursor.FlxUICursorInputFlag",
		"flixel.graphics.atlas.AseAtlasColor",
		"flixel.graphics.atlas.AseAtlasTagDirection",
		"flixel.graphics.atlas.AseAtlasTagRepeat",
		"flixel.graphics.atlas.AseBlendMode",
		"flixel.graphics.atlas.HashOrArray",
		"flixel.graphics.frames.bmfont.BMFontXml",
		"flixel.graphics.frames.FlxFrameAngle",
		"flixel.graphics.frames.FlxFrameType",
		"flixel.input.actions.FlxAnalogAxis",
		"flixel.input.actions.FlxAnalogState",
		"flixel.input.actions.FlxInputDeviceID",
		"flixel.input.android.FlxAndroidKey",
		"flixel.input.FlxInputState",
		"flixel.input.gamepad.FlxGamepadInputID",
		"flixel.input.gamepad.id.LogitechID",
		"flixel.input.gamepad.id.MayflashWiiRemoteID",
		"flixel.input.gamepad.id.MFiID",
		"flixel.input.gamepad.id.OUYAID",
		"flixel.input.gamepad.id.PS4ID",
		"flixel.input.gamepad.id.PSVitaID",
		"flixel.input.gamepad.id.SwitchJoyconLeftID",
		"flixel.input.gamepad.id.SwitchJoyconRightID",
		"flixel.input.gamepad.id.SwitchProID",
		"flixel.input.gamepad.id.WiiRemoteID",
		"flixel.input.gamepad.id.XInputID",
		"flixel.input.keyboard.FlxKey",
		"flixel.input.mouse.FlxMouseButtonID",
		"flixel.math.FlxPoint",
		"flixel.path.FlxPathDirection",
		"flixel.path.FlxPathLoopType",
		"flixel.path.FlxPathType",
		"flixel.path.FlxTilemapDiagonalPolicy",
		"flixel.system.FlxAngelCodeAsset",
		"flixel.system.FlxJsonAsset",
		"flixel.system.FlxXmlAsset",
		"flixel.system.frontEnds.FlxAssetType",
		"flixel.text.FlxInputTextCase",
		"flixel.text.FlxInputTextChange",
		"flixel.text.FlxTextAlign",
		"flixel.tweens.FlxTweenType",
		"flixel.ui.FlxButtonState",
		"flixel.util.FlxAxes",
		"flixel.util.FlxColor",
		"flixel.util.FlxDirection",
		"flixel.util.FlxDirectionFlags",
		"flixel.util.FlxTypedSignal",
		"flixel.util.PoolFactory",
		"flixel.util.typeLimit.NextState",
		"flixel.util.typeLimit.InitialState",
		"flixel.util.typeLimit.OneOfFour",
		"flixel.util.typeLimit.OneOfThree",
		"flixel.util.typeLimit.OneOfTwo",
		"flixel.util.UnicodeBuffer",
		// --- openfl 9.5.0 abstracts (explicit public type paths; no package wildcards) ---
		"openfl.desktop.ClipboardFormats",
		"openfl.desktop.ClipboardTransferMode",
		"openfl.desktop.InvokeEventReason",
		"openfl.desktop.NotificationType",
		"openfl.desktop.SystemIdleMode",
		"openfl.system.SecurityPanel",
		// OpenFL's underscore-prefixed implementation packages are not valid
		// addGlobalMetadata type selectors on this Haxe toolchain; keep the
		// internal draw command abstracts out of the HScript registration list.
		"openfl.display.BitmapDataChannel",
		"openfl.display.BlendMode",
		"openfl.display.CapsStyle",
		"openfl.display.ChildAccess",
		"openfl.display.FocusDirection",
		"openfl.display.GradientType",
		"openfl.display.GraphicsPathCommand",
		"openfl.display.GraphicsPathWinding",
		"openfl.display.InterpolationMethod",
		"openfl.display.JointStyle",
		"openfl.display.LineScaleMode",
		"openfl.display.NativeWindowDisplayState",
		"openfl.display.NativeWindowSystemChrome",
		"openfl.display.NativeWindowType",
		"openfl.display.PixelSnapping",
		"openfl.display.ShaderData",
		"openfl.display.ShaderParameterType",
		"openfl.display.ShaderPrecision",
		"openfl.display.SpreadMethod",
		"openfl.display.StageAlign",
		"openfl.display.StageDisplayState",
		"openfl.display.StageOrientation",
		"openfl.display.StageQuality",
		"openfl.display.StageScaleMode",
		"openfl.display.TriangleCulling",
		"openfl.display3D.Context3DBlendFactor",
		"openfl.display3D.Context3DBufferUsage",
		"openfl.display3D.Context3DClearMask",
		"openfl.display3D.Context3DCompareMode",
		"openfl.display3D.Context3DMipFilter",
		"openfl.display3D.Context3DProfile",
		"openfl.display3D.Context3DProgramFormat",
		"openfl.display3D.Context3DProgramType",
		"openfl.display3D.Context3DRenderMode",
		"openfl.display3D.Context3DStencilAction",
		"openfl.display3D.Context3DTextureFilter",
		"openfl.display3D.Context3DTextureFormat",
		"openfl.display3D.Context3DTriangleFace",
		"openfl.display3D.Context3DVertexBufferFormat",
		"openfl.display3D.Context3DWrapMode",
		"openfl.events.EventPhase",
		"openfl.events.EventType",
		"openfl.filesystem.FileMode",
		"openfl.filters.BitmapFilterQuality",
		"openfl.filters.BitmapFilterType",
		"openfl.filters.DisplacementMapFilterMode",
		"openfl.geom.Orientation3D",
		"openfl.globalization.DateTimeNameContext",
		"openfl.globalization.DateTimeNameStyle",
		"openfl.globalization.DateTimeStyle",
		"openfl.globalization.LastOperationStatus",
		"openfl.media.AudioPlaybackMode",
		"openfl.media.CameraPosition",
		"openfl.net.IPVersion",
		"openfl.net.ObjectEncoding",
		"openfl.net.SharedObjectFlushStatus",
		"openfl.net.URLLoaderDataFormat",
		"openfl.net.URLRequestMethod",
		"openfl.net.URLVariables",
		"openfl.permissions.PermissionStatus",
		"openfl.printing.PrintJobOrientation",
		"openfl.profiler.TelemetryCommandName",
		"openfl.security.CertificateStatus",
		"openfl.system.ImageDecodingPolicy",
		"openfl.system.TouchscreenType",
		"openfl.text.AntiAliasType",
		"openfl.text.AutoCapitalize",
		"openfl.text.engine.FontPosture",
		"openfl.text.engine.FontWeight",
		"openfl.text.FontStyle",
		"openfl.text.FontType",
		"openfl.text.GridFitType",
		"openfl.text.ReturnKeyLabel",
		"openfl.text.SoftKeyboardType",
		"openfl.text.StageTextClearButtonMode",
		"openfl.text.TextFieldAutoSize",
		"openfl.text.TextFieldType",
		"openfl.text.TextFormatAlign",
		"openfl.ui.KeyLocation",
		"openfl.ui.MouseCursor",
		"openfl.ui.MultitouchInputMode",
		"openfl.utils.AssetType",
		"openfl.utils.ByteArray",
		"openfl.utils.CompressionAlgorithm",
		"openfl.utils.Dictionary",
		"openfl.utils.Endian",
		"openfl.utils.Object",
		"openfl.Vector",
		// OpenFL compatibility aliases backed by Haxe abstracts.
		"openfl.utils.JSON",
		"openfl.xml.XML",
		"openfl.xml.XMLList",
		// --- lime abstracts ---
		"lime.graphics.CairoRenderContext",
		"lime.graphics.AnimationDecoderStatus",
		"lime.graphics.AnimationDecoderType",
		"lime.graphics.WebGL2RenderContext",
		"lime.graphics.WebGLRenderContext",
		"lime.graphics.opengl.GLTexture",
		"lime.math.ARGB",
		"lime.math.BGRA",
		"lime.math.ColorMatrix",
		"lime.math.Matrix3",
		"lime.math.Matrix4",
		"lime.math.RGBA",
		"lime.math.Vector2",
		"lime.math.Vector4",
		"lime.text.Glyph",
		"lime.text.UTF8String",
		"lime.media.AudioFormat",
		"lime.utils.ArrayBuffer",
		"lime.utils.ArrayBufferView",
		"lime.utils.BytePointer",
		"lime.utils.Bytes",
		"lime.utils.DataPointer",
		"lime.utils.DataView",
		"lime.utils.Float32Array",
		"lime.utils.Float64Array",
		"lime.utils.Int16Array",
		"lime.utils.Int32Array",
		"lime.utils.Int8Array",
		"lime.utils.Resource",
		"lime.utils.TypedArrayType",
		"lime.utils.UInt16Array",
		"lime.utils.UInt32Array",
		"lime.utils.UInt8Array",
		"lime.utils.UInt8ClampedArray",
		"lime.ui.JoystickHatPosition",
		"lime.ui.KeyModifier",
		"lime.ui.MessageBoxType",
		"lime.ui.Touch.TouchDeviceType",
		"lime.ui.WindowVSyncMode",
		// --- CNE abstracts ---
		"codename.funkin.backend.assets.AssetSource",

		#if THREE_D_SUPPORT
		#if foxlite
		"foxlite.FoxLayer",
		"foxlite.animation.FoxEaseType",
		"foxlite.animation.FoxTrackType",
		"foxlite.instancing.FoxInstanceUpdateMode",
		"foxlite.lights.FoxAreaLightShape",
		"foxlite.lights.FoxLightType",
		"foxlite.material.FoxBlendMode",
		"foxlite.material.FoxDepthCompareMode",
		"foxlite.material.FoxTriangleFace",
		"foxlite.mesh.FoxQuadFace",
		"foxlite.mesh.buffer.FoxVertexBufferType",
		"foxlite.physics.FoxPhysicsBodyType",
		"foxlite.stencil.FoxStencilActionType",
		"foxlite.texture.FoxCubemapSide",
		"foxlite.texture.FoxMipFilter",
		"foxlite.texture.FoxTextureFilter",
		"foxlite.texture.FoxWrapMode",
		#end
		#end
		#else
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack",
		"codename.funkin",
		#if THREE_D_SUPPORT
		#if foxlite
		"foxlite",
		#end
		#end
		#end
		#end
	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [
		"flixel.addons", // flixel-addons/flixel-ui — static inline vars in default params break @:build macro
	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
		"codename.funkin.backend.scripting.events.sprite.PlayAnimContext", // Error: expected member name or ';' after declaration specifiers, Due to define macro from math.h
		"flixel.input.gamepad.FlxGamepadInputID", // Hand-written wrapper retained for stable native field names.
		"flixel.input.keyboard.FlxKey", // NONE/DELETE collide with native macros; use the hand-written FlxKey_HSC wrapper
		"flixel.text.FlxText.FlxTextAlign", // Secondary abstract; hand-written wrapper already provides the HScript reflection surface.
		"flixel.tweens.FlxTween.FlxTweenType", // Secondary abstract; hand-written wrapper already provides the HScript reflection surface.
		"flixel.util.FlxDestroyUtil", // IFlxDestroyable in same file — not ready to be accessed
		"openfl.ui.MouseCursor", // NONE collides with native macros; use the hand-written MouseCursor_HSC wrapper.
	];

	@:unreflective
	public static final IMPORT_BLACKLIST:Array<String> = [

	];
}
