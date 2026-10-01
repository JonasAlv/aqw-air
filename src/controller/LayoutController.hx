package controller;

import data.WidgetEntry;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Point;
import flash.ui.Multitouch;
import flash.Vector;
import ui.util.BasicButton;
import ui.util.Handle;
import util.Helper;
import util.HelperSetting;

class LayoutController {
    private static inline var SCALE_STEP:Float = 0.15;
    private static inline var SCALE_MIN:Float = 0.1;
    private static inline var SCALE_MAX:Float = 5.0;
    private static inline var GRID_SIZE:Float = 22.0;

    public static var editMode:Bool = false;
    private static var current:WidgetEntry;

    private var widgets:Array<WidgetEntry> = [];
    private var dragOffsetX:Float = 0;
    private var dragOffsetY:Float = 0;
    private var activeTouchID:Int = -1;
    public var pocket:Dynamic = null;

    public function new() {}

    public function register(id:String, target:Sprite, defaultPositionX:Float, defaultPositionY:Float, defaultScaleX:Float, defaultScaleY:Float):Void {
        this.widgets.push(new WidgetEntry(id, target, defaultPositionX, defaultPositionY, defaultScaleX, defaultScaleY));
    }

    public function unregister(id:String):Void {
        for (i in 0...this.widgets.length) {
            if (this.widgets[i].id == id) {
                hideHandles(this.widgets[i]);
                this.widgets.splice(i, 1);
                return;
            }
        }
    }

    public function load():Void {
        for (widgetEntry in this.widgets) {
            var saved:Dynamic = HelperSetting._get(widgetEntry.id);
            if (saved != null) {
                widgetEntry.target.x = saved.x != null ? saved.x : widgetEntry.defaultPositionX;
                widgetEntry.target.y = saved.y != null ? saved.y : widgetEntry.defaultPositionY;
                widgetEntry.target.scaleX = saved.scaleX != null ? saved.scaleX : widgetEntry.defaultScaleX;
                widgetEntry.target.scaleY = saved.scaleY != null ? saved.scaleY : widgetEntry.defaultScaleY;
            } else {
                widgetEntry.target.x = widgetEntry.defaultPositionX;
                widgetEntry.target.y = widgetEntry.defaultPositionY;
                widgetEntry.target.scaleX = widgetEntry.defaultScaleX;
                widgetEntry.target.scaleY = widgetEntry.defaultScaleY;
            }
        }
    }

    public function toggleEdit(state:Bool):Void {
        editMode = state;
        var pocket:Dynamic = this.pocket;
        if (pocket == null) {
            try {
                var g:Dynamic = untyped __global__["Pocket"];
                if (g != null && g.SINGLETON != null) pocket = g.SINGLETON;
            } catch (e:Dynamic) {}
        }

        if (editMode) {
            if (pocket != null && pocket.gameUI != null && pocket.gameUI.getChildByName("LayoutSaveButton") == null) {
                if (pocket.gameCore != null) {
                    pocket.gameCore.setWorldFilters([Helper.GRAYSCALE]);
                }

                var saveButton = new BasicButton("Save");
                saveButton.name = "LayoutSaveButton";
                saveButton.x = 480 - (saveButton.width / 2);
                saveButton.y = 10;

                var onHide = function(e:Dynamic):Void {
                    if (pocket != null && pocket.gameUI != null) {
                        pocket.gameUI.hideEditLayout();
                    }
                };

                if (Multitouch.supportsTouchEvents) {
                    saveButton.addEventListener(TouchEvent.TOUCH_TAP, onHide, false, 0, true);
                }
                saveButton.addEventListener(MouseEvent.CLICK, onHide, false, 0, true);

                pocket.gameUI.addChild(saveButton);
            }
        } else {
            if (pocket != null && pocket.gameCore != null) {
                pocket.gameCore.setWorldFilters([]);
            }

            if (pocket != null && pocket.gameUI != null) {
                var saveButton2:DisplayObject = pocket.gameUI.getChildByName("LayoutSaveButton");
                if (saveButton2 != null && saveButton2.parent != null) {
                    saveButton2.parent.removeChild(saveButton2);
                }
            }
        }

        for (widgetEntry in this.widgets) {
            if (editMode) {
                showHandles(widgetEntry);
            } else {
                hideHandles(widgetEntry);
                HelperSetting._set(widgetEntry.id, {
                    x: widgetEntry.target.x,
                    y: widgetEntry.target.y,
                    scaleX: widgetEntry.target.scaleX,
                    scaleY: widgetEntry.target.scaleY
                });
            }
        }
    }

