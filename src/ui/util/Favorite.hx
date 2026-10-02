package ui.util;

import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.ui.Multitouch;

class Favorite extends MovieClip {
    private static inline var ALPHA_ACTIVE:Float = 1.0;
    private static inline var ALPHA_INACTIVE:Float = 0.35;

    public var fData:Dynamic;

    public function new() {
        super();
        this.buttonMode = true;
        this.useHandCursor = true;
        if (Multitouch.supportsTouchEvents) {
            this.addEventListener(TouchEvent.TOUCH_TAP, onClick, false, 0, true);
        } else {
            this.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
        }
        this.mouseChildren = false;
        this.drawStar(false);
    }

    public function fOpen(fData:Dynamic):Void {
        this.fData = fData;
        refresh();
    }

    public function update(fData:Dynamic):Void {
        this.fData = fData;
        refresh();
    }

    public function fClose():Void {
        this.fData = null;
        if (this.parent != null) {
            this.parent.removeChild(this);
        }
    }

    private function refresh():Void {
        if (fData == null) return;
        var active:Bool = fData.favorited == true;
        this.alpha = active ? ALPHA_ACTIVE : ALPHA_INACTIVE;
        drawStar(active);
    }

    private function onClick(e:Dynamic):Void {
        if (fData == null || fData.onToggle == null) return;
        fData.favorited = fData.onToggle();
        refresh();
    }

    private function drawStar(active:Bool):Void {
        graphics.clear();
        graphics.beginFill(0x111111, 0.94);
        graphics.lineStyle(1.5, active ? 0xE7C94A : 0x555555, 1);
        graphics.drawRoundRect(0, 0, 32, 32, 6, 6);
        graphics.endFill();

        var outerRadius:Float = 10;
        var innerRadius:Float = 4.5;
        var color:Int = active ? 0xFFD84D : 0xF2F2F2;
        graphics.beginFill(color, 1);
        graphics.lineStyle(0, color, 1);
        for (point in 0...10) {
            var radius = (point % 2 == 0) ? outerRadius : innerRadius;
            var angle = -Math.PI / 2 + point * Math.PI / 5;
            var x = 16 + Math.cos(angle) * radius;
            var y = 16 + Math.sin(angle) * radius;
            if (point == 0) graphics.moveTo(x, y) else graphics.lineTo(x, y);
        }
        graphics.lineTo(16 + Math.cos(-Math.PI / 2) * outerRadius, 16 - outerRadius);
        graphics.endFill();
    }
}
