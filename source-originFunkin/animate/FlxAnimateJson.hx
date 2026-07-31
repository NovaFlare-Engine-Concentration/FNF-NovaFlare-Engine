package animate;

import animate.internal.filters.AdjustColorFilter;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.util.FlxColor;
import haxe.ds.Vector;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.filters.BitmapFilterType;
import openfl.filters.BlurFilter;
import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;

using StringTools;

#if flash
import flash.filters.BevelFilter;
#elseif (openfl >= "9.5.0")
import openfl.filters.BevelFilter;
#end

extern typedef SpritemapJson =
{
	ATLAS:
	{
		SPRITES:Array<SpriteJson>
	},
	meta:SpritemapMeta
}

extern typedef SpritemapMeta =
{
	app:String,
	version:String,
	image:String,
	format:String,
	size:
	{
		w:Int, h:Int
	},
	resolution:String
}

extern typedef SpriteJson =
{
	SPRITE:
	{
		name:String, x:Float, y:Float, w:Float, h:Float, rotated:Bool
	}
}

extern abstract AnimationJson(Dynamic)
{
	public var AN(get, never):AnimationDataJson;
	public var SD(get, never):Null< #if flash Array<SymbolJson> #else Vector<SymbolJson> #end>;
	public var MD(get, never):MetadataJson;

	inline function get_AN()
		return this.AN ?? this.ANIMATION;

	inline function get_SD()
		return this.SD?.S ?? this.SYMBOL_DICTIONARY?.Symbols;

	inline function get_MD()
		return this.MD ?? this.metadata;
}

extern abstract AnimationDataJson(Dynamic)
{
	public var N(get, never):String;
	public var SN(get, never):String;
	public var TL(get, never):TimelineJson;
	public var STI(get, never):Null<SymbolInstanceJson>;

	inline function get_N()
		return this.N ?? this.name;

	inline function get_SN()
		return this.SN ?? this.SYMBOL_name;

	inline function get_TL()
		return this.TL ?? this.TIMELINE;

	inline function get_STI()
		return this.STI?.SI ?? this.StageInstance?.SYMBOL_Instance ?? null;
}

extern abstract TimelineJson(Dynamic)
{
	public var L(get, never):Array<LayerJson>;

	inline function get_L()
		return this.L ?? this.LAYERS;
}

extern abstract LayerJson(Dynamic)
{
	public var LN(get, never):String;

	public var LT(get, never):Null<String>;
	public var Clpb(get, never):Null<String>;

	public var FR(get, never):Array<FrameJson>;

	inline function get_LN()
		return this.LN ?? this.Layer_name;

	inline function get_LT()
		return this.LT ?? this.Layer_type;

	inline function get_Clpb()
		return this.Clpb ?? this.Clipped_by;

	inline function get_FR()
		return this.FR ?? this.Frames;
}

extern abstract FrameJson(Dynamic)
{
	public var I(get, never):Int;
	public var DU(get, never):Int;
	public var E(get, never):Null<Array<ElementJson>>;

	public var N(get, never):Null<String>;

	public var SND(get, never):SoundJson;

	public var B(get, never):Null< #if flash Int #else BlendMode #end>;

	inline function get_I()
		return this.I ?? this.index;

	inline function get_DU()
		return this.DU ?? this.duration;

	inline function get_E()
		return this.E ?? this.elements;

	inline function get_N()
		return this.N ?? this.name;

	inline function get_SND()
		return this.SND;

	inline function get_B()
		return this.B ?? this.blend;
}

extern typedef SoundJson =
{
	N:String,
	SNC:String,
	LP:String,
	RP:Int
}

extern abstract ElementJson(Dynamic)
{
	public var SI(get, never):Null<SymbolInstanceJson>;
	public var ASI(get, never):Null<AtlasInstanceJson>;
	public var TFI(get, never):Null<TextFieldInstanceJson>;

	inline function get_SI()
		return this.SI ?? this.SYMBOL_Instance;

	inline function get_ASI()
		return this.ASI ?? this.ATLAS_SPRITE_instance;

	inline function get_TFI()
		return this.TFI ?? this.textFIELD_Instance;
}

