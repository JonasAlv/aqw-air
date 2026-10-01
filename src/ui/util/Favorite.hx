package ui.util;

import flash.display.MovieClip;
import flash.events.MouseEvent;

class Favorite extends MovieClip {
    private static inline var ALPHA_ACTIVE:Float = 1.0;
    private static inline var ALPHA_INACTIVE:Float = 0.35;

    public var fData:Dynamic;

    public function new() {
        super();
        this.buttonMode = true;
        this.useHandCursor = true;
        this.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
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
        this.alpha = (fData.favorited == true) ? ALPHA_ACTIVE : ALPHA_INACTIVE;
    }

    private function onClick(e:MouseEvent):Void {
        if (fData == null || fData.onToggle == null) return;
        fData.favorited = fData.onToggle();
        refresh();
    }
}
