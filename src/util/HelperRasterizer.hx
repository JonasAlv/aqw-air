package util;

import flash.display.DisplayObjectContainer;
import flash.display.FrameLabel;
import flash.display.MovieClip;

class HelperRasterizer {
    public static function hasLabel(mc:MovieClip, label:String):Bool {
        if (mc == null || mc.currentLabels == null) return false;
        for (frameLabel in mc.currentLabels) {
            if (frameLabel.name == label) {
                return true;
            }
        }
        return false;
    }

    public static function resetPlayback(container:DisplayObjectContainer):Void {
        if (container == null) return;
        if (Std.isOfType(container, MovieClip)) {
            (cast container : MovieClip).gotoAndPlay(1);
        }

        for (i in 0...container.numChildren) {
            var child = container.getChildAt(i);
            if (Std.isOfType(child, DisplayObjectContainer)) {
                resetPlayback(cast child);
            }
        }
    }

    public static function simulateFrameAdvance(container:DisplayObjectContainer):Void {
        if (container == null) return;
        if (Std.isOfType(container, MovieClip)) {
            var mc:MovieClip = cast container;
            var nextF:Int = mc.currentFrame + 1;
            if (nextF > mc.totalFrames) {
                nextF = 1;
            }
            mc.gotoAndPlay(nextF);
        }

        for (i in 0...container.numChildren) {
            var child = container.getChildAt(i);
            if (Std.isOfType(child, DisplayObjectContainer)) {
                simulateFrameAdvance(cast child);
            }
        }
    }

    public static function getMasterCycle(container:DisplayObjectContainer):Int {
        var counts:Array<Int> = [];
        findCounts(container, counts);

        if (counts.length == 0) {
            return 1;
        }

        var cycle:Int = counts[0];
        for (i in 1...counts.length) {
            cycle = lcm(cycle, counts[i]);
        }
        return cycle;
    }

    private static function findCounts(container:DisplayObjectContainer, list:Array<Int>):Void {
        if (container == null) return;
        if (Std.isOfType(container, MovieClip)) {
            var mc:MovieClip = cast container;
            if (mc.totalFrames > 1 && list.indexOf(mc.totalFrames) == -1) {
                list.push(mc.totalFrames);
            }
        }

        for (i in 0...container.numChildren) {
            var child = container.getChildAt(i);
            if (Std.isOfType(child, DisplayObjectContainer)) {
                findCounts(cast child, list);
            }
        }
    }

    private static function lcm(a:Int, b:Int):Int {
        if (a == 0 || b == 0) return 0;
        return Std.int(Math.abs(a * b) / gcd(a, b));
    }

    private static function gcd(a:Int, b:Int):Int {
        while (b != 0) {
            var temp:Int = b;
            b = a % b;
            a = temp;
        }
        return a;
    }
}
