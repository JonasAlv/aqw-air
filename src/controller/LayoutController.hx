package controller;

import data.WidgetEntry;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import util.Helper;
import util.HelperSetting;

class LayoutController {
    public static var editMode:Bool = false;

    private var widgets:Array<WidgetEntry> = [];
    public var pocket:Dynamic = null;
    private var toolbar:Sprite = null;
    private var selectedWidgetId:String;

    public function new() {}

    public function register(id:String, target:Sprite, defaultPositionX:Float, defaultPositionY:Float, defaultScaleX:Float, defaultScaleY:Float):Void {
        for (w in widgets) {
            if (w.id == id) {
                w.target = target;
                w.defaultPositionX = defaultPositionX;
                w.defaultPositionY = defaultPositionY;
                w.defaultScaleX = defaultScaleX;
                w.defaultScaleY = defaultScaleY;
                return;
            }
        }
        widgets.push(new WidgetEntry(id, target, defaultPositionX, defaultPositionY, defaultScaleX, defaultScaleY));
    }

    public function unregister(id:String):Void {
        for (i in 0...widgets.length) {
            if (widgets[i].id == id) {
                widgets.splice(i, 1);
                return;
            }
        }
    }

    public function load():Void {
        for (w in widgets) {
            loadWidget(w.id);
        }
    }

    public function loadWidget(id:String):Void {
        for (w in widgets) {
            if (w.id != id || w.target == null) continue;
            var saved:Dynamic = HelperSetting._get(w.id);
            w.target.x = (saved != null && saved.x != null) ? saved.x : w.defaultPositionX;
            w.target.y = (saved != null && saved.y != null) ? saved.y : w.defaultPositionY;
            w.target.scaleX = (saved != null && saved.scaleX != null) ? saved.scaleX : w.defaultScaleX;
            w.target.scaleY = (saved != null && saved.scaleY != null) ? saved.scaleY : w.defaultScaleY;
            return;
        }
    }

    public function updatePosition(id:String, x:Float, y:Float):Void {
        for (w in widgets) {
            if (w.id == id) {
                HelperSetting._set(id, {
                    x: x,
                    y: y,
                    scaleX: (w.target != null ? w.target.scaleX : 1.0),
                    scaleY: (w.target != null ? w.target.scaleY : 1.0)
                });
                return;
            }
        }
    }

    public function toggleEdit(state:Bool):Void {
        editMode = state;
        if (editMode) selectedWidgetId = null;
        var p = getPocketInstance();

        // 1. Notify all widgets of edit mode state
        for (w in widgets) {
            if (w.target == null) continue;
            if (Std.isOfType(w.target, ui.shortcut.ShortcutButton)) {
                cast(w.target, ui.shortcut.ShortcutButton).setEditMode(editMode);
            } else if (Std.isOfType(w.target, ui.input.Joystick)) {
                cast(w.target, ui.input.Joystick).setEditMode(editMode);
            }
        }
        if (p != null && p.gameUI != null) p.gameUI.setSkillBarLayoutEditMode(editMode);

        if (editMode) {
            if (p != null && p.gameCore != null) {
                p.gameCore.setWorldFilters([Helper.GRAYSCALE]);
            }
            showToolbar();
            attachWheelScaleListener();
            ui.api.ApiNotificationManager.notify("Layout editor: select a control, drag to move, and use Size +/- or the mouse wheel to resize.");
        } else {
            if (p != null && p.gameCore != null) {
                p.gameCore.setWorldFilters([]);
            }
            hideToolbar();
            removeWheelScaleListener();
            saveAll();
        }
    }

