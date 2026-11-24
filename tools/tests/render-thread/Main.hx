import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.RenderContext;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLTexture;
import lime.system.System;
import lime.ui.WindowVSyncMode;
import lime.utils.UInt8Array;

@:cppFileCode("#include <chrono>")
class Main extends Application
{
    static inline var WIDTH = 257;
    static inline var HEIGHT = 193;
    static inline var DATA_OFFSET = 13;
    static inline var BYTE_COUNT = WIDTH * HEIGHT * 4;
    static inline var ROUNDS = 5;

    var frame = 0;
    var failure:Null<String>;
    var texture:GLTexture;
    var framebuffer:GLFramebuffer;

    override public function render(context:RenderContext):Void
    {
        if (failure != null || frame >= ROUNDS * 3) return;

        try
        {
            if (frame == 0)
            {
                require(window.setVSyncMode(WindowVSyncMode.OFF), "Could not disable VSync on the render thread");
                var renderer = GL.getString(GL.RENDERER);
                require(renderer != null && renderer.length != 0, "OpenGL renderer is unavailable");
                Sys.println('renderer=${renderer}');
                createTargets();
            }

            var mode = frame % 3;
            GL.setMultiThreaded(mode != 0);
            if (frame == 3)
            {
                require(window.setVSyncMode(WindowVSyncMode.ON), "Could not enable VSync on the application thread");
            }
            require(GL.getString(GL.VERSION) != null, "OpenGL query failed after switching mode");
            checkTextureUpload(mode);
            drawWindow(mode);
            frame++;
        }
        catch (error:haxe.Exception)
        {
            failure = error.message;
        }
    }

    override public function update(deltaTime:Float):Void
    {
        if (failure != null)
        {
            Sys.stderr().writeString('FAIL frame=${frame} ${failure}\n');
            System.exit(1);
        }
        else if (frame >= ROUNDS * 3)
        {
            // Wait for the previous frame's queued swap before asking Lime to close the window.
            if (GL.getError() != GL.NO_ERROR)
            {
                Sys.stderr().writeString("FAIL OpenGL error after the final frame\n");
                System.exit(1);
                return;
            }

            Sys.println('PASS frames=${frame}');
            System.exit(0);
        }
    }

    function createTargets():Void
    {
        texture = GL.createTexture();
        framebuffer = GL.createFramebuffer();
        require(texture != null && framebuffer != null, "Could not create OpenGL test targets");
        GL.bindTexture(GL.TEXTURE_2D, texture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
    }

    function checkTextureUpload(mode:Int):Void
    {
        var source = Bytes.alloc(DATA_OFFSET + BYTE_COUNT + 5);
        var data = UInt8Array.fromBytes(source, DATA_OFFSET, BYTE_COUNT);
        for (index in 0...BYTE_COUNT) data[index] = pixelByte(index);
        var image = new Image(new ImageBuffer(data, WIDTH, HEIGHT));

        GL.bindTexture(GL.TEXTURE_2D, texture);
        if (mode == 0)
        {
            var queued = NativeCFFI.tryQueuePackedTextureImage2D(image, GL.RGBA, GL.RGBA);
            require(!queued, "Worker upload unexpectedly succeeded in direct mode");
        }
        else if (mode == 2)
        {
            // The packed upload must work with an odd row width and restore the caller's alignment.
            GL.pixelStorei(GL.UNPACK_ALIGNMENT, 8);
        }

        var started = steadyMicros();
        if (mode == 2)
        {
            var queued = NativeCFFI.tryQueuePackedTextureImage2D(image, GL.RGBA, GL.RGBA);
            var elapsed = elapsedMicros(started);
            // Mutate before any following GL call can submit the recorded upload.
            source.fill(DATA_OFFSET, BYTE_COUNT, 0xE2);
            require(queued, "Packed upload was rejected in worker mode");
            require(GL.getParameter(GL.UNPACK_ALIGNMENT) == 8, "Packed upload changed unpack alignment");
            GL.pixelStorei(GL.UNPACK_ALIGNMENT, 4);
            Sys.println('frame=${frame} mode=worker-queued submit_us=${elapsed}');
        }
        else
        {
            GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, WIDTH, HEIGHT, 0, GL.RGBA, GL.UNSIGNED_BYTE, data);
            var elapsed = elapsedMicros(started);
            source.fill(DATA_OFFSET, BYTE_COUNT, 0xE2);
            var label = mode == 0 ? "direct" : "worker-sync";
            Sys.println('frame=${frame} mode=${label} submit_us=${elapsed}');
        }

        GL.bindFramebuffer(GL.FRAMEBUFFER, framebuffer);
        GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
        require(GL.checkFramebufferStatus(GL.FRAMEBUFFER) == GL.FRAMEBUFFER_COMPLETE, "Upload framebuffer is incomplete");

        var readback = Bytes.alloc(BYTE_COUNT);
        GL.readPixels(0, 0, WIDTH, HEIGHT, GL.RGBA, GL.UNSIGNED_BYTE, readback);
        for (index in 0...BYTE_COUNT)
        {
            var expected = pixelByte(index);
            var actual = readback.get(index);
            if (actual != expected) throw new haxe.Exception('Pixel byte ${index} was ${actual}, expected ${expected}');
        }
        require(GL.getError() == GL.NO_ERROR, "OpenGL upload or readback reported an error");
    }

    function drawWindow(mode:Int):Void
    {
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        GL.clearColor(mode == 0 ? 1.0 : 0.0, mode == 1 ? 1.0 : 0.0, mode == 2 ? 1.0 : 0.0, 1.0);
        GL.clear(GL.COLOR_BUFFER_BIT);

        var pixel = Bytes.alloc(4);
        GL.readPixels(0, 0, 1, 1, GL.RGBA, GL.UNSIGNED_BYTE, pixel);
        for (channel in 0...3)
        {
            var expected = channel == mode ? 255 : 0;
            require(pixel.get(channel) == expected, "The window did not render with the selected context owner");
        }
    }

    inline function pixelByte(index:Int):Int
    {
        return (index * 13 + frame * 29) & 0xFF;
    }

    static inline function steadyMicros():Float
    {
        return untyped __cpp__("std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now().time_since_epoch()).count()");
    }

    static inline function elapsedMicros(started:Float):Int
    {
        return Math.round(steadyMicros() - started);
    }

    static function require(condition:Bool, message:String):Void
    {
        if (!condition) throw new haxe.Exception(message);
    }
}
