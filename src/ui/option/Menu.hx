package ui.option;

import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.Vector;

class Menu extends Sprite {
    public var button:SimpleButton;
    public var buttonTxt:TextField;
    public var options:Vector<Option>;

    public function new(buttonLabel:String, options:Vector<Option>) {
        super();
        this.options = options;

        if (this.buttonTxt != null) {
            this.buttonTxt.text = buttonLabel;
            this.buttonTxt.mouseEnabled = false;
        }

        if (this.button != null) {
            this.button.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
        }
    }

    private function onClick(e:MouseEvent):Void {
        var pocket:Dynamic = untyped __global__["Pocket"].SINGLETON;
        if (pocket != null && pocket.overlay != null) {
            pocket.overlay.selectMenu(this);
        }
    }
}
