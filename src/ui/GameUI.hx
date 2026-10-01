package ui;

import controller.LayoutController;
import controller.walk.KeyboardWalkSimulatorController;
import controller.walk.MouseWalkSimulatorController;
import controller.walk.WalkController;
import flash.display.Sprite;
import flash.events.Event;
import ui.input.Joystick;
import ui.shortcut.ShortcutButton;
import util.Helper;
import util.HelperSetting;

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

        ensureAttached();

        this.mouseChildren = true;
        this.mouseEnabled = false;
    }

    public function ensureAttached():Void {
        if (this.parent != null) return;
        if (this.pocket != null) {
            if (this.pocket.game != null && this.pocket.game.addChild != null) {
                this.pocket.game.addChild(this);
            } else if (this.pocket.addChild != null) {
                this.pocket.addChild(this);
            }
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

        var joystick = new Joystick(walkCtrl);
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
        this.showJoystick(HelperSetting.LAYOUT_JOYSTICK_MOUSE, "joystickMouseSimulator", true, 73, 348);
    }

    public function hideJoystickMouseSimulator():Void {
        this.hideJoystick(HelperSetting.LAYOUT_JOYSTICK_MOUSE, "joystickMouseSimulator", true);
    }

    public function showJoystickKeyboardSimulator():Void {
        this.showJoystick(HelperSetting.LAYOUT_JOYSTICK_KEYBOARD, "joystickKeyboardSimulator", false, 73 + 110, 348);
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
        } catch (e:Dynamic) {}
    }

    public function hideSkillBar():Void {
        if (this.pocket == null || this.pocket.game == null) return;
        try {
            if (this.pocket.game.ui != null && this.pocket.game.ui.mcInterface != null && this.pocket.game.ui.mcInterface.actBar != null) {
                this.pocket.game.ui.mcInterface.actBar.visible = false;
            }
        } catch (e:Dynamic) {}
    }

    public function addShortcutButton(actionName:String):Void {
        if (Reflect.field(shortcutButtons, actionName) != null) {
            ui.api.ApiNotificationManager.notify("Shortcut already placed: " + actionName);
            return;
        }

        ensureAttached();

        var layoutKey:String = "shortcut_" + Helper.sanitize(actionName);
        var index:Int = countShortcuts();

        var COLS:Int = 4;
        var CELL_X:Int = 64;
        var CELL_Y:Int = 54;
        var ORIGIN_X:Float = 480;
        var ORIGIN_Y:Float = 245;

        var col:Int = index % COLS;
        var row:Int = Std.int(index / COLS);

        var defaultX:Float = ORIGIN_X + col * CELL_X;
        var defaultY:Float = ORIGIN_Y + row * CELL_Y;

        var btn = new ShortcutButton(this.pocket, actionName);
        btn.name = layoutKey;
        btn.x = defaultX;
        btn.y = defaultY;

        this.layoutController.register(layoutKey, btn, defaultX, defaultY, btn.scaleX, btn.scaleY);
        this.layoutController.load();

        var added:ShortcutButton = cast addChild(btn);
        Reflect.setField(shortcutButtons, actionName, added);

        persistShortcuts();
        ui.api.ApiNotificationManager.notify("Added shortcut: " + actionName);
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
            if (action.length > 0) {
                addShortcutButton(action);
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
