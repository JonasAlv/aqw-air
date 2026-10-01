package ui.option;

import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.text.TextField;

class Button extends Option {
    public var button:SimpleButton;
    public var buttonTxt:TextField;

    public function new(
        key:String,
        name:String,
        info:String,
        buttonLabel:String,
        ?onChange:Dynamic->Void,
        ?onFrameChange:Dynamic->Void,
        ?onOverlayStateChange:Dynamic->Void
    ) {
        super(key, name, info, true, onChange, onFrameChange, onOverlayStateChange);

        if (this.buttonTxt != null) {
            this.buttonTxt.text = buttonLabel;
            this.buttonTxt.mouseEnabled = false;
        }

        if (this.button != null) {
            this.button.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
        }
    }

    private function onClick(e:MouseEvent):Void {
        if (onChange != null) {
            onChange(this);
        }
    }
}