    private function showToolbar():Void {
        hideToolbar();
        var p = getPocketInstance();
        if (p == null || p.gameUI == null) return;

        var stageW:Float = (p.game != null && p.game.stage != null) ? p.game.stage.stageWidth : 960;
        var barW:Float = 462;
        var barH:Float = 42;

        toolbar = new Sprite();
        toolbar.name = "LayoutEditToolbar";
        toolbar.graphics.beginFill(0x181818, 0.95);
        toolbar.graphics.lineStyle(2, 0xFFCC00, 1.0);
        toolbar.graphics.drawRoundRect(0, 0, barW, barH, 20, 20);
        toolbar.graphics.endFill();

        toolbar.x = (stageW - barW) / 2;
        toolbar.y = 12;

        // Button 1: Save (Green)
        var saveBtn = makeToolbarButton("Save Layout", 0x28A745, 120, 28);
        saveBtn.x = 10;
        saveBtn.y = 7;
        saveBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            toggleEdit(false);
            ui.api.ApiNotificationManager.notify("Controls layout saved!");
        });
        saveBtn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            toggleEdit(false);
            ui.api.ApiNotificationManager.notify("Controls layout saved!");
        });
        toolbar.addChild(saveBtn);

        // Button 2: Reset (Dark Grey)
        var resetBtn = makeToolbarButton("Reset", 0x333333, 70, 28);
        resetBtn.x = 138;
        resetBtn.y = 7;
        resetBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            resetToDefaults();
            ui.api.ApiNotificationManager.notify("Layout reset to defaults!");
        });
        resetBtn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            resetToDefaults();
            ui.api.ApiNotificationManager.notify("Layout reset to defaults!");
        });
        toolbar.addChild(resetBtn);

        var sizeDownBtn = makeToolbarButton("Size -", 0x333333, 70, 28);
        sizeDownBtn.x = 216;
        sizeDownBtn.y = 7;
        sizeDownBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            adjustSelectedScale(-0.1);
        });
        sizeDownBtn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            adjustSelectedScale(-0.1);
        });
        toolbar.addChild(sizeDownBtn);

        var sizeUpBtn = makeToolbarButton("Size +", 0x333333, 70, 28);
        sizeUpBtn.x = 294;
        sizeUpBtn.y = 7;
        sizeUpBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            adjustSelectedScale(0.1);
        });
        sizeUpBtn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            adjustSelectedScale(0.1);
        });
        toolbar.addChild(sizeUpBtn);

        // Button 5: Close (Red)
        var closeBtn = makeToolbarButton("Exit", 0xDC3545, 70, 28);
        closeBtn.x = 372;
        closeBtn.y = 7;
        closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            toggleEdit(false);
        });
        closeBtn.addEventListener(TouchEvent.TOUCH_TAP, function(e:TouchEvent):Void {
            toggleEdit(false);
        });
        toolbar.addChild(closeBtn);

        p.gameUI.addChild(toolbar);
    }

    private function hideToolbar():Void {
        if (toolbar != null && toolbar.parent != null) {
            toolbar.parent.removeChild(toolbar);
            toolbar = null;
        }
    }

    private function makeToolbarButton(label:String, bgColor:Int, w:Float, h:Float):Sprite {
        var sp = new Sprite();
        sp.buttonMode = true;
        sp.useHandCursor = true;
        sp.mouseChildren = false;

        var drawState = function(fill:Int, border:Int):Void {
            sp.graphics.clear();
            sp.graphics.beginFill(fill, 0.95);
            sp.graphics.lineStyle(1.5, border, 0.9);
            sp.graphics.drawRoundRect(0, 0, w, h, 14, 14);
            sp.graphics.endFill();
        };

        drawState(bgColor, 0x666666);

        var txt = new TextField();
        var tf = new TextFormat("_sans", 11, 0xFFFFFF, true);
        tf.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = tf;
        txt.text = label;
        txt.width = w;
        txt.y = 5;
        txt.selectable = false;
        txt.mouseEnabled = false;
        sp.addChild(txt);

        sp.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):Void {
            drawState(bgColor + 0x1A1A1A, 0xFFCC00);
        });
        sp.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):Void {
            drawState(bgColor, 0x666666);
        });

        return sp;
    }

    private function attachWheelScaleListener():Void {
        var p = getPocketInstance();
        if (p != null && p.game != null && p.game.stage != null) {
            p.game.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelScale, false, 0, true);
        }
    }

    private function removeWheelScaleListener():Void {
        var p = getPocketInstance();
        if (p != null && p.game != null && p.game.stage != null) {
            p.game.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheelScale);
        }
    }

    private function onMouseWheelScale(e:MouseEvent):Void {
        if (!editMode) return;
        for (w in widgets) {
            if (w.target == null) continue;
            if (w.target.hitTestPoint(e.stageX, e.stageY, true)) {
                selectedWidgetId = w.id;
                adjustSelectedScale((e.delta > 0) ? 0.1 : -0.1);
                break;
            }
        }
    }

    public function selectWidget(id:String):Void {
        if (!editMode) return;
        for (w in widgets) {
            if (w.id == id && w.target != null) {
                selectedWidgetId = id;
                if (Std.isOfType(w.target, ui.shortcut.ShortcutButton)) {
                    cast(w.target, ui.shortcut.ShortcutButton).setSelected(true);
                } else if (Std.isOfType(w.target, ui.input.Joystick)) {
                    cast(w.target, ui.input.Joystick).setSelected(true);
                }
                for (other in widgets) {
                    if (other.id == id || other.target == null) continue;
                    if (Std.isOfType(other.target, ui.shortcut.ShortcutButton)) {
                        cast(other.target, ui.shortcut.ShortcutButton).setSelected(false);
                    } else if (Std.isOfType(other.target, ui.input.Joystick)) {
                        cast(other.target, ui.input.Joystick).setSelected(false);
                    }
                }
                return;
            }
        }
    }

    private function adjustSelectedScale(delta:Float):Void {
        if (!editMode || selectedWidgetId == null) {
            ui.api.ApiNotificationManager.notify("Select a control first.");
            return;
        }
        for (w in widgets) {
            if (w.id != selectedWidgetId || w.target == null) continue;
            var nextScale:Float = Math.max(0.5, Math.min(2.5, w.target.scaleX + delta));
            w.target.scaleX = nextScale;
            w.target.scaleY = nextScale;
            updatePosition(w.id, w.target.x, w.target.y);
            if (StringTools.startsWith(w.id, HelperSetting.LAYOUT_SKILL_BAR + "_i")) {
                var p = getPocketInstance();
                if (p != null && p.gameUI != null) p.gameUI.applySkillBarStyle();
            }
            return;
        }
        selectedWidgetId = null;
    }

    public function saveAll():Void {
        for (w in widgets) {
            if (w.target == null) continue;
            HelperSetting._set(w.id, {
                x: w.target.x,
                y: w.target.y,
                scaleX: w.target.scaleX,
                scaleY: w.target.scaleY
            });
        }
    }

    public function resetToDefaults():Void {
        for (w in widgets) {
            if (w.target == null) continue;
            w.target.x = w.defaultPositionX;
            w.target.y = w.defaultPositionY;
            w.target.scaleX = w.defaultScaleX;
            w.target.scaleY = w.defaultScaleY;
            HelperSetting._set(w.id, null);
        }
        var p = getPocketInstance();
        if (p != null && p.gameUI != null) p.gameUI.applySkillBarStyle();
        selectedWidgetId = null;
    }

    private function getPocketInstance():Dynamic {
        if (this.pocket != null) return this.pocket;
        try {
            var g:Dynamic = untyped __global__["Pocket"];
            if (g != null && g.SINGLETON != null) return g.SINGLETON;
        } catch (_:Dynamic) {}
        return null;
    }
}
