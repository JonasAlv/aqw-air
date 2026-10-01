package ui.util;

import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.text.TextField;

class Pagination extends MovieClip {
    private static inline var DISABLED_ALPHA:Float = 0.4;

    public var tPage:TextField;
    public var btnPrev:SimpleButton;
    public var btnNext:SimpleButton;

    public var fData:Dynamic;
    public var sel:Dynamic;

    public function new() {
        super();
    }

    public function fOpen(fData:Dynamic):Void {
        this.fData = fData;
        refresh();
    }

    public function update(fData:Dynamic):Void {
        this.fData = fData;
        refresh();
    }

    private function refresh():Void {
        if (fData == null) return;

        if (tPage != null) {
            tPage.text = "Page " + fData.page + " of " + fData.totalPages;
        }

        setButtonState(btnPrev, fData.canPrev == true);
        setButtonState(btnNext, fData.canNext == true);
    }

    private function setButtonState(btn:SimpleButton, enabled:Bool):Void {
        if (btn == null) return;
        btn.mouseEnabled = enabled;
        btn.alpha = enabled ? 1.0 : DISABLED_ALPHA;
    }

    public function fClose():Void {
        fData = null;
        if (parent != null) {
            parent.removeChild(this);
        }
    }
}
