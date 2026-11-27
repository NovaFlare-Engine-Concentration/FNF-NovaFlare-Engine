#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#else
import haxe.io.Bytes;
import sys.thread.Mutex;
import sys.thread.Thread;
#end

class AsyncDecodeTrace
{
    #if macro
    public static function instrument():Array<Field>
    {
        var fields = Context.getBuildFields();
        for (field in fields)
        {
            if (field.name != "decodeScaled") continue;
            switch (field.kind)
            {
                case FFun(decoder):
                    decoder.expr = macro
                    {
                        if (encoded != null) AsyncDecodeTrace.record(hasScaledDecodeScope(), encoded);
                        $e{decoder.expr};
                    };
                    return fields;
                default:
            }
        }
        return Context.error("Missing scaled decode entry point", Context.currentPos());
    }
    #else
    static final mutex = new Mutex();
    static var mainThread:Thread;
    static var fixturePath:String;
    static var fixtureImages:Array<Bytes>;
    static var observations:Array<{scoped:Bool, worker:Bool}> = [];
    static var recording = false;

    public static function start(path:String, images:Array<Bytes>):Void
    {
        mutex.acquire();
        mainThread = Thread.current();
        fixturePath = path;
        fixtureImages = images;
        recording = true;
        mutex.release();
    }

    public static function record(scoped:Bool, encoded:Dynamic):Void
    {
        mutex.acquire();
        if (recording && isFixture(encoded)) observations.push({scoped: scoped, worker: Thread.current() != mainThread});
        mutex.release();
    }

    static function isFixture(encoded:Dynamic):Bool
    {
        if (encoded is String) return encoded == fixturePath;
        var bytes:Bytes = cast encoded;
        return Lambda.exists(fixtureImages, image -> isSameImage(image, bytes));
    }

    static function isSameImage(expected:Bytes, actual:Bytes):Bool
    {
        if (expected.length != actual.length) return false;
        for (index in 0...expected.length)
            if (expected.get(index) != actual.get(index)) return false;
        return true;
    }

    public static function check(description:String, scoped:Bool, worker:Null<Bool>):Void
    {
        mutex.acquire();
        var recorded = observations;
        observations = [];
        mutex.release();
        if (recorded.length == 0)
            throw new haxe.Exception('$description never reached the image decoder.');
        for (entry in recorded)
            if (entry.scoped != scoped || (worker != null && entry.worker != worker))
                throw new haxe.Exception('$description expected scope=$scoped, worker=$worker, got scope=${entry.scoped}, worker=${entry.worker}.');
    }

    public static function checkCache():Void
    {
        mutex.acquire();
        var empty = observations.length == 0;
        mutex.release();
        if (!empty) throw new haxe.Exception("The OpenFL bitmap cache decoded the asset again.");
    }

    public static function stop():Void
    {
        mutex.acquire();
        recording = false;
        mutex.release();
    }
    #end
}
