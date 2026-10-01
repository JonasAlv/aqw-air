package ui.util;

import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.text.TextField;

class BasicButton extends Sprite {
    public var button:SimpleButton;
    public var buttonTxt:TextField;

    public function new(buttonLabel:String) {
        super();
        if (this.buttonTxt != null) {
            this.buttonTxt.text = buttonLabel;
            this.buttonTxt.mouseEnabled = false;
        }
    }
}
