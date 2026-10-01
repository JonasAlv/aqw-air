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

    private var _limit:Float = 32;
    private var walkController:WalkController;
    private var activeTouchID:Int = -1;

    public function new(walkController:WalkController) {
        super();
        this.walkController = walkController;

        // 1. Programmatic Base graphics
        drawBase();

        // 2. Programmatic Knob graphics
        this.knob = new Sprite();
        drawKnob();
        addChild(this.knob);

        this.mouseChildren = false;
        this.buttonMode = true;
        this.useHandCursor = true;

        addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
    }

    private function drawBase():Void {
        graphics.clear();
        // Outer dark translucent pad
        graphics.beginFill(0x121212, 0.55);
        graphics.lineStyle(2, 0x484848, 0.85);
        graphics.drawCircle(0, 0, 42);
        graphics.endFill();

        // Inner boundary guide ring
        graphics.lineStyle(1, 0x333333, 0.5);
        graphics.drawCircle(0, 0, 32);

        // Directional tick notches
        graphics.lineStyle(2, 0x888888, 0.7);
        graphics.moveTo(0, -40); graphics.lineTo(0, -32);
        graphics.moveTo(0, 32);  graphics.lineTo(0, 40);
        graphics.moveTo(-40, 0); graphics.lineTo(-32, 0);
        graphics.moveTo(32, 0);  graphics.lineTo(40, 0);
    }

    private function drawKnob():Void {
        knob.graphics.clear();
        // Main knob body
        knob.graphics.beginFill(0x282828, 0.92);
        knob.graphics.lineStyle(2, 0xFFCC00, 0.95);
        knob.graphics.drawCircle(0, 0, 20);
        knob.graphics.endFill();

        // Knob inner tactile ring
        knob.graphics.lineStyle(1, 0xFFFFFF, 0.25);
        knob.graphics.drawCircle(0, 0, 14);

        // Knob center dot
        knob.graphics.beginFill(0xFFCC00, 0.7);
        knob.graphics.drawCircle(0, 0, 4);
        knob.graphics.endFill();
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