abstract SymbolInstanceJson(Dynamic)
{
	public var SN(get, never):String;
	public var FF(get, never):Int;
	public var ST(get, never):String;
	public var TRP(get, never):TransformationPointJson;
	public var LP(get, never):String;
	public var MX(get, never):MatrixJson;

	public var B(get, never):Null< #if flash Int #else BlendMode #end>;
	public var C(get, never):Null<ColorJson>;
	public var F(get, never):Null<Array<FilterJson>>;

	extern inline function get_SN()
		return this.SN ?? this.SYMBOL_name;

	extern inline function get_FF()
		return this.FF ?? this.firstFrame ?? 0;

	extern inline function get_ST()
		return this.ST ?? this.symbolType;

	extern inline function get_TRP()
		return this.TRP ?? this.transformationPoint;

	extern inline function get_LP()
		return this.LP ?? this.loop ?? "LP";

	extern inline function get_MX()
		return MatrixJson.resolve(this);

	function get_B()
	{
		var blend:Dynamic = this.B ?? this.blend;
		if (blend != null) // blends from BTA
			return blend;

		var blend:Null<String> = this.IN;
		if (blend != null && blend.length > 0)
		{
			if (blend.contains("_bl")) // legacy blends method
			{
				var index:Int = Std.parseInt(blend.split("_bl")[1].split("_")[0]);
				return this.B = index;
			}
		}

		return null;
	}

	extern inline function get_C()
		return this.C ?? this.color;

	extern inline function get_F()
	{
		var filters:Dynamic = this.F ?? this.filters;
		if (filters == null || filters is Array)
			return filters;
		return this.F = FilterJson.resolve(filters);
	}
}

