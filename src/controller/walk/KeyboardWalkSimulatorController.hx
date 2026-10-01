package controller.walk;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

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
        var target:DisplayObject = get_target();
        if (target == null) return;

        this._lastKeyCode = keyCode;
        target.dispatchEvent(_makeEvent(KeyboardEvent.KEY_DOWN, keyCode));
    }

    private function _releaseKey():Void {
        if (this._lastKeyCode == 0) return;

        var target:DisplayObject = get_target();
        if (target == null) return;

        target.dispatchEvent(_makeEvent(KeyboardEvent.KEY_UP, this._lastKeyCode));
        this._lastKeyCode = 0;
    }

    private function get_target():DisplayObject {
        if (this.pocket == null || this.pocket.game == null) return null;
        var ext:MovieClip = cast this.pocket.game.mcExtSWF;
        if (ext == null || ext.numChildren == 0) return null;

        try {
            return ext.getChildAt(0);
        } catch (e:Dynamic) {
            return null;
        }
    }

    private function _makeEvent(ttype:String, keyCode:Int):KeyboardEvent {
        return new KeyboardEvent(ttype, true, false, 0, keyCode);
    }
}
