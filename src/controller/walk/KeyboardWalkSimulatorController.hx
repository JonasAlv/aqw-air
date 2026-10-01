package controller.walk;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

/**
 * Virtual Keyboard / Arrow Keys Walk Simulator Controller.
 * Dispatches simulated direction arrow keys directly to stage and game client.
 */
class KeyboardWalkSimulatorController extends WalkController {
    private var _lastKeyCode:Int = 0;

    public function new(pocket:Dynamic) {
        super(pocket);
    }

    override public function update():Void {
        if (this.pocket == null || this.pocket.gameUI == null || this.pocket.gameUI.joystickKeyboardSimulator == null) {
            return;
        }

        var joystick = this.pocket.gameUI.joystickKeyboardSimulator;
        var dirX:Float = joystick.dirX;
        var dirY:Float = joystick.dirY;

        if (dirX == 0 && dirY == 0) {
            _releaseKey();
            return;
        }

        var angle:Float = Math.atan2(dirY, dirX);
        var PI4:Float = Math.PI / 4;

        var keyCode:Int;

        if (angle >= -PI4 && angle < PI4) {
            keyCode = Keyboard.RIGHT;
        } else if (angle >= PI4 && angle < PI4 * 3) {
            keyCode = Keyboard.DOWN;
        } else if (angle >= -PI4 * 3 && angle < -PI4) {
            keyCode = Keyboard.UP;
        } else {
            keyCode = Keyboard.LEFT;
        }

        if (keyCode != this._lastKeyCode) {
            _releaseKey();
            _pressKey(keyCode);
        }
    }

    override public function stop():Void {
        _releaseKey();
    }

    private function _pressKey(keyCode:Int):Void {
        var targets = get_targets();
        if (targets.length == 0) return;

        this._lastKeyCode = keyCode;
        var evt = _makeEvent(KeyboardEvent.KEY_DOWN, keyCode);
        for (target in targets) {
            try { target.dispatchEvent(evt); } catch (_:Dynamic) {}
        }
    }

    private function _releaseKey():Void {
        if (this._lastKeyCode == 0) return;

        var targets = get_targets();
        if (targets.length == 0) return;

        var evt = _makeEvent(KeyboardEvent.KEY_UP, this._lastKeyCode);
        for (target in targets) {
            try { target.dispatchEvent(evt); } catch (_:Dynamic) {}
        }
        this._lastKeyCode = 0;
    }

    private function get_targets():Array<DisplayObject> {
        var targets:Array<DisplayObject> = [];
        if (this.pocket == null) return targets;

        if (this.pocket.game != null) {
            try {
                var ext:MovieClip = cast this.pocket.game.mcExtSWF;
                if (ext != null && ext.numChildren > 0) {
                    var ch = ext.getChildAt(0);
                    if (ch != null) targets.push(ch);
                }
            } catch (_:Dynamic) {}

            targets.push(this.pocket.game);
            if (this.pocket.game.stage != null) {
                targets.push(this.pocket.game.stage);
            }
        } else if (this.pocket.stage != null) {
            targets.push(this.pocket.stage);
        }

        return targets;
    }

    private function _makeEvent(ttype:String, keyCode:Int):KeyboardEvent {
        return new KeyboardEvent(ttype, true, false, 0, keyCode);
    }
}
