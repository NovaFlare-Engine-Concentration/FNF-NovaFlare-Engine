import haxe.io.Bytes;
import lime.graphics.RenderContext;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.system.System;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite
{
    static inline var MIN_DRAWABLE_SIZE = 96;
    static inline var QUADS_PER_ROW = 64;
    static inline var LARGE_QUAD_COUNT = 4096;
    static inline var SMALL_QUAD_COUNT = 128;
    static inline var BYTES_PER_QUAD = 64;

    final shape = new Sprite();
    final texture = new BitmapData(1, 1, false, 0xFFFFFFFF);
    final pixel = Bytes.alloc(4);
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
        addChild(shape);
        redraw(LARGE_QUAD_COUNT);
        stage.window.onRender.add(checkRenderedFrame, false, -100);
        stage.application.onUpdate.add(finish);
    }

    function redraw(count:Int):Void
    {
        var graphics = shape.graphics;
        graphics.clear();
        graphics.beginBitmapFill(texture);
        drawIndexedQuads(graphics, 0, count >> 1);
        drawIndexedQuads(graphics, count >> 1, count);
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
            indices.push(0);
            transforms.push(1);
            transforms.push(0);
            transforms.push(0);
            transforms.push(1);
            transforms.push(index % QUADS_PER_ROW);
            transforms.push(Std.int(index / QUADS_PER_ROW));
        }
        graphics.drawQuads(rects, indices, transforms);
    }

    function checkRenderedFrame(_:RenderContext):Void
    {
        if (failure != null || checkFrame >= 2) return;

        try
        {
            var window = stage.window;
            require(window.width >= MIN_DRAWABLE_SIZE && window.height >= MIN_DRAWABLE_SIZE && window.scale == 1,
                "The test requires at least 96 pixels on each axis at scale one");
            var count = checkFrame == 0 ? LARGE_QUAD_COUNT : SMALL_QUAD_COUNT;
            var expectedBytes = BYTES_PER_QUAD * count;
            var actualBytes = readQuadBufferSize();
            require(actualBytes == expectedBytes, 'Quad buffer reported ${actualBytes} bytes, expected ${expectedBytes}');
            expectPixel(2, 1, 255, "retained quad");
            expectPixel(2, 15, checkFrame == 0 ? 255 : 0, "removed quad");
            expectPixel(69, 6, 255, "UV triangle");
            expectPixel(69, 23, 255, "UVT triangle");
            Sys.println('quads=${count} gpu_bytes=${actualBytes} pixels=verified');
            if (checkFrame == 1)
            {
                @:privateAccess shape.graphics.__quadBuffer.flushVertexBufferData();
                var fullBytes = readQuadBufferSize();
                var capacityBytes = BYTES_PER_QUAD * LARGE_QUAD_COUNT;
                require(fullBytes == capacityBytes, 'Full upload reported ${fullBytes} bytes, expected ${capacityBytes}');
                Sys.println('comparison quads=${count} prefix_bytes=${actualBytes} full_bytes=${fullBytes}');
            }

            checkFrame++;
            if (checkFrame == 1) redraw(SMALL_QUAD_COUNT);
        }
        catch (error:haxe.Exception)
        {
            failure = error.message;
        }
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
        GL.readPixels(x, stage.window.height - 1 - y, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixel);
        for (channel in 0...3)
        {
            var actual = pixel.get(channel);
            require(actual == expected, '${label} channel ${channel} was ${actual}, expected ${expected}');
        }
    }

    function finish(_:Float):Void
    {
        if (failure != null)
        {
            Sys.stderr().writeString('FAIL frame=${checkFrame} ${failure}\n');
            System.exit(1);
        }
        else if (checkFrame == 2)
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
