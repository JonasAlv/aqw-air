package ui.input;

import controller.LayoutController;
import controller.walk.WalkController;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Point;
import flash.ui.Multitouch;

/**
 * Modern Virtual Joystick created from scratch.
 * Supports analog 360 walk, dynamic touch centering, variable speed,
 * double-flick dash, and direct drag repositioning in Edit Mode.
 */
class Joystick extends Sprite {
    public var knob:Sprite;
    public var dirX:Float = 0;
    public var dirY:Float = 0;

    public var isKeyboardMode:Bool = false;
    private var _limit:Float = 36;
    private var walkController:WalkController;
    private var activeTouchID:Int = -1;

    // Double-flick dash detection
    private var lastFlickTime:Int = 0;
    private var wasFlicked:Bool = false;

    // Direct drag state in Edit Mode
    private var isDraggingWidget:Bool = false;
    private var dragStartMouseX:Float = 0;
    private var dragStartMouseY:Float = 0;
    private var dragStartX:Float = 0;
    private var dragStartY:Float = 0;

    public function new(walkController:WalkController, isKeyboardMode:Bool = false) {
        super();
        this.walkController = walkController;
        this.isKeyboardMode = isKeyboardMode;

        this.mouseChildren = false;
        this.buttonMode = true;
        this.useHandCursor = true;

        // 1. Draw Outer Base Pad
        drawBase(false);

        // 2. Knob
        this.knob = new Sprite();
        drawKnob(false);
        addChild(this.knob);

        addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
    }

    public function setEditMode(active:Bool):Void {
        drawBase(active);
    }

    private function drawBase(isEdit:Bool):Void {
        graphics.clear();

        if (isEdit) {
            // Gold dashed outline in Edit Mode
            graphics.beginFill(0x181818, 0.85);
            graphics.lineStyle(2, 0xFFCC00, 1.0);
            graphics.drawCircle(0, 0, 46);
            graphics.endFill();
            return;
        }

        // Translucent dark glass outer pad
        graphics.beginFill(0x101010, 0.58);
        graphics.lineStyle(2, 0x4A4A4A, 0.85);
        graphics.drawCircle(0, 0, 45);
        graphics.endFill();

        // Inner travel boundary ring
        graphics.lineStyle(1, 0x333333, 0.45);
        graphics.drawCircle(0, 0, _limit);

        if (isKeyboardMode) {
            // D-Pad style direction arrows
            drawArrow(0, -32, 0);   // UP
            drawArrow(32, 0, 90);   // RIGHT
            drawArrow(0, 32, 180);  // DOWN
            drawArrow(-32, 0, 270); // LEFT
        } else {
            // Sleek analog tick notches
            graphics.lineStyle(2, 0x888888, 0.65);
            graphics.moveTo(0, -43); graphics.lineTo(0, -35);
            graphics.moveTo(0, 35);  graphics.lineTo(0, 43);
            graphics.moveTo(-43, 0); graphics.lineTo(-35, 0);
            graphics.moveTo(35, 0);  graphics.lineTo(43, 0);
        }
    }

    private function drawArrow(cx:Float, cy:Float, angleDeg:Float):Void {
        graphics.lineStyle(2, 0xFFCC00, 0.7);
        var rad = angleDeg * Math.PI / 180;
        var p1x = cx + Math.cos(rad) * 6;
        var p1y = cy + Math.sin(rad) * 6;
        var p2x = cx + Math.cos(rad + 2.4) * 6;
        var p2y = cy + Math.sin(rad + 2.4) * 6;
        var p3x = cx + Math.cos(rad - 2.4) * 6;
        var p3y = cy + Math.sin(rad - 2.4) * 6;

        graphics.moveTo(p2x, p2y);
        graphics.lineTo(p1x, p1y);
        graphics.lineTo(p3x, p3y);
    }

