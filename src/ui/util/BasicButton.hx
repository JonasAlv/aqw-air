package ui.util;

import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

class BasicButton extends Sprite {
    public var button:SimpleButton;
    public var buttonTxt:TextField;

    public function new(buttonLabel:String) {
        super();

        var btnW:Float = 100;
        var btnH:Float = 32;

        graphics.beginFill(0x28a745, 0.95);
        graphics.lineStyle(2, 0x48c765, 1.0);
        graphics.drawRoundRect(0, 0, btnW, btnH, 6, 6);
        graphics.endFill();

        var txt = new TextField();
        var tf = new TextFormat("_sans", 12, 0xFFFFFF, true);
        tf.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = tf;
        txt.text = buttonLabel;
        txt.width = btnW;
        txt.y = 6;
        txt.selectable = false;
        txt.mouseEnabled = false;
        addChild(txt);
        this.buttonTxt = txt;

        this.buttonMode = true;
        this.useHandCursor = true;
        this.mouseChildren = false;

        addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):Void {
            graphics.clear();
            graphics.beginFill(0x34c759, 1.0);
            graphics.lineStyle(2, 0x5de87f, 1.0);
            graphics.drawRoundRect(0, 0, btnW, btnH, 6, 6);
            graphics.endFill();
        });

        addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):Void {
            graphics.clear();
            graphics.beginFill(0x28a745, 0.95);
            graphics.lineStyle(2, 0x48c765, 1.0);
            graphics.drawRoundRect(0, 0, btnW, btnH, 6, 6);
            graphics.endFill();
        });
    }
}