abstract FilterJson(Dynamic)
{
	public var N(get, never):String;
	public var BLX(get, never):Null<Float>;
	public var BLY(get, never):Null<Float>;
	public var Q(get, never):Null<Int>;
	public var BRT(get, never):Null<Int>;
	public var H(get, never):Null<Int>;
	public var CT(get, never):Null<Int>;
	public var SAT(get, never):Null<Int>;
	public var D(get, never):Null<Float>;
	public var KK(get, never):Null<Bool>;
	public var T(get, never):String;
	public var STR(get, never):Null<Float>;
	public var AL(get, never):Null<Float>;
	public var A(get, never):Null<Float>;
	public var HA(get, never):Null<Float>;
	public var SA(get, never):Null<Float>;
	public var SC(get, never):String;
	public var HC(get, never):String;
	public var IN(get, never):Null<Bool>;
	public var HO(get, never):Null<Bool>;
	public var C(get, never):String;
	public var GE(get, never):Array<GradientEntry>;

	extern inline function get_N()
		return this.N ?? this.name;

	extern inline function get_BLX()
		return this.BLX ?? this.blurX;

	extern inline function get_BLY()
		return this.BLY ?? this.blurY;

	extern inline function get_Q()
		return this.Q ?? this.quality;

	extern inline function get_BRT()
		return this.BRT ?? this.brightness;

	extern inline function get_H()
		return this.H ?? this.hue;

	extern inline function get_CT()
		return this.CT ?? this.contrast;

	extern inline function get_SAT()
		return this.SAT ?? this.saturation;

	extern inline function get_D()
		return this.D ?? this.distance;

	extern inline function get_KK()
		return this.KK ?? this.knockout;

	extern inline function get_T()
		return this.T ?? this.type;

	extern inline function get_STR()
		return this.STR ?? this.strength;

	extern inline function get_AL()
		return this.AL ?? this.angle;

	extern inline function get_A()
		return this.A ?? this.alpha ?? 1.0;

	extern inline function get_SA()
		return this.SA ?? this.shadowAlpha ?? 1.0;

	extern inline function get_HA()
		return this.HA ?? this.highlightAlpha ?? 1.0;

	extern inline function get_SC()
		return this.SC ?? this.shadowColor;

	extern inline function get_HC()
		return this.HC ?? this.highlightColor;

	extern inline function get_IN()
		return this.IN ?? this.inner;

	extern inline function get_HO()
		return this.HO ?? this.hideObject;

	extern inline function get_C()
		return this.C ?? this.color;

	extern inline function get_GE()
		return this.GE ?? this.GradientEntries;

	function getGradientArray():{colors:Array<Int>, alphas:Array<Float>, ratios:Array<Float>}
	{
		var colors:Array<Int> = [];
		var alphas:Array<Float> = [];
		var ratios:Array<Float> = [];

		for (entry in GE)
		{
			colors.push(FlxColor.fromString(entry.C));
			alphas.push(entry.A);
			ratios.push(entry.R);
		}

		return {
			colors: colors,
			alphas: alphas,
			ratios: ratios
		}
	}

	function getBitmapFilterType():BitmapFilterType
	{
		var type:Null<String> = T;
		return (type == null) ? BitmapFilterType.INNER : switch (type)
		{
			case "full": BitmapFilterType.FULL;
			case "outer": BitmapFilterType.OUTER;
			default: BitmapFilterType.INNER;
		}
	}

	public function toBitmapFilter():BitmapFilter
	{
		switch (this.N)
		{
			case "blurFilter" | "BLF":
				var blf = new BlurFilter(BLX, BLY, Q);
				return blf;

			case "adjustColorFilter" | "ACF":
				var acf = new AdjustColorFilter();
				acf.set(BRT, H, CT, SAT);
				return acf.filter;

			case "dropShadowFilter" | "DSF":
				var dsf = new DropShadowFilter(D, AL, FlxColor.fromString(C), A, BLX, BLY, STR, Q, IN, KK, HO);
				return dsf;

			case "glowFilter" | "GF":
				var gf = new GlowFilter(FlxColor.fromString(C), A, BLX, BLY, STR / 100, Q, IN, KK);
				return gf;

				// TODO: add missing filters support for other targets
				// case "gradientBevelFilter" | "GBF":
				// case "gradientGlowFilter" | "GGF":

			#if (flash || openfl >= "9.5.0")
			case "bevelFilter" | "BF":
				var highlightColor = FlxColor.fromString(HC);
				var shadowColor = FlxColor.fromString(SC);
				var type:BitmapFilterType = getBitmapFilterType();
				var bf = new BevelFilter(D, AL, highlightColor, HA, shadowColor, SA, BLX, BLY, STR, Q, type, KK);
				return bf;
			#end
			#if flash
			case "gradientBevelFilter" | "GBF":
				var type:BitmapFilterType = getBitmapFilterType();
				var ga = getGradientArray();
				var gbf = new flash.filters.GradientBevelFilter(D, AL, ga.colors, ga.alphas, ga.ratios, BLX, BLY, STR, Q, type, KK);
				return gbf;

			case "gradientGlowFilter" | "GGF":
				var type:BitmapFilterType = getBitmapFilterType();
				var ga = getGradientArray();
				var ggf = new flash.filters.GradientGlowFilter(D, AL, ga.colors, ga.alphas, ga.ratios, BLX, BLY, STR, Q, type, KK);
				return ggf;
			#end

			default:
				FlxG.log.warn('Filter with name "${this.N}" is not currently supported on this target.');
				return null;
		}
	}

	public static function resolve(input:Dynamic):Array<FilterJson>
	{
		if (input == null || input is Array)
			return input;

		var filters:Array<FilterJson> = [];
		for (filter in Reflect.fields(input))
		{
			var filterJson:Dynamic = Reflect.field(input, filter);
			filterJson.N = switch (filter)
			{
				case "DropShadowFilter": "DSF";
				case "GlowFilter": "GF";
				case "BevelFilter": "BF";
				case "BlurFilter": "BLF";
				case "AdjustColorFilter": "ACF";
				case "GradientGlowFilter": "GGF";
				case "GradientBevelFilter": "GBF";
				default: filter;
			}
			filters.push(filterJson);
		}

		return filters;
	}
}

extern abstract GradientEntry(Dynamic)
{
	public var R(get, never):Float;
	public var C(get, never):String;
	public var A(get, never):Float;

	inline function get_R()
		return this.R ?? this.ratio;

	inline function get_C()
		return this.C ?? this.color;

	inline function get_A()
		return this.A ?? this.alpha;
}

extern abstract AtlasInstanceJson(Dynamic)
{
	public var N(get, never):String;
	public var MX(get, never):MatrixJson;

	inline function get_N()
		return this.N ?? this.name;

	inline function get_MX()
		return MatrixJson.resolve(this);
}

