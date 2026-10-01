package ui.option;

import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.text.TextField;
import util.HelperSetting;

class Toggle extends Option {
    public var stateTxt:TextField;
    public var buttonLeft:SimpleButton;
    public var buttonRight:SimpleButton;

    private var toggleLabels:Array<String>;
    private var index:Int = 0;

    public function new(
        key:String,
        defaultValue:Int,
        label:String,
        info:String,
        visible:Bool = true,
        ?toggleLabels:Array<String>,
        ?onChange:Dynamic->Void,
        ?onFrameChange:Dynamic->Void,
        ?onOverlayStateChange:Dynamic->Void
    ) {
        super(key, label, info, visible, onChange, onFrameChange, onOverlayStateChange);

        this.toggleLabels = toggleLabels != null ? toggleLabels : [];
        this.index = this.key != null ? HelperSetting.getInt(this.key, defaultValue) : defaultValue;

        syncState();

        if (this.buttonLeft != null) {
            this.buttonLeft.addEventListener(MouseEvent.CLICK, onLeft, false, 0, true);
        }
        if (this.buttonRight != null) {
            this.buttonRight.addEventListener(MouseEvent.CLICK, onRight, false, 0, true);
        }
    }

    public function getIndex():Int {
        return index;
    }

    public function setIndex(i:Int):Void {
        if (this.toggleLabels != null && this.toggleLabels.length > 0) {
            this.index = i % this.toggleLabels.length;
        } else {
            this.index = i;
        }
        syncState();
    }

    private function syncState():Void {
        if (this.stateTxt != null && this.toggleLabels != null && this.index >= 0 && this.index < this.toggleLabels.length) {
            this.stateTxt.text = this.toggleLabels[this.index];
        }
    }

    private function onLeft(e:MouseEvent):Void {
        if (this.toggleLabels == null || this.toggleLabels.length == 0) return;
        this.index = (this.index - 1 + this.toggleLabels.length) % this.toggleLabels.length;

        if (this.key != null) {
            HelperSetting.setInt(this.key, this.index);
        }

        syncState();

        if (onChange != null) {
            onChange(this);
        }
    }

    private function onRight(e:MouseEvent):Void {
        if (this.toggleLabels == null || this.toggleLabels.length == 0) return;
        this.index = (this.index + 1) % this.toggleLabels.length;

        if (this.key != null) {
            HelperSetting.setInt(this.key, this.index);
        }

        syncState();

        if (onChange != null) {
            onChange(this);
        }
    }
}
