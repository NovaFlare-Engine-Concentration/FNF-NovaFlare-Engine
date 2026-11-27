import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import general.backend.ImageCompression;
import haxe.crypto.Base64;
import haxe.io.Path;
import haxe.Timer;
import lime.app.Future;
import lime.graphics.Image;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLTexture;
import lime.system.System;
import lime.utils.AssetLibrary;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.display3D.textures.TextureBase;
import openfl.utils.Assets;
import openfl.utils.ByteArray;
import sys.FileSystem;
import sys.io.File;

class Main extends Sprite
{
    public function new()
    {
        super();
        addChild(new FlxGame(160, 128, CompressionCheck, 60, 60, true));
    }
}

@:access(flixel.graphics.tile.FlxDrawQuadsItem)
private class CompressionCheck extends FlxState
{
    static inline var SOURCE_WIDTH = 11;
    static inline var SOURCE_HEIGHT = 7;
    static inline var STORED_WIDTH = 5;
    static inline var STORED_HEIGHT = 3;
    static inline var COLOR = 0xff149c38;
    static inline var FIXTURE_PNG = "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAHCAYAAADebrddAAAAFUlEQVR4nGMQmWPxn1jMMKp4DkIxAMoiknzyQE1sAAAAAElFTkSuQmCC";
    static inline var PALETTE_PNG = "iVBORw0KGgoAAAANSUhEUgAAAAsAAAAHCAMAAADpsEdvAAAABlBMVEUUnDjoLVoQLIAAAAAAEklEQVR4nGNgYIRDJCYKh1RxAAaQACcAUcmbAAAAAElFTkSuQmCC";
    static inline var ASSET_KEY = "novaflare-compression-test:sheet.png";

    var fixturePath:String;
    var deadline:Float;
    var phase:Int = 0;
    var liveBitmaps:Array<BitmapData>;
    var editedBitmap:BitmapData;
    var gpuBitmap:BitmapData;
    var gpuClone:BitmapData;
    var borrowedBitmap:BitmapData;
    var uploadingBitmap:BitmapData;
    var currentTexture:TextureBase;
    var cloneTexture:TextureBase;
    var currentTextureId:GLTexture;
    var cloneTextureId:GLTexture;
    var uploadFinished:Bool = false;
    var liveFrame:FlxFrame;

    override public function create():Void
    {
        super.create();
        try
        {
            ImageCompression.configure(64, 5, 0.75);
            var xmlFrame = checkSparrow();
            checkOtherAtlases();
            checkGridAndCrop();
            checkDrawItems(xmlFrame);
            checkBitmapPaint(xmlFrame);
            checkCompressionPolicy();
            Sys.println("PASS compressed image atlas, grid, trim, rotation, clipping, quad, triangle, and pixel extraction");
            startAsyncChecks();
        }
        catch (error:haxe.Exception)
        {
            fail(error);
        }
    }

    @:access(lime.utils.AssetLibrary)
    function startAsyncChecks():Void
    {
        var encoded = Base64.decode(FIXTURE_PNG);
        var bytes = ByteArray.fromBytes(encoded);
        fixturePath = Path.join([Sys.getCwd(), "image-compression-source.png"]);
        File.saveBytes(fixturePath, encoded);
        var library = new AssetLibrary();
        library.types.set("sheet.png", IMAGE);
        library.paths.set("sheet.png", fixturePath);
        lime.utils.Assets.registerLibrary("novaflare-compression-test", library);
        deadline = Timer.stamp() + 12;
        #if cpp
        ImageCompression.configure(64, 0, 1);
        if (!ImageCompression.canDecodeScaled()) throw new haxe.Exception("Lime's native scaled decoder is unavailable.");
        library.preload.set("sheet.png", true);
        library.load().onComplete(_ ->
        {
            try
            {
                if (library.cachedImages.exists("sheet.png")) throw new haxe.Exception("Preload retained the original pixels.");
                var source = library.cachedBytes.get("sheet.png");
                if (source == null || source.compare(encoded) != 0) throw new haxe.Exception("Preload did not retain the encoded PNG.");
                ImageCompression.configure(64, 5, 0.75);
                var image = ImageCompression.withScaledDecode(() -> Image.fromFile(fixturePath));
                equal(image.width, STORED_WIDTH, "native decoded width before BitmapData");
                equal(image.height, STORED_HEIGHT, "native decoded height before BitmapData");
                equal(image.data.byteLength, STORED_WIDTH * STORED_HEIGHT * 4, "native decoded pixel bytes");
                Sys.println("PASS native scaled PNG buffer and encoded image preload");
                runAsyncLoads(bytes);
            }
            catch (error:haxe.Exception)
            {
                fail(error);
            }
        }).onError(error -> fail(new haxe.Exception('Image preload failed: $error')));
        #else
        runAsyncLoads(bytes);
        #end
    }