extern abstract TextFieldInstanceJson(Dynamic)
{
	public var MX(get, never):MatrixJson;
	public var TXT(get, never):String;
	public var TP(get, never):String;
	public var IN(get, never):Null<String>;
	public var ORT(get, never):Null<String>;
	public var LT(get, never):Null<String>;
	public var ATR(get, never):Array<TextFieldAttributesJson>;
	public var BRD(get, never):Bool;
	public var ALSRP(get, never):Float;
	public var ALTHK(get, never):Float;
	public var MAX(get, never):Int;

	inline function get_MX():MatrixJson
		return MatrixJson.resolve(this);

	inline function get_TXT():String
		return this.TXT ?? this.text;

	inline function get_TP():String
		return this.TP ?? this.type;

	inline function get_IN():Null<String>
		return this.IN ?? this.Instance_name;

	inline function get_ORT():Null<String>
		return this.ORT ?? this.orientation;

	inline function get_LT():Null<String>
		return this.LT ?? this.lineType;

	inline function get_ATR():Array<TextFieldAttributesJson>
		return this.ATR ?? this.attributes;

	inline function get_BRD():Bool
		return this.BRD ?? this.border;

	inline function get_ALSRP():Float
		return this.ALSRP ?? this.alias_SHARPNESS;

	inline function get_ALTHK():Float
		return this.ALTHK ?? this.alias_thickness;

	inline function get_MAX():Int
		return this.MAX ?? this.maxCharacters;
}

extern abstract TextFieldAttributesJson(Dynamic)
{
	public var OF(get, never):Int;
	public var LEN(get, never):Int;
	public var ALS(get, never):Bool;
	public var ALN(get, never):String;
	public var AUK(get, never):Bool;
	public var BL(get, never):Bool;
	public var IT(get, never):Bool;
	public var CPS(get, never):String;
	public var CSP(get, never):Float;
	public var LSP(get, never):Float;
	public var F(get, never):String;
	public var SZ(get, never):Int;
	public var C(get, never):String;
	public var IND(get, never):String;
	public var LFM(get, never):Float;
	public var RFM(get, never):Float;
	public var URL(get, never):String;

	inline function get_OF():Int
		return this.OF ?? this.offset;

	inline function get_LEN():Int
		return this.LEN ?? this.length;

	inline function get_ALS():Bool
		return this.ALS ?? this.alias;

	inline function get_ALN():String
		return this.ALN ?? this.align;

	inline function get_AUK():Bool
		return this.AUK ?? this.autoKern;

	inline function get_BL():Bool
		return this.BL ?? this.bold;

	inline function get_IT():Bool
		return this.IT ?? this.italic;

	inline function get_CPS():String
		return this.CPS ?? this.charPosition;

	inline function get_CSP():Float
		return this.CSP ?? this.charSpacing;

	inline function get_LSP():Float
		return this.LSP ?? this.lineSpacing;

	inline function get_F():String
		return this.F ?? this.font;

	inline function get_SZ():Int
		return this.SZ ?? this.Size;

	inline function get_C():String
		return this.C ?? this.color;

	inline function get_IND():String
		return this.IND ?? this.indent;

	inline function get_LFM():Float
		return this.LFM ?? this.leftMargin;

	inline function get_RFM():Float
		return this.RFM ?? this.rightMargin;

	inline function get_URL():String
		return this.URL ?? this.URL;
}

extern abstract SymbolJson(Dynamic)
{
	public var SN(get, never):String;
	public var TL(get, never):TimelineJson;

	inline function get_SN()
		return this.SN ?? this.SYMBOL_name;

	inline function get_TL()
		return this.TL ?? this.TIMELINE;
}

extern abstract MetadataJson(Dynamic)
{
	public var V(get, never):String;
	public var FRT(get, never):Float;

	public var W(get, never):Int;
	public var H(get, never):Int;
	public var BGC(get, never):String;

	inline function get_V()
		return this.V ?? this.version;

	inline function get_FRT()
		return this.FRT ?? this.framerate;

	inline function get_W()
		return this.W ?? this.width ?? 0;

	inline function get_H()
		return this.H ?? this.height ?? 0;

	inline function get_BGC()
		return this.BGC ?? this.backgroundColor ?? "#FFFFFF";
}