    public function resetToDefaults():Void {
        if (editMode) {
            for (e in this.widgets) {
                hideHandles(e);
            }
            editMode = false;
        }

        for (widgetEntry in this.widgets) {
            widgetEntry.target.x = widgetEntry.defaultPositionX;
            widgetEntry.target.y = widgetEntry.defaultPositionY;
            widgetEntry.target.scaleX = widgetEntry.defaultScaleX;
            widgetEntry.target.scaleY = widgetEntry.defaultScaleY;

            HelperSetting._delete(widgetEntry.id);
        }
    }

    private function showHandles(widgetEntry:WidgetEntry):Void {
        if (widgetEntry.handle != null || widgetEntry.target == null || widgetEntry.target.parent == null) {
            return;
        }

        var parent:DisplayObjectContainer = widgetEntry.target.parent;
        var handle = new Handle();
        handle.x = widgetEntry.target.x;
        handle.y = widgetEntry.target.y;

        parent.addChild(handle);

        if (Multitouch.supportsTouchEvents) {
            if (handle.drag != null) handle.drag.addEventListener(TouchEvent.TOUCH_BEGIN, onHandleTouchBegin, false, 0, true);
            if (handle.up != null) handle.up.addEventListener(TouchEvent.TOUCH_TAP, onResizeUp, false, 0, true);
            if (handle.down != null) handle.down.addEventListener(TouchEvent.TOUCH_TAP, onResizeDown, false, 0, true);
        }

        if (handle.drag != null) handle.drag.addEventListener(MouseEvent.MOUSE_DOWN, onHandleMouseDown, false, 0, true);
        if (handle.up != null) handle.up.addEventListener(MouseEvent.CLICK, onResizeUp, false, 0, true);
        if (handle.down != null) handle.down.addEventListener(MouseEvent.CLICK, onResizeDown, false, 0, true);

        widgetEntry.handle = handle;
    }

    private function repositionHandles(widgetEntry:WidgetEntry):Void {
        if (widgetEntry.handle == null) return;
        widgetEntry.handle.x = widgetEntry.target.x;
        widgetEntry.handle.y = widgetEntry.target.y;
    }

    private function hideHandles(widgetEntry:WidgetEntry):Void {
        if (widgetEntry.handle == null) return;

        if (Multitouch.supportsTouchEvents) {
            if (widgetEntry.handle.drag != null) widgetEntry.handle.drag.removeEventListener(TouchEvent.TOUCH_BEGIN, onHandleTouchBegin);
            if (widgetEntry.handle.up != null) widgetEntry.handle.up.removeEventListener(TouchEvent.TOUCH_TAP, onResizeUp);
            if (widgetEntry.handle.down != null) widgetEntry.handle.down.removeEventListener(TouchEvent.TOUCH_TAP, onResizeDown);
        }

        if (widgetEntry.handle.drag != null) widgetEntry.handle.drag.removeEventListener(MouseEvent.MOUSE_DOWN, onHandleMouseDown);
        if (widgetEntry.handle.up != null) widgetEntry.handle.up.removeEventListener(MouseEvent.CLICK, onResizeUp);
        if (widgetEntry.handle.down != null) widgetEntry.handle.down.removeEventListener(MouseEvent.CLICK, onResizeDown);

        if (widgetEntry.handle.parent != null) {
            widgetEntry.handle.parent.removeChild(widgetEntry.handle);
        }

        widgetEntry.handle = null;
    }

    private function entryForHandle(button:SimpleButton):WidgetEntry {
        if (button == null) return null;
        for (widgetEntry in this.widgets) {
            if (widgetEntry.handle != null && (widgetEntry.handle.drag == button || widgetEntry.handle.up == button || widgetEntry.handle.down == button)) {
                return widgetEntry;
            }
        }
        return null;
    }