    function runAsyncLoads(bytes:ByteArray):Void
    {
        ImageCompression.configure(64, 5, 0.75);
        AsyncDecodeTrace.start(fixturePath, [Base64.decode(FIXTURE_PNG), Base64.decode(PALETTE_PNG)]);
        verifyExactPalette();

        var checks:Array<AsyncImageCheck> = [
            {name: "BitmapData.loadFromBytes", scoped: true, load: () -> BitmapData.loadFromBytes(bytes), verify: verifyAsyncAtlas},
            {name: "BitmapData.loadFromFile", scoped: true, load: () -> BitmapData.loadFromFile(fixturePath), verify: verifyAsyncAtlas},
            {
                name: "BitmapData.loadFromBytes with raw alpha",
                scoped: false,
                load: () -> ImageCompression.withScaledDecode(() -> BitmapData.loadFromBytes(bytes, fixtureAlpha())),
                verify: verifyExactAlpha
            },
            {name: "Lime Image.loadFromFile", scoped: false, load: loadRawLimeImage, verify: bitmap -> equal(bitmap.width, SOURCE_WIDTH, "raw Lime image width")},
            {name: "Assets.loadBitmapData", scoped: true, load: () -> Assets.loadBitmapData(ASSET_KEY), verify: verifyCachedAtlas}
        ];
        runAsyncChecks(checks.iterator());
    }

    function runAsyncChecks(checks:Iterator<AsyncImageCheck>):Void
    {
        if (!checks.hasNext())
        {
            AsyncDecodeTrace.stop();
            Sys.println("PASS async bitmap and asset decode scope, rotated atlas, raw alpha, and exact palette");
            startLiveChecks();
            return;
        }

        var check = checks.next();
        check.load().onComplete(bitmap ->
        {
            try
            {
                AsyncDecodeTrace.check(check.name, check.scoped, check.scoped ? true : null);
                check.verify(bitmap);
                runAsyncChecks(checks);
            }
            catch (error:haxe.Exception)
            {
                fail(error);
            }
        }).onError(error -> fail(new haxe.Exception('${check.name}: $error')));
    }

    function verifyAsyncAtlas(bitmap:BitmapData):Void
    {
        equal(bitmap.width, STORED_WIDTH, "asynchronous stored width");
        equal(bitmap.height, STORED_HEIGHT, "asynchronous stored height");
        equal(bitmap.image.data.byteLength, STORED_WIDTH * STORED_HEIGHT * 4, "asynchronous stored pixel bytes");
        equal(bitmap.imageSourceWidth, SOURCE_WIDTH, "asynchronous source width");
        equal(bitmap.imageSourceHeight, SOURCE_HEIGHT, "asynchronous source height");
        checkBitmapPaint(checkSparrowFrame(FlxGraphic.fromBitmapData(bitmap)));
    }

    function verifyCachedAtlas(bitmap:BitmapData):Void
    {
        verifyAsyncAtlas(bitmap);
        if (Assets.getBitmapData(ASSET_KEY) != bitmap) throw new haxe.Exception("The cached bitmap was replaced.");
        AsyncDecodeTrace.checkCache();
        var raw = lime.utils.Assets.getImage(ASSET_KEY, false);
        equal(raw.width, SOURCE_WIDTH, "raw library image width stays original after caching a compressed bitmap");
        AsyncDecodeTrace.check("Lime Assets.getImage", false, false);
    }

