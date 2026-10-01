package util;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.MouseEvent;
import ui.util.Scroll;

class HelperScroll {
    private static inline var WHEEL_SPEED:Int = 20;
    private static inline var FRICTION:Float = 0.92;
    private static inline var MIN_VELOCITY:Float = 0.5;
    private static inline var BOTTOM_PADDING:Int = 50;

    private var scroll:Scroll;
    private var list:DisplayObject;
    private var listMask:DisplayObject;

    private var hRun:Int = 0;
    private var dRun:Int = 0;
    private var oy:Float = 0;

    private var mhY:Float = 0;
    private var mbY:Float = 0;
    private var scrollBarDragging:Bool = false;

    private var listDragging:Bool = false;
    private var dragStartY:Float = 0;
    private var dragLastY:Float = 0;
    private var dragPrevY:Float = 0;
    private var velocity:Float = 0;

    public function new(scroll:Scroll, list:DisplayObject, mask:DisplayObject, isResize:Bool = true) {
        this.scroll = scroll;
        this.list = list;
        this.listMask = mask;

        if (this.scroll != null && this.scroll.hit != null) {
            this.scroll.hit.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownScrollHit);
            this.scroll.visible = false;
            this.scroll.hit.alpha = 0;
            if (this.scroll.h != null) this.scroll.h.y = 0;
        }

        if (this.list != null && this.listMask != null) {
            this.oy = this.list.y = this.listMask.y;
            var maskHeight:Float = this.listMask.height;

            if (this.list.height > maskHeight && this.scroll != null && this.scroll.h != null && this.scroll.b != null) {
                if (isResize) {
                    this.scroll.h.height = Std.int((maskHeight / this.list.height) * this.scroll.b.height);
                }

                this.hRun = Std.int(this.scroll.b.height - this.scroll.h.height);
                this.dRun = Std.int((this.list.height - maskHeight) + BOTTOM_PADDING);

                this.scroll.visible = true;

                if (this.scroll.hit != null) {
                    this.scroll.hit.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownScrollHit);
                }

                this.list.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownList);
                this.list.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            }
        }
    }

    public function dispose():Void {
        if (this.scroll != null && this.scroll.hit != null) {
            this.scroll.hit.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownScrollHit);
        }
        if (this.list != null) {
            this.list.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDownList);
            this.list.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
            this.list.removeEventListener(Event.ENTER_FRAME, onMomentum);

            if (this.list.stage != null) {
                this.list.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveList);
                this.list.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpList);
                this.list.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpScrollBar);
                this.list.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveScrollBar);
            }
        }

        listDragging = false;
        scrollBarDragging = false;
        velocity = 0;
    }

    private function clampScrollHandle():Void {
        if (this.scroll == null || this.scroll.h == null || this.scroll.b == null) return;
        if (this.scroll.h.y + this.scroll.h.height > this.scroll.b.height) {
            this.scroll.h.y = Std.int(this.scroll.b.height - this.scroll.h.height);
        }
        if (this.scroll.h.y < 0) {
            this.scroll.h.y = 0;
        }
    }

    private function clampListPosition():Void {
        if (this.list == null) return;
        var minY:Float = this.oy - this.dRun;

        if (this.list.y > this.oy) {
            this.list.y = this.oy;
        }
        if (this.list.y < minY) {
            this.list.y = minY;
        }
    }

    private function syncListFromScrollHandle():Void {
        if (this.scroll == null || this.scroll.h == null || this.list == null || this.hRun == 0) return;
        var hP:Float = this.scroll.h.y / this.hRun;
        this.list.y = this.oy - Std.int(hP * this.dRun);
    }

    private function syncScrollHandleFromList():Void {
        if (this.scroll == null || this.scroll.h == null || this.list == null || this.dRun == 0) return;
        var listP:Float = (this.oy - this.list.y) / this.dRun;
        this.scroll.h.y = Std.int(listP * this.hRun);
        clampScrollHandle();
    }

    private function onMouseDownList(e:MouseEvent):Void {
        if (scrollBarDragging || this.list == null || this.list.stage == null) return;

        listDragging = true;
        dragStartY = e.stageY;
        dragLastY = e.stageY;
        dragPrevY = e.stageY;
        velocity = 0;

        this.list.removeEventListener(Event.ENTER_FRAME, onMomentum);

        this.list.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveList);
        this.list.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpList);
    }

    private function onMouseMoveList(e:MouseEvent):Void {
        if (!listDragging || this.list == null) return;

        var delta:Float = e.stageY - dragLastY;
        velocity = e.stageY - dragPrevY;
        dragPrevY = dragLastY;
        dragLastY = e.stageY;

        this.list.y += delta;
        clampListPosition();
        syncScrollHandleFromList();
    }

    private function onMouseUpList(e:MouseEvent):Void {
        listDragging = false;

        if (this.list != null && this.list.stage != null) {
            this.list.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveList);
            this.list.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpList);
        }

        if (Math.abs(velocity) > MIN_VELOCITY && this.list != null) {
            this.list.addEventListener(Event.ENTER_FRAME, onMomentum);
        }
    }

    private function onMomentum(e:Event):Void {
        if (this.list == null) return;
        velocity *= FRICTION;
        this.list.y += velocity;

        clampListPosition();
        syncScrollHandleFromList();

        if (Math.abs(velocity) < MIN_VELOCITY) {
            this.list.removeEventListener(Event.ENTER_FRAME, onMomentum);
        }
    }

    private function onMouseDownScrollHit(e:MouseEvent):Void {
        if (this.list == null || this.list.stage == null || this.scroll == null || this.scroll.h == null) return;
        scrollBarDragging = true;
        mbY = Std.int(this.list.stage.mouseY);
        mhY = this.scroll.h.y;

        this.list.removeEventListener(Event.ENTER_FRAME, onMomentum);

        this.list.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUpScrollBar);
        this.list.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveScrollBar);
    }

    private function onMouseUpScrollBar(e:MouseEvent):Void {
        scrollBarDragging = false;
        if (this.list != null && this.list.stage != null) {
            this.list.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUpScrollBar);
            this.list.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMoveScrollBar);
        }
    }

    private function onMouseMoveScrollBar(e:MouseEvent):Void {
        if (this.scroll == null || this.scroll.h == null || this.list == null || this.list.stage == null) return;
        this.scroll.h.y = this.mhY + (Std.int(this.list.stage.mouseY) - this.mbY);
        clampScrollHandle();
        syncListFromScrollHandle();
    }

    private function onMouseWheel(e:MouseEvent):Void {
        if (this.list == null || this.scroll == null || this.scroll.h == null || this.dRun == 0) return;
        this.list.removeEventListener(Event.ENTER_FRAME, onMomentum);
        this.scroll.h.y -= Std.int(e.delta * WHEEL_SPEED * this.hRun / this.dRun);
        clampScrollHandle();
        syncListFromScrollHandle();
    }
}
