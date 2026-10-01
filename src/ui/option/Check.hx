package ui.option;

import flash.display.Sprite;
import flash.events.MouseEvent;
import util.HelperSetting;

class Check extends Option {
    public var state:Bool;
    public var checkMark:Sprite;
    public var checkBackground:Sprite;

    public function new(
        key:String,
        defaultValue:Bool,
        name:String,
        info:String,
        visible:Bool = true,
        ?onChange:Dynamic->Void,
        ?onFrameChange:Dynamic->Void,
        ?onOverlayStateChange:Dynamic->Void
    ) {
        super(key, name, info, visible, onChange, onFrameChange, onOverlayStateChange);

        this.state = this.key != null ? HelperSetting.getBool(this.key, defaultValue) : defaultValue;

        syncState();

        if (this.checkMark != null) {
            this.checkMark.mouseEnabled = false;
        }

        if (this.checkBackground != null) {
            this.checkBackground.addEventListener(MouseEvent.CLICK, onToggle, false, 0, true);
        }
    }

    public function syncState():Void {
        if (this.checkMark != null) {
            this.checkMark.visible = this.state;
        }
    }

    public function onToggle(?e:MouseEvent):Void {
        this.state = !this.state;

        if (this.key != null) {
            HelperSetting.setBool(this.key, this.state);
        }

        if (this.onChange != null) {
            this.onChange(this);
        }

        syncState();
    }
}