    function loadRawLimeImage():Future<BitmapData>
    {
        return Image.loadFromFile(fixturePath).then(image ->
        {
            equal(image.width, SOURCE_WIDTH, "raw Lime source width");
            equal(image.height, SOURCE_HEIGHT, "raw Lime source height");
            equal(image.imageSourceWidth, 0, "raw Lime carries no compressed width");
            return Future.withValue(BitmapData.fromImage(ImageCompression.keepOriginal(image)));
        });
    }

    function verifyExactPalette():Void
    {
        var image = Image.fromBytes(Base64.decode(PALETTE_PNG));
        equal(image.width, SOURCE_WIDTH, "raw palette image width");
        equal(image.imageSourceWidth, 0, "raw palette carries no compressed width");
        var palette = BitmapData.fromImage(ImageCompression.keepOriginal(image));
        equal(palette.width, SOURCE_WIDTH, "exact palette width");
        equal(palette.getPixel32(0, 0), COLOR, "first exact palette color");
        equal(palette.getPixel32(1, 0), 0xffe82d5a, "second exact palette color");
        AsyncDecodeTrace.check("Lime Image.fromBytes", false, false);
    }

    function startLiveChecks():Void
    {
        GL.setMultiThreaded(false);
        ImageCompression.configure(64, 0, 1);
        var bytes = ByteArray.fromBytes(Base64.decode(FIXTURE_PNG));
        var fileBitmap = BitmapData.fromFile(fixturePath);
        var bytesBitmap = BitmapData.fromBytes(bytes);
        editedBitmap = bytesBitmap.clone();
        editedBitmap.setPixel32(0, 0, 0xffff0000);

        gpuBitmap = BitmapData.fromFile(fixturePath, true);
        currentTexture = gpuBitmap.getTexture(FlxG.stage.context3D);
        currentTextureId = @:privateAccess currentTexture.__textureID;
        checkGpuOnly();
        gpuClone = gpuBitmap.clone();
        cloneTexture = gpuClone.getTexture(FlxG.stage.context3D);
        if (cloneTexture != currentTexture) throw new haxe.Exception("GPU-only clone did not share its source texture.");
        cloneTextureId = currentTextureId;
        borrowedBitmap = BitmapData.fromTexture(currentTexture);
        uploadingBitmap = BitmapData.fromBytes(bytes);
        uploadingBitmap.disposeOnUpload = true;
        uploadingBitmap.getTextureAsync(FlxG.stage.context3D, _ -> uploadFinished = true, 3);
        equal(uploadingBitmap.imageCompressionUploads, 1, "asynchronous upload is tracked");

        liveBitmaps = [fileBitmap, bytesBitmap, bytesBitmap.clone(), Assets.getBitmapData(ASSET_KEY), gpuBitmap, gpuClone, uploadingBitmap];
        liveFrame = checkSparrowFrame(FlxGraphic.fromBitmapData(bytesBitmap));
        deadline = Timer.stamp() + 12;
        rebuildImages(0.25);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        try
        {
            if (Timer.stamp() > deadline) throw new haxe.Exception('Image compression stalled at phase $phase.');
            if (liveBitmaps == null) return;
            var expected = switch (phase) { case 0: 5; case 1: 3; default: SOURCE_WIDTH; };
            for (bitmap in liveBitmaps)
                if (bitmap.width != expected) return;
            if (phase == 2 && @:privateAccess ImageCompression.processing) return;
            if (borrowedBitmap != null)
            {
                if (borrowedBitmap.getTexture(FlxG.stage.context3D) != currentTexture || !GL.isTexture(currentTextureId))
                    throw new haxe.Exception("Image compression deleted a texture while another bitmap was borrowing it.");
                borrowedBitmap.dispose();
                borrowedBitmap = null;
                return;
            }
            verifyLiveImages(expected);
            switch (phase++)
            {
                case 0:
                    rebuildImages(0.81);
                    rebuildImages(0.1);
                case 1:
                    rebuildImages(1);
                case 2:
                    Sys.println("PASS live reload and deletion of replaced GPU textures, including shared clones and async uploads");
                    exit(0);
            }
        }
        catch (error:haxe.Exception)
        {
            fail(error);
        }
    }