    private function onHandleTouchBegin(e:TouchEvent):Void {
        if (this.activeTouchID != -1) return;
        current = entryForHandle(cast e.currentTarget);
        if (current == null || current.target == null || current.target.parent == null) return;

        this.activeTouchID = e.touchPointID;
        var parent:DisplayObjectContainer = current.target.parent;
        var pointer:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));

        dragOffsetX = pointer.x - current.target.x;
        dragOffsetY = pointer.y - current.target.y;

        if (current.handle != null) current.handle.visible = false;
        if (current.target.stage != null) {
            current.target.stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 0, true);
            current.target.stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 0, true);
        }
    }

    private function onTouchMove(e:TouchEvent):Void {
        if (current == null || current.target.parent == null || e.touchPointID != this.activeTouchID) return;

        var parent:DisplayObjectContainer = current.target.parent;
        var pointer:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));

        var nextX:Float = pointer.x - dragOffsetX;
        var nextY:Float = pointer.y - dragOffsetY;

        if (isSnapToGridEnabled()) {
            nextX = snap(nextX);
            nextY = snap(nextY);
        }

        current.target.x = nextX;
        current.target.y = nextY;
    }

    private function onTouchEnd(e:TouchEvent):Void {
        if (current == null || e.touchPointID != this.activeTouchID) return;

        if (current.target != null && current.target.stage != null) {
            current.target.stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
            current.target.stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);
        }

        this.activeTouchID = -1;

        if (isSnapToGridEnabled()) {
            current.target.x = snap(current.target.x);
            current.target.y = snap(current.target.y);
        }

        if (current.handle != null) {
            current.handle.visible = true;
            repositionHandles(current);
        }

        current = null;
    }

    private function onHandleMouseDown(e:MouseEvent):Void {
        current = entryForHandle(cast e.currentTarget);
        if (current == null || current.target == null || current.target.parent == null) return;

        var parent:DisplayObjectContainer = current.target.parent;
        var pointer:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));

        dragOffsetX = pointer.x - current.target.x;
        dragOffsetY = pointer.y - current.target.y;

        if (current.handle != null) current.handle.visible = false;
        if (current.target.stage != null) {
            current.target.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
            current.target.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
        }
    }

    private function onMouseMove(e:MouseEvent):Void {
        if (current == null || current.target.parent == null) return;

        var parent:DisplayObjectContainer = current.target.parent;
        var pointer:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));

        var nextX:Float = pointer.x - dragOffsetX;
        var nextY:Float = pointer.y - dragOffsetY;

        if (isSnapToGridEnabled()) {
            nextX = snap(nextX);
            nextY = snap(nextY);
        }

        current.target.x = nextX;
        current.target.y = nextY;
    }

    private function onMouseUp(e:MouseEvent):Void {
        if (current == null) return;

        if (current.target != null && current.target.stage != null) {
            current.target.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            current.target.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        }

        if (isSnapToGridEnabled()) {
            current.target.x = snap(current.target.x);
            current.target.y = snap(current.target.y);
        }

        if (current.handle != null) {
            current.handle.visible = true;
            repositionHandles(current);
        }

        current = null;
    }

    private function onResizeUp(e:Dynamic):Void {
        var entry:WidgetEntry = entryForHandle(cast e.currentTarget);
        if (entry == null) return;

        var scale:Float = Math.min(SCALE_MAX, entry.target.scaleX + SCALE_STEP);
        entry.target.scaleX = scale;
        entry.target.scaleY = scale;
        repositionHandles(entry);
    }

    private function onResizeDown(e:Dynamic):Void {
        var entry:WidgetEntry = entryForHandle(cast e.currentTarget);
        if (entry == null) return;

        var scale:Float = Math.max(SCALE_MIN, entry.target.scaleX - SCALE_STEP);
        entry.target.scaleX = scale;
        entry.target.scaleY = scale;
        repositionHandles(entry);
    }

    private function isSnapToGridEnabled():Bool {
        return HelperSetting.getBool(HelperSetting.OPTION_SNAP_TO_GRID, true);
    }

    private function snap(value:Float):Float {
        return Math.round(value / GRID_SIZE) * GRID_SIZE;
    }
}
