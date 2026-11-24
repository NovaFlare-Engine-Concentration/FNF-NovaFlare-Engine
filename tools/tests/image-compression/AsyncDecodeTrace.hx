#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#else
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
                        if (encoded != null) AsyncDecodeTrace.record(hasScaledDecodeScope());
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
    static var observations:Array<{scoped:Bool, worker:Bool}> = [];
    static var recording = false;

    public static function start():Void
    {
        mutex.acquire();
        mainThread = Thread.current();
        recording = true;
        mutex.release();
    }

    public static function record(scoped:Bool):Void
    {
        mutex.acquire();
        if (recording) observations.push({scoped: scoped, worker: Thread.current() != mainThread});
        mutex.release();
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