    function verifyLiveImages(expected:Int):Void
    {
        equal(liveFrame.parent.width, SOURCE_WIDTH, "existing graphic retains logical width");
        equal(liveFrame.parent.textureScaleX, expected / SOURCE_WIDTH, "existing graphic uses new density");
        equal(liveFrame.frame.x, 7, "existing frame retains atlas coordinates");
        checkBitmapPaint(liveFrame);
        equal(editedBitmap.width, SOURCE_WIDTH, "edited bitmap retains its width");
        equal(editedBitmap.getPixel32(0, 0), 0xffff0000, "edited pixels survive reloading");
        equal(uploadingBitmap.imageCompressionUploads, 0, "asynchronous upload has finished");
        if (!uploadFinished) throw new haxe.Exception("The asynchronous upload did not call back.");
        verifyTextureDeleted(currentTexture, currentTextureId);
        if (currentTexture != cloneTexture) verifyTextureDeleted(cloneTexture, cloneTextureId);
        currentTexture = gpuBitmap.getTexture(FlxG.stage.context3D);
        cloneTexture = gpuClone.getTexture(FlxG.stage.context3D);
        currentTextureId = @:privateAccess currentTexture.__textureID;
        cloneTextureId = @:privateAccess cloneTexture.__textureID;
        if (currentTextureId == null || cloneTextureId == null) throw new haxe.Exception("The replacement textures were not uploaded.");
        checkGpuOnly();
    }

    @:access(openfl.display3D.textures.TextureBase)
    function verifyTextureDeleted(oldTexture:TextureBase, oldId:GLTexture):Void
    {
        if (oldTexture.__textureID != null || GL.isTexture(oldId)) throw new haxe.Exception("The old GPU texture was not deleted.");
    }

    function checkGpuOnly():Void
    {
        if (gpuBitmap.readable || gpuBitmap.image != null) throw new haxe.Exception("A GPU-only texture kept its CPU copy.");
    }

    function rebuildImages(ratio:Float):Void
    {
        ImageCompression.configure(64, 0, ratio);
        ImageCompression.refreshLoadedImages();
    }

    function fail(error:haxe.Exception):Void
    {
        Sys.stderr().writeString('FAIL ${error.details()}\n');
        exit(1);
    }

    function exit(code:Int):Void
    {
        if (fixturePath != null && FileSystem.exists(fixturePath)) FileSystem.deleteFile(fixturePath);
        System.exit(code);
    }

    function checkCompressionPolicy():Void
    {
        var encoded = Base64.decode(FIXTURE_PNG);
        var png = ByteArray.fromBytes(encoded);
        ImageCompression.configure(5, 8, 0.75);
        var bitmap = BitmapData.fromBytes(png);
        equal(bitmap.width, 5, "device limit takes precedence");
        equal(bitmap.clone().imageSourceWidth, SOURCE_WIDTH, "clone retains original dimensions");
        equal(new BitmapData(4, 2).clone().width, 4, "generated bitmaps retain their dimensions");
        equal(BitmapData.fromImage(ImageCompression.keepOriginal(Image.fromBytes(encoded))).width, SOURCE_WIDTH, "full source decode");

        verifyExactAlpha(BitmapData.fromBytes(png, fixtureAlpha()));

        ImageCompression.configure(64, 0, 0);
        var minimum = BitmapData.fromBytes(png);
        equal(minimum.width, 3, "legacy zero clamps to ten percent of the area");
        equal(minimum.height, 2, "minimum ratio retains the aspect ratio");
        ImageCompression.configure(64, 0, 0.25);
        var quarterArea = ImageCompression.resize(new Image(null, 0, 0, 20, 12));
        equal(quarterArea.width, 10, "quarter area halves width");
        equal(quarterArea.height, 6, "quarter area halves height");
        equal(quarterArea.width * quarterArea.height, 60, "quarter area applies the ratio once");
        ImageCompression.configure(64, 0, 1);
        equal(BitmapData.fromBytes(png).width, SOURCE_WIDTH, "default ratio retains original width");

        ImageCompression.configure(64, 0, 0, SOURCE_WIDTH + 1);
        equal(BitmapData.fromBytes(png).width, SOURCE_WIDTH, "below the start size skips the ratio");
        ImageCompression.configure(64, 0, 0, SOURCE_WIDTH);
        equal(BitmapData.fromBytes(png).width, 3, "equal to the start size applies the ratio");
        ImageCompression.configure(64, 5, 0, SOURCE_WIDTH + 1);
        equal(BitmapData.fromBytes(png).width, 5, "maximum side applies below the start size");
        ImageCompression.configure(8, 0, 0, 64);
        equal(BitmapData.fromBytes(png).width, 3, "the start size is clamped to the device limit");
    }

