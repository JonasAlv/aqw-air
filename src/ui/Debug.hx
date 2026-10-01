package ui;

import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;

@:keep
class Debug extends Sprite {
    public var logTxt:TextField;
    public var closeBtn:SimpleButton;

    public function new() {
        super();
        this.x = 30;
        this.y = 330;

        #if flash
        haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos):Void {
            try {
                untyped __global__["trace"](v);
            } catch (e:Dynamic) {}
        };
        #end

        if (this.closeBtn != null) {
            this.closeBtn.addEventListener(MouseEvent.CLICK, onClose, false, 0, true);
        }
    }

    private function onClose(e:MouseEvent):Void {
        if (this.parent != null && this.parent.contains(this)) {
            this.parent.removeChild(this);
        }
    }

    public function log(msg:String):Void {
        var timestamp:String = Date.now().toString().substr(11, 8);
        var entry:String = "[" + timestamp + "] [Loader] " + msg;
        #if flash
        try {
            untyped __global__["trace"](entry);
        } catch (e:Dynamic) {}
        #end
        try {
            com.aqwapi.utils.ApiLogger.info("Loader", msg);
        } catch (e:Dynamic) {}

        if (this.logTxt != null) {
            this.logTxt.appendText(entry + "\n");
            this.logTxt.scrollV = this.logTxt.maxScrollV;
        }
    }

    public function logError(msg:String):Void {
        var timestamp:String = Date.now().toString().substr(11, 8);
        var entry:String = "[" + timestamp + "] [Loader:ERROR] " + msg;
        #if flash
        try {
            untyped __global__["trace"](entry);
        } catch (e:Dynamic) {}
        #end
        try {
            com.aqwapi.utils.ApiLogger.error("Loader", msg);
        } catch (e:Dynamic) {}

        if (this.logTxt != null) {
            this.logTxt.appendText(entry + "\n");
            this.logTxt.scrollV = this.logTxt.maxScrollV;
        }
    }
}
