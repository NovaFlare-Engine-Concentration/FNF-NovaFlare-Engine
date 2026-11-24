package general.backend.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class ImageCompressionMacro
{
	public static function checkFlixelPatch():Array<Field>
	{
		var fields = Context.getBuildFields();
		for (field in fields)
			if (field.name == "textureScaleX") return fields;
		return Context.error("Install the ImageCoordinates component of tools/setup-novaflare-render-dependencies.ps1 before building.", Context.currentPos());
	}

	public static function buildImage():Array<Field>
	{
		var fields = Context.getBuildFields();
		addSourceDimensions(fields);
		preserveCloneDimensions(fields, "image");
		fields.push({
			name: "isDecodedImage",
			access: [APublic],
			kind: FVar(macro:Bool, macro false),
			pos: Context.currentPos()
		});
		fields.push({
			name: "reopenCompressionSource",
			access: [APublic],
			kind: FVar(macro:Void->lime.graphics.Image),
			pos: Context.currentPos()
		});
		for (decoder in ["__fromFile", "__fromBytes", "__fromBase64"])
		{
			var method = findMethod(fields, decoder);
			var reopen = switch (decoder)
			{
				case "__fromFile": macro lime.graphics.Image.fromFile.bind(path);
				case "__fromBytes": macro {
					var encoded = bytes == null ? null : bytes.sub(0, bytes.length);
					lime.graphics.Image.fromBytes.bind(encoded);
				};
				default: macro lime.graphics.Image.fromBase64.bind(base64, type);
			};
			var encoded = decoder == "__fromFile" ? macro path : macro bytes;
			var scaledDecode = decoder == "__fromBase64" ? macro {} : macro
			{
				if (general.backend.ImageCompression.decodeScaled(this, $e{encoded}))
				{
					if (onload != null) onload(this);
					return true;
				}
			};
			method.expr = macro
			{
				isDecodedImage = true;
				reopenCompressionSource = $e{reopen};
				$e{scaledDecode};
				$e{method.expr};
			};
		}
		var loadFromBytes = findMethod(fields, "loadFromBytes");
		loadFromBytes.expr = macro
		{
			if (bytes != null && general.backend.ImageCompression.hasScaledDecodeScope())
				return new lime.app.Future(() -> general.backend.ImageCompression.withScaledDecode(() -> fromBytes(bytes)), true);
			$e{loadFromBytes.expr};
		};
		var loadFromFile = findMethod(fields, "loadFromFile");
		loadFromFile.expr = macro
		{
			if (path != null && general.backend.ImageCompression.hasScaledDecodeScope())
				return general.backend.ImageCompression.loadScopedFile(path);
			$e{loadFromFile.expr};
		};
		var fromElement = findMethod(fields, "fromImageElement");
		fromElement.expr = ExprTools.map(fromElement.expr, function(expr)
		{
			return switch (expr.expr)
			{
				case EReturn({expr: EConst(CIdent("_image"))}):
					macro
					{
						_image.isDecodedImage = true;
						return _image;
					};
				default: expr;
			}
		});
		return fields;
	}

	public static function buildBitmapData():Array<Field>
	{
		var fields = Context.getBuildFields();
		addSourceDimensions(fields);
		fields = fields.concat(liveBitmapFields());
		preserveCloneDimensions(fields, "bitmapData", true);
		var adoptImage = findMethod(fields, "__fromImage");
		adoptImage.expr = macro
		{
			var fromDecodedSource = image != null && image.isDecodedImage;
			if (fromDecodedSource)
				image = general.backend.ImageCompression.adopt(this, image);
			imageSourceWidth = image == null ? 0 : image.imageSourceWidth;
			imageSourceHeight = image == null ? 0 : image.imageSourceHeight;
			$e{adoptImage.expr};
			if (fromDecodedSource && image != null)
			{
				imageCompressionVersion = image.version;
				general.backend.ImageCompression.finishAdopting(this);
			}
		};
		for (decoder in ["__fromBytes", "__loadFromBytes", "loadFromBytes"])
		{
			var method = findMethod(fields, decoder);
			method.expr = ExprTools.map(method.expr, preserveRawAlpha);
		}
		for (decoder in ["__fromBytes", "__fromFile", "__fromBase64", "loadFromBytes", "loadFromFile", "loadFromBase64",
			"__loadFromBytes", "__loadFromFile", "__loadFromBase64"])
		{
			var method = findMethod(fields, decoder);
			var enabled = StringTools.endsWith(decoder, "Bytes") ? macro rawAlpha == null : macro true;
			method.expr = scopeDecodeCalls(method.expr, "Image", ["fromBytes", "fromBase64", "fromFile", "loadFromBytes", "loadFromFile", "loadFromBase64"],
				enabled);
		}
		var upload = findMethod(fields, "getTextureAsync");
		upload.expr = ExprTools.map(upload.expr, trackAsyncUpload);
		return fields;
	}

	public static function buildAssets():Array<Field>
	{
		var fields = Context.getBuildFields();
		for (name in ["getBitmapData", "loadBitmapData"])
		{
			var method = findMethod(fields, name);
			method.expr = scopeDecodeCalls(method.expr, "LimeAssets", ["getImage", "loadImage"], macro true);
		}
		return fields;
	}

	public static function buildAssetLibrary():Array<Field>
	{
		var fields = Context.getBuildFields();
		var loadImage = findMethod(fields, "loadImage");
		function preserveRawCache(expr:Expr):Expr
		{
			return switch (expr.expr)
			{
				case ECall({expr: EField({expr: EConst(CIdent("cachedBytes"))}, "remove")}, _)
					| ECall({expr: EField({expr: EConst(CIdent("cachedImages"))}, "set")}, _):
					macro if (cacheOriginalImage) $e{expr};
				default: ExprTools.map(expr, preserveRawCache);
			}
		}
		var original = preserveRawCache(loadImage.expr);
		loadImage.expr = macro
		{
			// A scaled display texture must never replace the readable source image.
			var cacheOriginalImage = !general.backend.ImageCompression.hasScaledDecodeScope();
			$e{original};
		};
		return fields;
	}

	public static function buildDeferredAssetLibrary():Array<Field>
	{
		var fields = Context.getBuildFields();
		var loadImage = findMethod(fields, "loadImage");
		var original = scopeDecodeCalls(loadImage.expr, "Image", ["loadFromBytes"], macro scaleInCallback);
		loadImage.expr = macro
		{
			var scaleInCallback = general.backend.ImageCompression.hasScaledDecodeScope();
			$e{original};
		};
		return fields;
	}

	static function scopeDecodeCalls(expr:Expr, owner:String, methods:Array<String>, enabled:Expr):Expr
	{
		return switch (expr.expr)
		{
			case ECall({expr: EField({expr: EConst(CIdent(callOwner))}, name)}, _) if (owner == callOwner && methods.contains(name)):
				macro general.backend.ImageCompression.withScaledDecode(() -> $e{expr}, $e{enabled});
			default: ExprTools.map(expr, child -> scopeDecodeCalls(child, owner, methods, enabled));
		}
	}

	static function liveBitmapFields():Array<Field>
	{
		return (macro class LiveCompression
		{
			var imageCompressionVersion:Int = -1;
			public var imageCompressionUploads(default, null):Int = 0;

			@:noCompletion public function canRefreshCompression():Bool
			{
				return __isValid && imageCompressionVersion >= 0 && __framebuffer == null
					&& (image == null || image.version == imageCompressionVersion);
			}

			@:noCompletion public function applyRefreshedCompression(replacement:lime.graphics.Image):Void
			{
				if (!readable) disposeOnUpload = true;
				__texture = null;
				__textureContext = null;
				__textureVersion = -1;
				__vertexBuffer = null;
				__vertexBufferData = null;
				__surface = null;
				graphicScale = 1;
				replacement.isDecodedImage = false;
				__fromImage(replacement);
				replacement.transparent = transparent;
				if (replacement.version <= imageCompressionVersion) replacement.version = imageCompressionVersion + 1;
				imageCompressionVersion = replacement.version;
			}
		}).fields;
	}

	static function trackAsyncUpload(expr:Expr):Expr
	{
		return switch (expr.expr)
		{
			case ECall(target = {expr: EField({expr: EConst(CIdent("uploader"))}, "init")}, args):
				switch (args[args.length - 1].expr)
				{
					case EFunction(_, callback):
						callback.expr = macro
						{
							imageCompressionUploads--;
							$e{callback.expr};
						};
					default:
				}
				macro {
					imageCompressionUploads++;
					$e{target}($a{args});
				};
			default: ExprTools.map(expr, trackAsyncUpload);
		}
	}

	public static function buildSpineTextureLoader():Array<Field>
	{
		var fields = Context.getBuildFields();
		var loadPage = findMethod(fields, "loadPage");
		loadPage.expr = ExprTools.map(loadPage.expr, function(expr)
		{
			return switch (expr.expr)
			{
				case EBinop(OpAssign, target, physical = {expr: EField({expr: EConst(CIdent("bitmapData"))}, dimension)})
					if (dimension == "width" || dimension == "height"):
					var original = dimension == "width" ? macro bitmapData.imageSourceWidth : macro bitmapData.imageSourceHeight;
					macro $e{target} = $e{original} > 0 ? $e{original} : $e{physical};
				default: expr;
			}
		});
		return fields;
	}

	static function preserveRawAlpha(expr:Expr):Expr
	{
		return switch (expr.expr)
		{
			case ECall(target = {expr: EConst(CIdent("__fromImage"))}, [image])
				| ECall(target = {expr: EField(_, "fromImage")}, [image]):
				macro $e{target}(rawAlpha == null ? $e{image} : general.backend.ImageCompression.keepOriginal($e{image}));
			default: ExprTools.map(expr, preserveRawAlpha);
		}
	}

	static function addSourceDimensions(fields:Array<Field>):Void
	{
		for (dimension in ["imageSourceWidth", "imageSourceHeight"])
		{
			fields.push({
				name: dimension,
				access: [APublic],
				kind: FVar(macro:Int, macro 0),
				pos: Context.currentPos(),
				doc: "Original pixel dimension of a compressed image. Zero for images kept at their original size."
			});
		}
	}

	static function preserveCloneDimensions(fields:Array<Field>, cloneName:String, copyScale:Bool = false):Void
	{
		var clone = findMethod(fields, "clone");
		var scaleAssignment = copyScale ? macro
		{
			$i{cloneName}.graphicScale = graphicScale;
			$i{cloneName}.imageCompressionVersion = imageCompressionVersion;
			general.backend.ImageCompression.trackClone(this, $i{cloneName});
		} : macro {};
		function copyDimensions(expr:Expr):Expr
		{
			return switch (expr.expr)
			{
				case EReturn({expr: EConst(CIdent(name))}) if (name == cloneName):
					macro
					{
						$i{name}.imageSourceWidth = imageSourceWidth;
						$i{name}.imageSourceHeight = imageSourceHeight;
						$e{scaleAssignment};
						return $i{name};
					};
				default: ExprTools.map(expr, copyDimensions);
			}
		}
		clone.expr = ExprTools.map(clone.expr, copyDimensions);
	}

	static function findMethod(fields:Array<Field>, name:String):Function
	{
		for (field in fields)
		{
			if (field.name != name) continue;
			switch (field.kind)
			{
				case FFun(method): return method;
				default:
			}
		}
		return Context.error('Image compression requires method $name', Context.currentPos());
	}
}
#end
