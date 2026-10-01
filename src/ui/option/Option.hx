package ui.option;

import flash.display.Sprite;
import flash.text.TextField;

class Option extends Sprite {
    public var nameTxt:TextField;
    public var infoTxt:TextField;

    public var key:String;
    public var onChange:Dynamic->Void;
    public var onFrameChange:Dynamic->Void;
    public var onOverlayStateChange:Dynamic->Void;

    public function new(
        key:String,
        name:String,
        info:String,
        visible:Bool = true,
        ?onChange:Dynamic->Void,
        ?onFrameChange:Dynamic->Void,
        ?onOverlayStateChange:Dynamic->Void
    ) {
        super();
        this.visible = visible;
        this.key = key;
        this.onChange = onChange;
        this.onFrameChange = onFrameChange;
        this.onOverlayStateChange = onOverlayStateChange;

        if (name != null && this.nameTxt != null) {
            this.nameTxt.text = name;
        }

        if (info != null && this.infoTxt != null) {
            this.infoTxt.htmlText = info;
        }
    }
}
