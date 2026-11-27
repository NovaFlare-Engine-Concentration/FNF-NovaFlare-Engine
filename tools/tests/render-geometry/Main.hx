import haxe.io.Bytes;
import lime.graphics.RenderContext;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.system.System;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.GraphicsShader;
import openfl.display.Sprite;
import openfl.display.Tile;
import openfl.display.TileContainer;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.events.Event;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;

class Main extends Sprite
{
    static inline var MIN_DRAWABLE_SIZE = 128;
    static inline var MIN_DRAWABLE_WIDTH = 152;
    static inline var QUADS_PER_ROW = 64;
    static inline var LARGE_QUAD_COUNT = 16390;
    static inline var SMALL_QUAD_COUNT = 128;
    static inline var BYTES_PER_QUAD = 64;

    final shape = new Sprite();
    final transformShape = new Sprite();
    final shaderQuads = [new Sprite(), new Sprite()];
    final texture = new BitmapData(1, 1, false, 0xFFFFFFFF);
    final atlas = new BitmapData(16, 8, false, 0xFFFF0000);
    final tileGroups:Array<TileContainer> = [];
    final pixel = Bytes.alloc(4);
    final requireTicketReuse = Sys.getEnv("NOVAFLARE_TEST_SHADER_RECAPTURE") == "1";
    final requireCompactQuads = Sys.getEnv("NOVAFLARE_TEST_COMPACT_QUADS") == "1";
    var checkFrame:Int = 0;
    var initialBuffer:GLBuffer;
    var failure:Null<String>;

    public function new()
    {
        super();
        addEventListener(Event.ADDED_TO_STAGE, begin);
    }

    function begin(_:Event):Void
    {
        removeEventListener(Event.ADDED_TO_STAGE, begin);
        final renderThread = Sys.getEnv("NOVAFLARE_RENDER_THREAD");
        if (renderThread != null) GL.setMultiThreaded(renderThread != "0");
        addChild(shape);
        addChild(transformShape);
        atlas.fillRect(new Rectangle(8, 0, 8, 8), 0xFF00FF00);
        addTexturedTriangles();
        addTilemaps();
        addShaderSnapshotQuads();
        #if novaflare_compact_quad_shader_attributes
        addCompactShaderBatch(48, [1.0], [1.0, 0., 0., 1.], [0., 0., 0., 0.]);
        addCompactShaderBatch(62, [0.5, 1.0], [0., 1., 0., 1., 0., 0., 0., 1.], [0., 0., 0., 0., 0., 0., 1., 0.]);
        #end
        if (Sys.getEnv("NOVAFLARE_TEST_SHADER_HANDOFF") == "1") GL.setMultiThreaded(false);
        transformShape.y = 68;
        redraw(LARGE_QUAD_COUNT);
        redrawTransforms(false);
        stage.window.onRender.add(checkRenderedFrame, false, -100);
        stage.application.onUpdate.add(finish);
    }

    function addShaderSnapshotQuads():Void
    {
        for (index in 0...shaderQuads.length)
        {
            final quad = shaderQuads[index];
            quad.x = 8 + 16 * index;
            quad.y = 86;
            addChild(quad);
        }
        redrawShaderSnapshotQuads(false);
    }

    function redrawShaderSnapshotQuads(reverseColors:Bool):Void
    {
        final shader = new SnapshotGraphicsShader();
        final values = [0.0, 0.0, 0.0, 0.0];
        shader.sampleWeight.value = values;
        shader.sampleBias.value = [0.0];
        shader.bitmap.input = texture;

        for (index in 0...shaderQuads.length)
        {
            final red = (index == 0) != reverseColors;
            for (sample in 0...values.length) values[sample] = red ? 1.0 : 0.0;
            shader.sampleBias.value[0] = red ? 0.0 : 1.0;
            drawShaderQuad(shader, shaderQuads[index].graphics);
        }

        for (index in 0...values.length) values[index] = 0.25;
        shader.sampleBias.value[0] = 0.25;
    }

