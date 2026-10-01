package controller;

#if flash
import flash.display.MovieClip;
import flash.display.Stage;
import flash.events.Event;
import flash.geom.Rectangle;
import util.HelperSetting;

class ViewportController {
    public static var instance(get, never):ViewportController;
    private static var _instance:ViewportController;
    private static function get_instance():ViewportController {
        if (_instance == null) _instance = new ViewportController();
        return _instance;
    }

    private var _pocket:Dynamic;
    private var _stage:Stage;
    private var _isAttached:Bool = false;

    public function new() {}

    public function init(pocket:Dynamic):Void {
        _pocket = pocket;
        if (_pocket != null && _pocket.stage != null) {
            _stage = _pocket.stage;
            if (!_isAttached) {
                _stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
                _isAttached = true;
            }
        }
        apply();
    }

    private function onStageResize(e:Event):Void {
        apply();
    }

    public function apply():Void {
        if (_pocket == null) {
            try {
                var p = pocket.PocketRoot.SINGLETON;
                if (p != null) _pocket = p;
            } catch (_:Dynamic) {}
        }
        if (_pocket == null) return;

        var game:MovieClip = cast _pocket.game;
        if (game == null) return;

        var stg:Stage = (_stage != null) ? _stage : (game.stage != null ? game.stage : null);
        if (stg == null) return;

        var mode:String = HelperSetting.getString(HelperSetting.OPTION_RENDER_RESOLUTION, "native");
        var letterbox:Bool = HelperSetting.getBool(HelperSetting.OPTION_RESOLUTION_LETTERBOX, true);

        var targetW:Float = 0;
        var targetH:Float = 0;

        switch (mode) {
            case "720p":
                targetW = 1280;
                targetH = 720;
            case "900p":
                targetW = 1600;
                targetH = 900;
            case "550p":
                targetW = 960;
                targetH = 550;
            default: // "native"
                targetW = 0;
                targetH = 0;
        }

        var winW:Float = (stg.stageWidth > 0) ? stg.stageWidth : 960;
        var winH:Float = (stg.stageHeight > 0) ? stg.stageHeight : 550;

        if (targetW <= 0 || targetH <= 0) {
            // Native Window Resolution (Dynamic Unlocked)
            game.scaleX = 1.0;
            game.scaleY = 1.0;
            game.x = 0;
            game.y = 0;
            game.scrollRect = null;
            return;
        }

        // Fixed Resolution with Viewport Hardware Scaling
        var scaleX:Float;
        var scaleY:Float;
        var offsetX:Float = 0;
        var offsetY:Float = 0;

        if (letterbox) {
            var scale:Float = Math.min(winW / targetW, winH / targetH);
            scaleX = scale;
            scaleY = scale;
            offsetX = (winW - (targetW * scale)) / 2;
            offsetY = (winH - (targetH * scale)) / 2;
        } else {
            scaleX = winW / targetW;
            scaleY = winH / targetH;
            offsetX = 0;
            offsetY = 0;
        }

        game.x = Math.max(0, offsetX);
        game.y = Math.max(0, offsetY);
        game.scaleX = scaleX;
        game.scaleY = scaleY;
        game.scrollRect = new Rectangle(0, 0, targetW, targetH);
    }
}
#else
class ViewportController {
    public static var instance(get, never):ViewportController;
    private static var _instance:ViewportController;
    private static function get_instance():ViewportController {
        if (_instance == null) _instance = new ViewportController();
        return _instance;
    }
    public function new() {}
    public function init(pocket:Dynamic):Void {}
    public function apply():Void {}
}
#end
