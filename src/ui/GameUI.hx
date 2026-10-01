package ui;

import controller.LayoutController;
import controller.walk.KeyboardWalkSimulatorController;
import controller.walk.MouseWalkSimulatorController;
import controller.walk.WalkController;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import ui.input.Joystick;
import ui.shortcut.ShortcutButton;
import util.Helper;
import util.HelperSetting;

/**
 * Modern Touch Controls and Quick Action Shortcuts Layer.
 * Manages virtual joysticks, quick shortcuts, layout persistence,
 * and direct drag-and-drop editor from scratch.
 */
class GameUI extends Sprite {
    public var pocket:Dynamic;

    public var joystickMouseSimulator:Joystick = null;
    public var joystickKeyboardSimulator:Joystick = null;

    public var layoutController:LayoutController = new LayoutController();
    public var shortcutButtons:Dynamic = {};

    public function new(pocket:Dynamic) {
        super();
        this.pocket = pocket;
        this.layoutController.pocket = pocket;

        this.mouseChildren = true;
        this.mouseEnabled = false;

        ensureAttached();
    }

    public function ensureAttached():Void {
        if (this.pocket == null) return;

        var targetParent:DisplayObjectContainer = null;
        if (this.pocket.game != null) {
            targetParent = this.pocket.game;
        } else if (this.pocket.stage != null) {
            targetParent = this.pocket.stage;
        } else {
            targetParent = this.pocket;
        }

        if (targetParent != null && this.parent != targetParent) {
            if (this.parent != null) {
                try { this.parent.removeChild(this); } catch (_:Dynamic) {}
            }
            try { targetParent.addChild(this); } catch (_:Dynamic) {}
        }

        if (targetParent != null && targetParent.numChildren > 1) {
            try {
                if (targetParent.getChildIndex(this) != targetParent.numChildren - 1) {
                    targetParent.setChildIndex(this, targetParent.numChildren - 1);
                }
            } catch (_:Dynamic) {}
        }
    }

    private function showJoystick(layout:String, joystickName:String, isMouse:Bool, xPosition:Int, yPosition:Int):Void {
        ensureAttached();

        var existing:Joystick = cast this.getChildByName(joystickName);
        if (existing != null) {
            existing.visible = true;
            return;
        }

        var walkCtrl:WalkController = isMouse
            ? new MouseWalkSimulatorController(this.pocket)
            : new KeyboardWalkSimulatorController(this.pocket);

        var joystick = new Joystick(walkCtrl, !isMouse);
        joystick.name = joystickName;

        var defX:Float = xPosition;
        var defY:Float = yPosition;
        joystick.x = defX;
        joystick.y = defY;

        this.layoutController.register(layout, joystick, defX, defY, joystick.scaleX, joystick.scaleY);
        this.layoutController.load();

        var added:Joystick = cast addChild(joystick);
        if (isMouse) {
            this.joystickMouseSimulator = added;
        } else {
            this.joystickKeyboardSimulator = added;
        }
    }

    private function hideJoystick(layout:String, joystickName:String, isMouse:Bool):Void {
        var joystick:Joystick = cast this.getChildByName(joystickName);
        if (joystick != null && joystick.parent != null) {
            removeChild(joystick);
        }

        this.layoutController.unregister(layout);
        this.layoutController.load();

        if (isMouse) this.joystickMouseSimulator = null;
        else this.joystickKeyboardSimulator = null;
    }

    public function showJoystickMouseSimulator():Void {
        this.showJoystick(HelperSetting.LAYOUT_JOYSTICK_MOUSE, "joystickMouseSimulator", true, 75, 410);
    }

    public function hideJoystickMouseSimulator():Void {
        this.hideJoystick(HelperSetting.LAYOUT_JOYSTICK_MOUSE, "joystickMouseSimulator", true);
    }

    public function showJoystickKeyboardSimulator():Void {
        this.showJoystick(HelperSetting.LAYOUT_JOYSTICK_KEYBOARD, "joystickKeyboardSimulator", false, 75 + 110, 410);
    }

    public function hideJoystickKeyboardSimulator():Void {
        this.hideJoystick(HelperSetting.LAYOUT_JOYSTICK_KEYBOARD, "joystickKeyboardSimulator", false);
    }

    public function showSkillBar():Void {
        if (this.pocket == null || this.pocket.game == null) return;
        try {
            if (this.pocket.game.ui != null && this.pocket.game.ui.mcInterface != null && this.pocket.game.ui.mcInterface.actBar != null) {
                this.pocket.game.ui.mcInterface.actBar.visible = true;
            }
        } catch (_:Dynamic) {}
    }