    function drawShaderQuad(shader:GraphicsShader, graphics:Graphics):Void
    {
        final previousBuffer = @:privateAccess graphics.__usedShaderBuffers[0];
        final previousTicket = requireTicketReuse && previousBuffer != null ? @:privateAccess previousBuffer.shaderParamTicket : null;
        graphics.clear();
        graphics.beginShaderFill(shader);
        final currentBuffer = @:privateAccess graphics.__usedShaderBuffers[0];
        if (previousBuffer != null)
            require(currentBuffer == previousBuffer, "Graphics did not reuse the ShaderBuffer");
        if (requireTicketReuse)
        {
            final currentTicket = @:privateAccess currentBuffer.shaderParamTicket;
            require(currentTicket != null, "ShaderBuffer did not capture shader attributes");
            if (previousBuffer != null)
                require(currentTicket == previousTicket, "ShaderBuffer replaced the native shader parameter ticket");
        }
        graphics.drawQuads(Vector.ofArray([0., 0., 8., 8.]));
        graphics.endFill();
    }

    #if novaflare_compact_quad_shader_attributes
    function addCompactShaderBatch(x:Int, alphas:Array<Float>, multipliers:Array<Float>, offsets:Array<Float>):Void
    {
        final batch = new Sprite();
        batch.x = x;
        batch.y = 86;
        addChild(batch);
        final shader = new CompactQuadGraphicsShader();
        shader.bitmap.input = texture;

        final accepted = batch.graphics.__beginCompactQuadShaderFill(shader, alphas, multipliers, offsets);
        if (requireCompactQuads) require(accepted, "Graphics did not route compact attributes to Lime");
        if (!accepted)
        {
            shader.alpha.value = expandQuadAttributes(alphas, 1);
            shader.colorMultiplier.value = expandQuadAttributes(multipliers, 4);
            shader.colorOffset.value = expandQuadAttributes(offsets, 4);
            batch.graphics.beginShaderFill(shader);
        }

        final rects = new Vector<Float>();
        final translations = new Vector<Float>();
        for (index in 0...alphas.length)
        {
            rects.push(0.);
            rects.push(0.);
            rects.push(8.);
            rects.push(8.);
            translations.push(12. * index);
            translations.push(0.);
        }
        batch.graphics.drawQuads(rects, null, translations);
        batch.graphics.endFill();
        for (values in [alphas, multipliers, offsets])
            for (index in 0...values.length) values[index] = 0;
    }

    static function expandQuadAttributes(values:Array<Float>, components:Int):Array<Float>
    {
        final expanded = new Array<Float>();
        for (tuple in 0...Std.int(values.length / components))
            for (vertex in 0...4)
                for (component in 0...components)
                    expanded.push(values[tuple * components + component]);
        return expanded;
    }
    #end

    function addTexturedTriangles():Void
    {
        final triangles = new Sprite();
        triangles.x = 110;
        triangles.y = 4;
        addChild(triangles);
        final graphics = triangles.graphics;
        graphics.beginBitmapFill(atlas, null, false, false);
        graphics.drawTriangles(Vector.ofArray([0., 0., 32., 0., 0., 32.]), Vector.ofArray([2, 0, 1]),
            Vector.ofArray([0., 0., 2., 1., 0., 0.25, 0., 0., 2.]));
        graphics.drawTriangles(Vector.ofArray([0., 42., 16., 42., 0., 50.]), null,
            Vector.ofArray([0., 0., 1., 0., 0., 1.]));
        graphics.endFill();

        final automaticUV = new Sprite();
        automaticUV.x = 130;
        automaticUV.y = 45;
        addChild(automaticUV);
        automaticUV.graphics.beginBitmapFill(atlas, null, false, false);
        automaticUV.graphics.drawTriangles(Vector.ofArray([0., 0., 16., 0., 0., 8.]));
        automaticUV.graphics.endFill();
    }

