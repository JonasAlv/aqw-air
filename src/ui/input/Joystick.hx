package ui.input;

import controller.LayoutController;
import controller.walk.WalkController;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Point;
import flash.ui.Multitouch;

class Joystick extends Sprite {
    public var knob:Sprite;
    public var dirX:Float = 0;
    public var dirY:Float = 0;

    private var _limit:Float = 40;
    private var walkController:WalkController;
    private var activeTouchID:Int = -1;

    public function new(walkController:WalkController) {
        super();
        this.walkController = walkController;
        addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
    }

    public function move(stageX:Float, stageY:Float):Void {
        var local:Point = globalToLocal(new Point(stageX, stageY));
        var dx:Float = local.x;
        var dy:Float = local.y;
        var dist:Float = Math.sqrt(dx * dx + dy * dy);

        if (this._limit > 0 && dist > this._limit) {
            dx = dx / dist * this._limit;
            dy = dy / dist * this._limit;
        }

        if (this.knob != null) {
            this.knob.x = dx;
            this.knob.y = dy;
        }

        if (this._limit > 0) {
            this.dirX = dx / this._limit;
            this.dirY = dy / this._limit;
        }
    }

    public function snapHome():Void {
        if (this.knob != null) {
            this.knob.x = 0;
            this.knob.y = 0;
        }
        this.dirX = 0;
        this.dirY = 0;
    }

    private function onAdded(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);

        if (Multitouch.supportsTouchEvents) {
            addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin, false, 0, true);
        }
        addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);

        var knobW:Float = (this.knob != null && this.knob.width > 0) ? this.knob.width : 30;
        var totalW:Float = (this.width > 0) ? this.width : 100;
        this._limit = (totalW / 2) - (knobW / 2) * 0.4;
    }

    private function onTouchBegin(e:TouchEvent):Void {
        if (!this.visible || LayoutController.editMode || this.activeTouchID != -1 || stage == null) {
            return;
        }

        this.activeTouchID = e.touchPointID;

        stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
        stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameJoystick);

        stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 0, true);
        stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 0, true);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrameJoystick, false, 0, true);

        this.move(e.stageX, e.stageY);
    }

    private function onTouchMove(e:TouchEvent):Void {
        if (e.touchPointID != this.activeTouchID) {
            return;
        }

        if (this.dirX != 0 || this.dirY != 0) {
            this.move(e.stageX, e.stageY);
        }
    }

    private function onTouchEnd(e:TouchEvent):Void {
        if (e.touchPointID != this.activeTouchID || stage == null) {
            return;
        }

        stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
        stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameJoystick);

        this.activeTouchID = -1;

        if (this.dirX == 0 && this.dirY == 0) {
            return;
        }

        this.snapHome();
        if (this.walkController != null) {
            this.walkController.stop();
        }
    }

    private function onMouseDown(e:MouseEvent):Void {
        if (!this.visible || LayoutController.editMode || stage == null) {
            return;
        }

        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameJoystick);

        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrameJoystick, false, 0, true);

        this.move(e.stageX, e.stageY);
    }

    private function onMouseMove(e:MouseEvent):Void {
        if (this.dirX != 0 || this.dirY != 0) {
            this.move(e.stageX, e.stageY);
        }
    }

    private function onMouseUp(e:MouseEvent):Void {
        if (stage != null) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameJoystick);
        }

        if (this.dirX == 0 && this.dirY == 0) {
            return;
        }

        this.snapHome();
        if (this.walkController != null) {
            this.walkController.stop();
        }
    }

    private function onEnterFrameJoystick(e:Event):Void {
        if (this.walkController != null) {
            this.walkController.update();
        }
    }
}