    static function fixtureAlpha():ByteArray
    {
        var alpha = new ByteArray();
        for (index in 0...(SOURCE_WIDTH * SOURCE_HEIGHT)) alpha.writeByte(145 + index);
        alpha.position = 0;
        return alpha;
    }

    static function verifyExactAlpha(bitmap:BitmapData):Void
    {
        equal(bitmap.width, SOURCE_WIDTH, "separate alpha retains original dimensions");
        equal(bitmap.getPixel32(SOURCE_WIDTH - 1, SOURCE_HEIGHT - 1) >>> 24, 221, "last alpha byte applies to the last pixel");
    }

    function checkSparrow():FlxFrame
    {
        var graphic = makeGraphic();
        equal(graphic.bitmap.width, STORED_WIDTH, "stored width");
        equal(graphic.bitmap.height, STORED_HEIGHT, "stored height");
        equal(graphic.width, SOURCE_WIDTH, "original width");
        equal(graphic.height, SOURCE_HEIGHT, "original height");
        return checkSparrowFrame(graphic);
    }

    function checkSparrowFrame(graphic:FlxGraphic):FlxFrame
    {
        var atlas = FlxAtlasFrames.fromSparrow(graphic,
            '<TextureAtlas><SubTexture name="limb" x="7" y="2" width="4" height="5" rotated="true"
                frameX="-2" frameY="-3" frameWidth="9" frameHeight="8" /></TextureAtlas>');
        var frame = atlas.getByName("limb");
        checkRotatedFrame(frame);
        var sprite = new FlxSprite();
        sprite.frames = atlas;
        equal(sprite.frameWidth, 9, "sprite frame width");
        equal(sprite.frameHeight, 8, "sprite frame height");
        return frame;
    }

    function checkOtherAtlases():Void
    {
        var json = '{"frames":{"limb":{"frame":{"x":7,"y":2,"w":5,"h":4},"rotated":true,"trimmed":true,
            "spriteSourceSize":{"x":2,"y":3,"w":5,"h":4},"sourceSize":{"w":9,"h":8}}}}';
        var atlas = FlxAtlasFrames.fromTexturePackerJson(makeGraphic(), json);
        checkRotatedFrame(atlas.getByName("limb"));
        var text = FlxAtlasFrames.fromSpriteSheetPacker(makeGraphic(), "corner = 7 2 4 5").getByName("corner");
        equal(text.frame.right, SOURCE_WIDTH, "text frame right edge");
        equal(text.frame.bottom, SOURCE_HEIGHT, "text frame bottom edge");
    }

    function checkGridAndCrop():Void
    {
        var graphic = makeGraphic();
        var sprite = new FlxSprite().loadGraphic(graphic, true, 5, 3);
        var sheet:FlxTileFrames = cast sprite.frames;
        equal(sheet.numCols, 2, "grid columns");
        equal(sheet.numRows, 2, "grid rows");
        var tile = sheet.getByTilePosition(1, 1);
        equal(tile.frame.x, 5, "second-column tile x");
        equal(tile.frame.y, 3, "second-row tile y");
        var crop = tile.subFrameTo(FlxRect.get(1, 1, 2, 2));
        equal(crop.frame.x, 6, "crop x");
        equal(crop.frame.y, 4, "crop y");
        var withBorders = FlxTileFrames.fromBitmapAddSpacesAndBorders(graphic, FlxPoint.get(5, 3), null, FlxPoint.get(1, 1));
        equal(withBorders.numFrames, 4, "tiles with copied border pixels");
        var rotations = new FlxSprite().loadRotatedGraphic(graphic, 4, 0);
        equal(rotations.frameWidth, SOURCE_HEIGHT, "rotation uses original frame width");
        equal(rotations.frameHeight, SOURCE_HEIGHT, "rotation uses original frame height");
    }

    function checkDrawItems(frame:FlxFrame):Void
    {
        var matrix = frame.prepareMatrix(new FlxMatrix());
        var quads = new FlxDrawQuadsItem();
        quads.addQuad(frame, matrix);
        equal(quads.rects[0] / STORED_WIDTH, 7 / SOURCE_WIDTH, "quad left UV");
        equal(quads.rects[1] / STORED_HEIGHT, 2 / SOURCE_HEIGHT, "quad top UV");
        equal(quads.rects[0] + quads.rects[2], STORED_WIDTH, "quad right edge reaches stored width");
        equal(quads.rects[1] + quads.rects[3], STORED_HEIGHT, "quad bottom edge reaches stored height");
        equal(quads.transforms[0] * quads.rects[2], matrix.a * frame.frame.width, "quad rotated horizontal X");
        equal(quads.transforms[1] * quads.rects[2], matrix.b * frame.frame.width, "quad rotated horizontal Y");
        equal(quads.transforms[2] * quads.rects[3], matrix.c * frame.frame.height, "quad rotated vertical X");
        equal(quads.transforms[3] * quads.rects[3], matrix.d * frame.frame.height, "quad rotated vertical Y");
        equal(quads.transforms[4], matrix.tx, "quad preserves x translation");
        equal(quads.transforms[5], matrix.ty, "quad preserves y translation");

        var triangles = new FlxDrawTrianglesItem();
        triangles.addQuad(frame, matrix);
        equal(triangles.uvtData[0], quads.rects[0] / STORED_WIDTH, "triangle matches quad left UV");
        equal(triangles.uvtData[1], quads.rects[1] / STORED_HEIGHT, "triangle matches quad top UV");
        equal(triangles.vertices[4], matrix.a * frame.frame.width + matrix.c * frame.frame.height + matrix.tx, "triangle rotated X");
        equal(triangles.vertices[5], matrix.b * frame.frame.width + matrix.d * frame.frame.height + matrix.ty, "triangle rotated Y");
    }

    function checkBitmapPaint(frame:FlxFrame):Void
    {
        var painted = frame.paint();
        equal(painted.width, 9, "painted width");
        equal(painted.height, 8, "painted height");
        equal(painted.getPixel32(0, 0), 0, "paint leaves trim transparent");
        equal(painted.getPixel32(3, 4), COLOR, "paint places the limb at its original offset");
        painted.dispose();
    }

    static function checkRotatedFrame(frame:FlxFrame):Void
    {
        equal(frame.angle, -90, "rotation");
        equal(frame.frame.x, 7, "atlas x");
        equal(frame.frame.y, 2, "atlas y");
        equal(frame.frame.right, SOURCE_WIDTH, "atlas right edge");
        equal(frame.frame.bottom, SOURCE_HEIGHT, "atlas bottom edge");
        equal(frame.sourceSize.x, 9, "untrimmed width");
        equal(frame.sourceSize.y, 8, "untrimmed height");
        equal(frame.offset.x, 2, "trim x");
        equal(frame.offset.y, 3, "trim y");
    }

    static function makeGraphic():FlxGraphic
    {
        var png = ByteArray.fromBytes(Base64.decode(FIXTURE_PNG));
        return FlxGraphic.fromBitmapData(BitmapData.fromBytes(png));
    }

    static function equal(actual:Float, expected:Float, description:String):Void
    {
        if (Math.isNaN(actual) || Math.abs(actual - expected) > 0.000001)
            throw new haxe.Exception('$description expected $expected, got $actual');
    }
}

private typedef AsyncImageCheck = {
    final name:String;
    final scoped:Bool;
    final load:Void->Future<BitmapData>;
    final verify:BitmapData->Void;
}