    function addTilemaps():Void
    {
        final tileset = new Tileset(atlas, [new Rectangle(0, 0, 8, 8), new Rectangle(8, 0, 8, 8)]);
        final alternate = new Tileset(new BitmapData(8, 8, false, 0xFF0000FF), [new Rectangle(0, 0, 8, 8)]);
        for (layout in 0...4)
        {
            final tilemap = new Tilemap(32, 24, tileset, false);
            tilemap.x = layout * 36;
            tilemap.y = 96;
            tilemap.tileAlphaEnabled = (layout & 1) != 0;
            tilemap.tileColorTransformEnabled = (layout & 2) != 0;
            addChild(tilemap);

            final group = new TileContainer(3, 2);
            final tinted = new Tile(0, 0, 0);
            tinted.alpha = 0.5;
            tinted.colorTransform = new ColorTransform(0.5, 1, 1, 1);
            final hidden = new Tile(1, 10, 0);
            hidden.visible = false;
            final changedAtlas = new Tile(0, 21, 0);
            changedAtlas.tileset = alternate;
            group.addTile(tinted);
            group.addTile(hidden);
            group.addTile(changedAtlas);
            tilemap.addTile(group);
            tileGroups.push(group);
        }
    }

    function redraw(count:Int):Void
    {
        var graphics = shape.graphics;
        graphics.clear();
        graphics.beginBitmapFill(texture);
        final split = count == LARGE_QUAD_COUNT ? count - 1 : count >> 1;
        drawIndexedQuads(graphics, 0, split);
        drawIndexedQuads(graphics, split, count);
        graphics.drawTriangles(Vector.ofArray([68., 5., 80., 5., 68., 17.]), Vector.ofArray([0, 1, 2]),
            Vector.ofArray([0., 0., 1., 0., 0., 1.]));
        graphics.drawTriangles(Vector.ofArray([68., 22., 80., 22., 68., 34.]), Vector.ofArray([0, 1, 2]),
            Vector.ofArray([0., 0., 1., 1., 0., 1., 0., 1., 1.]));
        graphics.endFill();
    }

    function drawIndexedQuads(graphics:Graphics, start:Int, end:Int):Void
    {
        var rects = Vector.ofArray([0., 0., 1., 1.]);
        var indices = new Vector<Int>();
        var transforms = new Vector<Float>();
        for (index in start...end)
        {
            var x = index % QUADS_PER_ROW;
            var y = Std.int(index / QUADS_PER_ROW);
            if (index >= 4096)
            {
                x = index >= 16383 ? 90 + (index - 16383) : 200;
                y = 45;
            }
            indices.push(0);
            transforms.push(1);
            transforms.push(0);
            transforms.push(0);
            transforms.push(1);
            transforms.push(x);
            transforms.push(y);
        }
        graphics.drawQuads(rects, indices, transforms);
    }

    function redrawTransforms(skipFirst:Bool):Void
    {
        final graphics = transformShape.graphics;
        final greenRect = Vector.ofArray([8., 0., 8., 8.]);
        graphics.clear();
        graphics.beginBitmapFill(atlas, null, false, false);
        graphics.drawQuads(greenRect, null, Vector.ofArray([2., 0., 0., 2.]));
        graphics.drawQuads(greenRect, null, Vector.ofArray([30., 2.]));
        graphics.drawQuads(Vector.ofArray([0., 0., 8., 8.]), null, Vector.ofArray([1., 0., 0., 1., 54., 4.]));
        graphics.drawQuads(Vector.ofArray([1., 4., 4., 4.]));
        graphics.drawQuads(greenRect, Vector.ofArray([skipFirst ? -1 : 0, 0]), Vector.ofArray([88., 4., 104., 4.]));
        graphics.drawQuads(Vector.ofArray([8., 0., skipFirst ? 0. : 8., 8.]), null, Vector.ofArray([118., 4.]));
        graphics.endFill();
    }