    public function hideSkillBar():Void {
        if (this.pocket == null || this.pocket.game == null) return;
        try {
            if (this.pocket.game.ui != null && this.pocket.game.ui.mcInterface != null && this.pocket.game.ui.mcInterface.actBar != null) {
                this.pocket.game.ui.mcInterface.actBar.visible = false;
            }
        } catch (_:Dynamic) {}
    }

    public function addShortcutButton(actionName:String):Void {
        if (Reflect.field(shortcutButtons, actionName) != null) {
            ui.api.ApiNotificationManager.notify("Shortcut already placed: " + actionName);
            return;
        }

        ensureAttached();

        var layoutKey:String = "shortcut_" + Helper.sanitize(actionName);
        var coords = getSmartDefaultPosition(actionName);

        var btn = new ShortcutButton(this.pocket, actionName);
        btn.name = layoutKey;
        btn.x = coords.x;
        btn.y = coords.y;

        this.layoutController.register(layoutKey, btn, coords.x, coords.y, btn.scaleX, btn.scaleY);
        this.layoutController.load();

        var added:ShortcutButton = cast addChild(btn);
        Reflect.setField(shortcutButtons, actionName, added);

        persistShortcuts();
        ui.api.ApiNotificationManager.notify("Added shortcut: " + actionName);
    }

    private function getSmartDefaultPosition(actionName:String):{x:Float, y:Float} {
        // Ergonomic mobile placement defaults
        switch (actionName) {
            case "Auto Attack":
                return {x: 875, y: 395};
            case "Skill 2":
                return {x: 805, y: 420};
            case "Skill 3":
                return {x: 775, y: 355};
            case "Skill 4":
                return {x: 815, y: 295};
            case "Skill 5":
                return {x: 885, y: 265};
            case "Skill 6":
                return {x: 710, y: 420};
            case "Target Random Monster":
                return {x: 885, y: 330};
            case "Cancel Target":
                return {x: 725, y: 355};
            case "Rest":
                return {x: 880, y: 195};
            case "Jump":
                return {x: 810, y: 230};
            case "Dash":
                return {x: 740, y: 230};
            case "Bank":
                return {x: 880, y: 80};
            case "Inventory":
                return {x: 880, y: 135};
            default:
                // Grid layout for other utility/interface buttons
                var index:Int = countShortcuts();
                var COLS:Int = 3;
                var CELL_X:Float = 64;
                var CELL_Y:Float = 54;
                var ORIGIN_X:Float = 460;
                var ORIGIN_Y:Float = 200;

                var col:Int = index % COLS;
                var row:Int = Std.int(index / COLS);
                return {x: ORIGIN_X + col * CELL_X, y: ORIGIN_Y + row * CELL_Y};
        }
    }

    public function removeShortcutButton(actionName:String):Void {
        var btn:ShortcutButton = Reflect.field(shortcutButtons, actionName);
        if (btn == null) return;

        var layoutKey:String = "shortcut_" + Helper.sanitize(actionName);
        if (btn.parent != null) {
            removeChild(btn);
        }

        this.layoutController.unregister(layoutKey);
        this.layoutController.load();

        Reflect.deleteField(shortcutButtons, actionName);
        persistShortcuts();
        ui.api.ApiNotificationManager.notify("Removed shortcut: " + actionName);
    }

    public function loadPersistedShortcuts():Void {
        var saved:String = HelperSetting.getString(HelperSetting.OPTION_SHORTCUTS);
        if (saved == null || saved.length == 0) return;

        for (action in saved.split(",")) {
            var trimmed = StringTools.trim(action);
            if (trimmed.length > 0 && Reflect.field(shortcutButtons, trimmed) == null) {
                addShortcutButton(trimmed);
            }
        }
    }

    private function persistShortcuts():Void {
        var keys:Array<String> = Reflect.fields(shortcutButtons);
        HelperSetting.setString(HelperSetting.OPTION_SHORTCUTS, keys.join(","));
    }

    private function countShortcuts():Int {
        return Reflect.fields(shortcutButtons).length;
    }

    public function showEditLayout():Void {
        ensureAttached();
        this.layoutController.toggleEdit(true);
    }

    public function hideEditLayout(?event:Event):Void {
        this.layoutController.toggleEdit(false);
    }

    public function resetLayout():Void {
        this.layoutController.resetToDefaults();
    }

    public function resetShortcuts():Void {
        for (actionName in Reflect.fields(shortcutButtons)) {
            var btn:ShortcutButton = Reflect.field(shortcutButtons, actionName);
            if (btn != null && btn.parent != null) {
                removeChild(btn);
            }
            this.layoutController.unregister("shortcut_" + Helper.sanitize(actionName));
        }

        this.layoutController.load();
        this.shortcutButtons = {};
        persistShortcuts();
    }
}