extern abstract ColorJson(Dynamic)
{
	public var M(get, never):String;
	public var RM(get, never):Null<Float>;
	public var GM(get, never):Null<Float>;
	public var BM(get, never):Null<Float>;
	public var AM(get, never):Null<Float>;
	public var RO(get, never):Null<Float>;
	public var GO(get, never):Null<Float>;
	public var BO(get, never):Null<Float>;
	public var AO(get, never):Null<Float>;
	public var TC(get, never):Null<String>;
	public var TM(get, never):Null<Float>;
	public var BRT(get, never):Null<Float>;

	inline function get_M()
		return this.M ?? this.mode;

	inline function get_RM()
		return this.RM ?? this.RedMultiplier;

	inline function get_GM()
		return this.GM ?? this.greenMultiplier;

	inline function get_BM()
		return this.BM ?? this.blueMultiplier;

	inline function get_AM()
		return this.AM ?? this.alphaMultiplier;

	inline function get_RO()
		return this.RO ?? this.redOffset;

	inline function get_GO()
		return this.GO ?? this.greenOffset;

	inline function get_BO()
		return this.BO ?? this.blueOffset;

	inline function get_AO()
		return this.AO ?? this.AlphaOffset;

	inline function get_TC()
		return this.TC ?? this.tintColor;

	inline function get_TM()
		return this.TM ?? this.tintMultiplier;

	inline function get_BRT()
		return this.BRT ?? this.brightness;
}

extern typedef TransformationPointJson =
{
	x:Float,
	y:Float
}

abstract MatrixJson(Array<Float>) from Array<Float>
{
	public var a(get, never):Float;
	public var b(get, never):Float;
	public var c(get, never):Float;
	public var d(get, never):Float;
	public var tx(get, never):Float;
	public var ty(get, never):Float;

	public static function resolve(input:Dynamic):MatrixJson
	{
		var mat2D:Null<MatrixJson> = input.MX ?? input.Matrix;
		if (mat2D != null)
			return mat2D;

		var m:Dynamic = input.M3D ?? input.Matrix3D;
		var mat3D:Array<Float>;

		if (m is Array)
		{
			mat3D = m;
		}
		else
		{
			mat3D = [
				m.m00, m.m01, m.m02, m.m03, m.m10, m.m11, m.m12, m.m13, m.m20, m.m21, m.m22, m.m23, m.m30, m.m31, m.m32, m.m33
			];
		}

		return from3Dto2D(mat3D);
	}

	public static function from3Dto2D(mat3D:Array<Float>):Array<Float>
	{
		final hasPerspective:Bool = (mat3D[3] != 0) || (mat3D[7] != 0) || (mat3D[11] != 0) || (mat3D[15] != 1);
		if (!hasPerspective)
			return [mat3D[0], mat3D[1], mat3D[4], mat3D[5], mat3D[12], mat3D[13]];

		var points:Array<Array<Float>> = [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]];
		var transformed:Array<Array<Float>> = [];

		for (p in points)
		{
			var x = p[0];
			var y = p[1];
			var z = mat3D[3] * x + mat3D[7] * y + mat3D[15];
			transformed.push([
				mat3D[0] * x + mat3D[4] * y + mat3D[12] / z,
				mat3D[1] * x + mat3D[5] * y + mat3D[13] / z
			]);
		}

		var p0:Array<Float> = transformed[0];
		var p1:Array<Float> = transformed[1];
		var p2:Array<Float> = transformed[2];

		var a:Float = p1[0] - p0[0];
		var b:Float = p1[1] - p0[1];
		var c:Float = p2[0] - p0[0];
		var d:Float = p2[1] - p0[1];
		var tx:Float = p0[0];
		var ty:Float = p0[1];

		return [a, b, c, d, tx, ty];
	}

	extern public inline function toMatrix():FlxMatrix
	{
		return new FlxMatrix(a, b, c, d, tx, ty);
	}

	extern inline function get_a()
		return this[0];

	extern inline function get_b()
		return this[1];

	extern inline function get_c()
		return this[2];

	extern inline function get_d()
		return this[3];

	extern inline function get_tx()
		return this[4];

	extern inline function get_ty()
		return this[5];
}
