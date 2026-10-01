package ui.util;

import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

class Handle extends Sprite {
    public var drag:SimpleButton;
    public var up:SimpleButton;
    public var down:SimpleButton;

    public function new() {
        super();

        // 1. Drag button (overlay box / handle)
        this.drag = createButton("MOVE", 0x3377FF, 58, 22);
        this.drag.x = 0;
        this.drag.y = -26;
        addChild(this.drag);

        // 2. Scale Up (+) button
        this.up = createButton("+", 0x28a745, 26, 22);
        this.up.x = 62;
        this.up.y = -26;
        addChild(this.up);

        // 3. Scale Down (-) button
        this.down = createButton("-", 0xdc3545, 26, 22);
        this.down.x = 92;
        this.down.y = -26;
        addChild(this.down);
    }

    private static function createButton(label:String, color:Int, w:Float, h:Float):SimpleButton {
        var upState = makeState(label, color, 0.85, w, h);
        var overState = makeState(label, color, 1.0, w, h);
        var downState = makeState(label, 0x111111, 1.0, w, h);
        var hitState = makeState("", 0, 0, w, h);
        return new SimpleButton(upState, overState, downState, hitState);
    }

    private static function makeState(label:String, color:Int, alpha:Float, w:Float, h:Float):Sprite {
        var sp = new Sprite();
        sp.graphics.beginFill(color, alpha);
        sp.graphics.lineStyle(1.5, 0xFFFFFF, 0.8);
        sp.graphics.drawRoundRect(0, 0, w, h, 4, 4);
        sp.graphics.endFill();

        if (label.length > 0) {
            var txt = new TextField();
            var tf = new TextFormat("_sans", 10, 0xFFFFFF, true);
            tf.align = TextFormatAlign.CENTER;
            txt.defaultTextFormat = tf;
            txt.text = label;
            txt.width = w;
            txt.y = Math.max(1, (h - 16) / 2);
            txt.selectable = false;
            txt.mouseEnabled = false;
            sp.addChild(txt);
        }
        return sp;
    }
}