    function checkRenderedFrame(_:RenderContext):Void
    {
        if (failure != null || checkFrame >= 3) return;

        try
        {
            if (checkFrame == 1) redrawShaderSnapshotQuads(true);
            var window = stage.window;
            require(window.width >= MIN_DRAWABLE_WIDTH && window.height >= MIN_DRAWABLE_SIZE && window.scale == 1,
                "The test requires at least 152 by 128 pixels at scale one");
            var count = checkFrame == 0 ? LARGE_QUAD_COUNT : SMALL_QUAD_COUNT;
            var expectedBytes = BYTES_PER_QUAD * count;
            var actualBytes = readQuadBufferSize();
            require(actualBytes == expectedBytes, 'Quad buffer reported ${actualBytes} bytes, expected ${expectedBytes}');
            expectPixel(2, 1, 255, "retained quad");
            expectPixel(2, 15, checkFrame == 0 ? 255 : 0, "removed quad");
            expectPixel(69, 6, 255, "UV triangle");
            expectPixel(69, 23, 255, "UVT triangle");
            expectPixel(91, 45, checkFrame == 0 ? 255 : 0, "quad after index-buffer split");
            verifyTransforms();
            verifyMeshes();
            expectRGB(11, 89, checkFrame == 2 ? 0x00FF00 : 0xFF0000, "first shader attributes remain frozen");
            expectRGB(27, 89, checkFrame == 2 ? 0xFF0000 : 0x00FF00, "second shader attributes remain frozen");
            #if novaflare_compact_quad_shader_attributes
            expectRGB(51, 89, 0xFF0000, "single quad repeats one RGBA tuple");
            assertRGB(readRGB(65, 89), 0x008000, "alpha multiplies only the first quad", 1);
            expectRGB(77, 89, 0x0000FF, "the second quad uses its own RGBA offset");
            #end
            Sys.println('quads=${count} gpu_bytes=${actualBytes} pixels=verified');
            if (checkFrame == 2)
            {
                @:privateAccess shape.graphics.__quadBuffer.flushVertexBufferData();
                var fullBytes = readQuadBufferSize();
                var capacityBytes = BYTES_PER_QUAD * LARGE_QUAD_COUNT;
                require(fullBytes == capacityBytes, 'Full upload reported ${fullBytes} bytes, expected ${capacityBytes}');
                Sys.println('comparison quads=${count} prefix_bytes=${actualBytes} full_bytes=${fullBytes}');
            }

            checkFrame++;
            if (checkFrame == 1)
            {
                redraw(SMALL_QUAD_COUNT);
                redrawTransforms(true);
                tileGroups[3].visible = false;
            }
        }
        catch (error:haxe.Exception)
        {
            failure = error.message;
        }
    }

    function verifyMeshes():Void
    {
        expectRGB(112, 8, 0xFF0000, "perspective triangle near the first vertex");
        expectRGB(134, 8, 0xFF0000, "perspective texture interpolation with nonuniform T");
        expectRGB(140, 4, 0x00FF00, "perspective triangle near the far vertex");
        expectRGB(112, 48, 0xFF0000, "explicit UV triangle after an UVT triangle");
        expectRGB(142, 46, 0x00FF00, "implicit bitmap UV at the atlas edge");
        for (layout in 0...4)
        {
            final x = layout * 36;
            final visible = layout != 3 || checkFrame == 0;
            final red = !visible ? 0 : layout == 0 ? 255 : layout == 3 ? 64 : 128;
            assertRGB(readRGB(x + 5, 100), red << 16, 'Tilemap $layout color and alpha', 1);
            expectRGB(x + 15, 100, 0, 'Tilemap $layout hidden tile');
            expectRGB(x + 26, 100, visible ? 0x0000FF : 0, 'Tilemap $layout alternate tileset');
        }
    }

    function verifyTransforms():Void
    {
        expectRGB(12, 73, 0x00FF00, "matrix with atlas coordinates");
        expectRGB(44, 82, 0x00FF00, "translation retains the previous draw command matrix");
        expectRGB(57, 75, 0xFF0000, "full transform resets the matrix");
        expectRGB(64, 75, 0, "full transform resets the quad width");
        expectRGB(2, 73, 0xFF0000, "rectangle without a transform");
        expectRGB(89, 74, checkFrame == 0 ? 0x00FF00 : 0, "skipped index clears a reused slot");
        expectRGB(106, 74, 0x00FF00, "slot after a skipped index remains in place");
        expectRGB(121, 74, checkFrame == 0 ? 0x00FF00 : 0, "zero-width rectangle clears a reused slot");
    }

