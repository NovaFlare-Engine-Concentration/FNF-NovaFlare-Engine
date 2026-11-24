import haxe.Timer;
import lime.app.Application;
import lime.graphics.RenderContext;
import lime.graphics.opengl.GL;
import lime.system.System;
import lime.ui.WindowVSyncMode;

private typedef CadenceCase =
{
    final name:String;
    final updateRate:Int;
    final drawRate:Int;
    final split:Bool;
    final vsync:WindowVSyncMode;
}

class Main extends Application
{
    static inline var MEASUREMENT_SECONDS = 2.0;

    final cases:Array<CadenceCase> = [
        {name: "splitSlowDraw", updateRate: 90, drawRate: 30, split: true, vsync: OFF},
        {name: "coupled", updateRate: 90, drawRate: 30, split: false, vsync: OFF},
        {name: "splitFastDraw", updateRate: 30, drawRate: 120, split: true, vsync: OFF},
        {name: "vsyncOn", updateRate: 120, drawRate: 120, split: true, vsync: ON},
        {name: "vsyncOff", updateRate: 120, drawRate: 120, split: true, vsync: OFF}
    ];

    var caseIndex = -1;
    var begunAt:Float;
    var updates = 0;
    var draws = 0;
    var recoveryStep = 0;
    var recoveryStartedAt:Float;
    var firstLateUpdateAt:Float;

    override public function update(deltaTime:Float):Void
    {
        try
        {
            if (caseIndex < 0)
            {
                GL.setMultiThreaded(true);
                require(GL.getString(GL.RENDERER) != null, "OpenGL renderer unavailable");
                beginCase(0);
                return;
            }

            if (caseIndex == cases.length)
            {
                checkUpdateRecovery();
                return;
            }

            final elapsed = Timer.stamp() - begunAt;
            if (elapsed < 0) return;
            if (elapsed < MEASUREMENT_SECONDS)
            {
                updates++;
                return;
            }

            checkCase(cases[caseIndex], elapsed);
            if (caseIndex + 1 < cases.length)
            {
                beginCase(caseIndex + 1);
                return;
            }

            beginUpdateRecovery();
        }
        catch (error:haxe.Exception)
        {
            Sys.stderr().writeString('FAIL ${error.message}\n');
            System.exit(1);
        }
    }

    override public function render(context:RenderContext):Void
    {
        if (caseIndex < 0 || caseIndex == cases.length) return;
        if (Timer.stamp() >= begunAt) draws++;
        GL.clearColor(0.15, 0.25, 0.45, 1);
        GL.clear(GL.COLOR_BUFFER_BIT);
    }

    function beginCase(index:Int):Void
    {
        final cadence = cases[index];
        require(window.setVSyncMode(cadence.vsync), '${cadence.name} could not set VSync');
        window.lockRender = cadence.split;
        window.frameRate = cadence.updateRate;
        window.drawFrameRate = cadence.drawRate;
        caseIndex = index;
        updates = 0;
        draws = 0;
        // Time the steady interval after the first swap warms up the driver.
        begunAt = Timer.stamp() + (index == 0 ? 1.25 : 0.25);
    }

    function checkCase(cadence:CadenceCase, elapsed:Float):Void
    {
        final measuredUpdates = updates / elapsed;
        final measuredDraws = draws / elapsed;
        final expectedDraws = cadence.split ? cadence.drawRate : cadence.updateRate;
        Sys.println('case=${cadence.name} seconds=${elapsed} updates=${updates} draws=${draws}');
        require(nearRate(measuredUpdates, cadence.updateRate), '${cadence.name} update rate was ${measuredUpdates}');
        if (cadence.vsync == ON)
        {
            require(measuredDraws > 0 && measuredDraws <= expectedDraws * 1.2, '${cadence.name} draw rate was ${measuredDraws}');
            return;
        }

        require(nearRate(measuredDraws, expectedDraws), '${cadence.name} draw rate was ${measuredDraws}');
    }

    function beginUpdateRecovery():Void
    {
        caseIndex = cases.length;
        window.frameRate = 20;
        window.drawFrameRate = 1;
    }

    function checkUpdateRecovery():Void
    {
        switch (recoveryStep++)
        {
            case 0:
                window.frameRate = 20;
                recoveryStartedAt = Timer.stamp();
                // Cross two 50 ms deadlines while leaving time before the third.
                while (Timer.stamp() - recoveryStartedAt < 0.125) {}
            case 1:
                firstLateUpdateAt = Timer.stamp();
                final stall = firstLateUpdateAt - recoveryStartedAt;
                require(stall >= 0.125 && stall < 0.150, 'Update recovery stall lasted ${stall} seconds');
            case 2:
                final recoveryGap = Timer.stamp() - firstLateUpdateAt;
                require(recoveryGap < 0.025, 'Missed update took ${recoveryGap} seconds to recover');
                Sys.println('case=updateRecovery gap_seconds=${recoveryGap}');
                Sys.println("PASS render cadence");
                System.exit(0);
        }
    }

    static inline function nearRate(measured:Float, requested:Int):Bool
    {
        return measured >= requested * 0.8 && measured <= requested * 1.2;
    }

    static function require(condition:Bool, message:String):Void
    {
        if (!condition) throw new haxe.Exception(message);
    }
}