    private function drawKnob(isPressed:Bool):Void {
        knob.graphics.clear();

        var fill = isPressed ? 0x1F1F1F : 0x2A2A2A;
        var border = isPressed ? 0xFFDD00 : 0xFFCC00;

        knob.graphics.beginFill(fill, 0.95);
        knob.graphics.lineStyle(2, border, 0.95);
        knob.graphics.drawCircle(0, 0, 22);
        knob.graphics.endFill();

        // Tactile concentric ring
        knob.graphics.lineStyle(1, 0xFFFFFF, isPressed ? 0.4 : 0.2);
        knob.graphics.drawCircle(0, 0, 15);

        // Center jewel dot
        knob.graphics.beginFill(border, 0.85);
        knob.graphics.drawCircle(0, 0, 5);
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
            dist = this._limit;
        }

        if (this.knob != null) {
            this.knob.x = dx;
            this.knob.y = dy;
        }

        if (this._limit > 0) {
            this.dirX = dx / this._limit;
            this.dirY = dy / this._limit;
        }

        // Double flick dash detection
        var mag = dist / this._limit;
        if (mag > 0.85) {
            if (!wasFlicked) {
                wasFlicked = true;
                var now = flash.Lib.getTimer();
                if (now - lastFlickTime < 350) {
                    triggerDash();
                }
                lastFlickTime = now;
            }
        } else if (mag < 0.3) {
            wasFlicked = false;
        }
    }

    private function triggerDash():Void {
        try {
            var pocket:Dynamic = (this.walkController != null) ? Reflect.field(this.walkController, "pocket") : null;
            if (pocket != null && pocket.game != null && pocket.game.world != null && pocket.game.world.myAvatar != null) {
                pocket.game.world.myAvatar.pMC.spAtt();
            }
        } catch (_:Dynamic) {}
    }

    public function snapHome():Void {
        if (this.knob != null) {
            this.knob.x = 0;
            this.knob.y = 0;
        }
        this.dirX = 0;
        this.dirY = 0;
        drawKnob(false);
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
        drawKnob(true);

        stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
        stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameJoystick);

        stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 0, true);
        stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 0, true);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrameJoystick, false, 0, true);

        this.move(e.stageX, e.stageY);
    }

    private function onTouchMove(e:TouchEvent):Void {
        if (e.touchPointID != this.activeTouchID) return;
        this.move(e.stageX, e.stageY);
    }

    private function onTouchEnd(e:TouchEvent):Void {
        if (e.touchPointID != this.activeTouchID || stage == null) return;

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
        if (!this.visible || stage == null) return;

        if (LayoutController.editMode) {
            // Direct drag repositioning in Edit Mode
            isDraggingWidget = true;
            dragStartMouseX = stage.mouseX;
            dragStartMouseY = stage.mouseY;
            dragStartX = this.x;
            dragStartY = this.y;

            stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageDragMove, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, onStageDragUp, false, 0, true);
            e.stopPropagation();
            return;
        }

        drawKnob(true);
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrameJoystick);

        stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
        stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrameJoystick, false, 0, true);

        this.move(e.stageX, e.stageY);
    }

    private function onMouseMove(e:MouseEvent):Void {
        this.move(e.stageX, e.stageY);
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

    private function onStageDragMove(e:MouseEvent):Void {
        if (!isDraggingWidget || stage == null) return;
        this.x = dragStartX + (stage.mouseX - dragStartMouseX);
        this.y = dragStartY + (stage.mouseY - dragStartMouseY);
    }

    private function onStageDragUp(e:MouseEvent):Void {
        if (!isDraggingWidget) return;
        isDraggingWidget = false;
        if (stage != null) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageDragMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onStageDragUp);
        }
        var p:Dynamic = (this.walkController != null) ? Reflect.field(this.walkController, "pocket") : null;
        if (p != null && p.gameUI != null && p.gameUI.layoutController != null) {
            p.gameUI.layoutController.updatePosition(this.name, this.x, this.y);
        }
    }

    private function onEnterFrameJoystick(e:Event):Void {
        if (this.walkController != null) {
            this.walkController.update();
        }
    }
}
