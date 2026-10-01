package ui;

import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;

@:keep
class Notification extends Sprite {
    public var messageTxt:TextField;
    public var closeBtn:SimpleButton;

    public function new(message:String) {
        super();
        if (this.messageTxt != null) {
            this.messageTxt.htmlText = message;
        }

        if (this.closeBtn != null) {
            this.closeBtn.addEventListener(MouseEvent.CLICK, onClose, false, 0, true);
        }
    }

    private function onClose(e:MouseEvent):Void {
        if (this.parent != null) {
            this.parent.removeChild(this);
        }
    }
}