    function readQuadBufferSize():Int
    {
        var context = stage.context3D;
        var quadBuffer = @:privateAccess shape.graphics.__quadBuffer;
        require(quadBuffer != null && quadBuffer.vertexBuffer != null, "Graphics did not create a quad vertex buffer");
        var buffer = @:privateAccess quadBuffer.vertexBuffer.__id;
        if (checkFrame == 0) initialBuffer = buffer;
        else require(buffer == initialBuffer, "Graphics replaced the vertex buffer after the quad count dropped");

        var previousBuffer = @:privateAccess context.__contextState.__currentGLArrayBuffer;
        @:privateAccess context.__bindGLArrayBuffer(buffer);
        var byteLength = GL.getBufferParameteri(GL.ARRAY_BUFFER, GL.BUFFER_SIZE);
        @:privateAccess context.__bindGLArrayBuffer(previousBuffer);
        return byteLength;
    }

    function expectPixel(x:Int, y:Int, expected:Int, label:String):Void
    {
        expectRGB(x, y, expected * 0x010101, label);
    }

    function expectRGB(x:Int, y:Int, expected:Int, label:String):Void
    {
        assertRGB(readRGB(x, y), expected, label, 0);
    }

    function readRGB(x:Int, y:Int):Int
    {
        GL.readPixels(x, stage.window.height - 1 - y, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixel);
        return (pixel.get(0) << 16) | (pixel.get(1) << 8) | pixel.get(2);
    }

    function assertRGB(actual:Int, expected:Int, label:String, tolerance:Int):Void
    {
        for (shift in [0, 8, 16])
        {
            final distance = Math.abs(((actual >> shift) & 255) - ((expected >> shift) & 255));
            require(distance <= tolerance, '${label} was ${StringTools.hex(actual, 6)}, expected ${StringTools.hex(expected, 6)}');
        }
    }

    function finish(_:Float):Void
    {
        if (failure != null)
        {
            Sys.stderr().writeString('FAIL frame=${checkFrame} ${failure}\n');
            System.exit(1);
        }
        else if (checkFrame == 3)
        {
            Sys.println("PASS render geometry");
            System.exit(0);
        }
    }

    static function require(condition:Bool, message:String):Void
    {
        if (!condition) throw new haxe.Exception(message);
    }
}

private class SnapshotGraphicsShader extends GraphicsShader
{
    @:glVertexSource("
        attribute vec4 openfl_Position;
        attribute float sampleWeight;
        uniform mat4 openfl_Matrix;
        varying float sampleWeightV;
        void main(void) {
            sampleWeightV = sampleWeight;
            gl_Position = openfl_Matrix * openfl_Position;
        }
    ")
    @:glFragmentSource("
        varying float sampleWeightV;
        uniform float sampleBias;
        uniform sampler2D bitmap;
        void main(void) {
            gl_FragColor = vec4(sampleWeightV, sampleBias, 0.0, 1.0) * texture2D(bitmap, vec2(0.5));
        }
    ")
    public function new()
    {
        super();
    }
}

#if novaflare_compact_quad_shader_attributes
private class CompactQuadGraphicsShader extends GraphicsShader
{
    @:glVertexSource("
        attribute vec4 openfl_Position;
        attribute float alpha;
        attribute vec4 colorMultiplier;
        attribute vec4 colorOffset;
        uniform mat4 openfl_Matrix;
        varying vec3 batchColor;
        void main(void) {
            batchColor = colorMultiplier.rgb * alpha + colorOffset.rgb;
            gl_Position = openfl_Matrix * openfl_Position;
        }
    ")
    @:glFragmentSource("
        varying vec3 batchColor;
        uniform sampler2D bitmap;
        void main(void) {
            gl_FragColor = vec4(batchColor, 1.0) * texture2D(bitmap, vec2(0.5));
        }
    ")
    public function new()
    {
        super();
    }
}
#end
