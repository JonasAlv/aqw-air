package ui;

import controller.LayoutController;
import controller.walk.KeyboardWalkSimulatorController;
import controller.walk.MouseWalkSimulatorController;
import controller.walk.WalkController;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Rectangle;
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
    private var skillBarFrames:Array<Sprite> = [null, null, null, null, null, null, null];
    private var skillBarMasks:Array<Sprite> = [null, null, null, null, null, null, null];
    private var skillBarOriginalMasks:Array<Dynamic> = [null, null, null, null, null, null, null];
    private var skillLayoutHitAreas:Array<Sprite> = [null, null, null, null, null, null, null];
    private var skillLayoutIcons:Array<Dynamic> = [null, null, null, null, null, null, null];
    private var skillLayoutDragTarget:Sprite;
    private var skillLayoutDragOffset:flash.geom.Point;
    private var skillLayoutTouchID:Int = -1;
    private var nextShortcutX:Float = 0;
    private var nextShortcutY:Float = 0;
    private var shortcutPlacementWidth:Float = 0;
    private var shortcutPlacementHeight:Float = 0;
    private var shortcutPlacementInitialized:Bool = false;

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

    public function applySkillBarStyle():Void {
        if (this.pocket == null || this.pocket.game == null || this.pocket.game.ui == null
            || this.pocket.game.ui.mcInterface == null || this.pocket.game.ui.mcInterface.actBar == null) {
            return;
        }

        var actBar:Sprite = cast this.pocket.game.ui.mcInterface.actBar;
        registerSkillBarWidgets(actBar);
        var useInfinityStyle = HelperSetting.getInt(HelperSetting.OPTION_SKILL_BAR_STYLE, HelperSetting.SKILL_BAR_STYLE_CLASSIC)
            == HelperSetting.SKILL_BAR_STYLE_INFINITY;

        for (id in 1...7) {
            var icon:Sprite = cast actBar.getChildByName("i" + id);
            if (skillLayoutIcons[id] != icon) {
                if (skillLayoutIcons[id] != null) {
                    var staleIcon:Sprite = cast skillLayoutIcons[id];
                    removeSkillBarStyle(id, staleIcon);
                    removeSkillLayoutHitArea(id, staleIcon);
                }
            }
            if (icon == null) continue;

            var hitArea = skillLayoutHitAreas[id];
            if (hitArea == null || hitArea.parent != actBar) {
                if (hitArea != null && hitArea.parent != null) hitArea.parent.removeChild(hitArea);
                hitArea = new Sprite();
                hitArea.name = "SkillLayoutHitArea" + id;
                hitArea.mouseChildren = false;
                hitArea.alpha = 0.01;
                hitArea.addEventListener(MouseEvent.MOUSE_DOWN, onSkillIconMouseDown, false, 100, true);
                hitArea.addEventListener(TouchEvent.TOUCH_BEGIN, onSkillIconTouchBegin, false, 100, true);
                actBar.addChild(hitArea);
                skillLayoutHitAreas[id] = hitArea;
            }
            hitArea.mouseEnabled = LayoutController.editMode;
            positionSkillLayoutHitArea(actBar, icon, hitArea);

            if (!useInfinityStyle) {
                removeSkillBarStyle(id, icon);
                actBar.setChildIndex(hitArea, actBar.numChildren - 1);
                continue;
            }

            var mask:Sprite = skillBarMasks[id];
            if (mask == null || mask.parent != actBar) {
                skillBarOriginalMasks[id] = icon.mask;
                mask = new Sprite();
                mask.name = "InfinitySkillMask" + id;
                mask.visible = false;
                mask.mouseEnabled = false;
                mask.mouseChildren = false;
                actBar.addChild(mask);
                skillBarMasks[id] = mask;
                icon.mask = mask;
            } else if (icon.mask != mask) {
                skillBarOriginalMasks[id] = icon.mask;
                icon.mask = mask;
            }

            var frame:Sprite = skillBarFrames[id];
            if (frame == null) {
                frame = createSkillBarFrame();
                frame.name = "InfinitySkillFrame" + id;
                frame.mouseEnabled = false;
                frame.mouseChildren = false;
                actBar.addChild(frame);
                skillBarFrames[id] = frame;
            }
            positionSkillBarStyle(actBar, icon, mask, frame);
            actBar.setChildIndex(hitArea, actBar.numChildren - 1);
        }
    }

    public function setSkillBarLayoutEditMode(enabled:Bool):Void {
        if (this.pocket == null || this.pocket.game == null || this.pocket.game.ui == null
            || this.pocket.game.ui.mcInterface == null || this.pocket.game.ui.mcInterface.actBar == null) {
            return;
        }
        var actBar:Sprite = cast this.pocket.game.ui.mcInterface.actBar;
        registerSkillBarWidgets(actBar);
        for (id in 1...7) {
            if (skillLayoutHitAreas[id] != null) skillLayoutHitAreas[id].mouseEnabled = enabled;
        }
        applySkillBarStyle();
    }

    private function positionSkillLayoutHitArea(actBar:Sprite, icon:Sprite, hitArea:Sprite):Void {
        var bounds:Rectangle = icon.getBounds(actBar);
        var diameter:Float = Math.min(bounds.width, bounds.height);
        if (diameter <= 0) return;
        hitArea.graphics.clear();
        hitArea.graphics.beginFill(0xFFFFFF);
        hitArea.graphics.drawCircle(bounds.x + bounds.width * 0.5, bounds.y + bounds.height * 0.5, diameter * 0.5);
        hitArea.graphics.endFill();
    }

    private function removeSkillLayoutHitArea(id:Int, icon:Sprite):Void {
        var hitArea = skillLayoutHitAreas[id];
        if (hitArea != null) {
            hitArea.removeEventListener(MouseEvent.MOUSE_DOWN, onSkillIconMouseDown);
            hitArea.removeEventListener(TouchEvent.TOUCH_BEGIN, onSkillIconTouchBegin);
            if (hitArea.parent != null) hitArea.parent.removeChild(hitArea);
        }
        skillLayoutHitAreas[id] = null;
    }

    private function createSkillBarFrame():Sprite {
        return new Sprite();
    }

    private function positionSkillBarStyle(actBar:Sprite, icon:Sprite, mask:Sprite, frame:Sprite):Void {
        var bounds:Rectangle = icon.getBounds(actBar);
        var diameter:Float = Math.min(bounds.width, bounds.height);
        if (diameter <= 0) return;
        var centerX:Float = bounds.x + bounds.width * 0.5;
        var centerY:Float = bounds.y + bounds.height * 0.5;
        var radius:Float = diameter * 0.5;

        mask.graphics.clear();
        mask.graphics.beginFill(0xFFFFFF);
        mask.graphics.drawCircle(centerX, centerY, radius);
        mask.graphics.endFill();

        frame.graphics.clear();
        frame.graphics.lineStyle(Math.max(2, diameter * 0.055), 0x08090B, 1);
        frame.graphics.drawCircle(centerX, centerY, radius + diameter * 0.015);
        frame.graphics.lineStyle(Math.max(1, diameter * 0.022), 0x7A7D80, 0.9);
        frame.graphics.drawCircle(centerX, centerY, radius - diameter * 0.025);
        frame.graphics.lineStyle(Math.max(1, diameter * 0.018), 0x17191C, 1);
        frame.graphics.drawCircle(centerX, centerY, radius - diameter * 0.015);
    }

    private function removeSkillBarStyle(id:Int, icon:Dynamic):Void {
        var mask = skillBarMasks[id];
        var frame = skillBarFrames[id];
        if (icon != null && mask != null && icon.mask == mask) icon.mask = skillBarOriginalMasks[id];
        if (mask != null && mask.parent != null) mask.parent.removeChild(mask);
        if (frame != null && frame.parent != null) frame.parent.removeChild(frame);
        skillBarMasks[id] = null;
        skillBarFrames[id] = null;
        skillBarOriginalMasks[id] = null;
    }

    public function registerSkillBarWidgets(actBar:Sprite):Bool {
        if (actBar == null || this.layoutController == null) return false;
        var changed = false;
        for (id in 1...7) {
            var icon:Sprite = cast actBar.getChildByName("i" + id);
            if (skillLayoutIcons[id] == icon) continue;

            changed = true;
            var layoutId = HelperSetting.LAYOUT_SKILL_BAR + "_i" + id;
            if (skillLayoutIcons[id] != null) {
                var oldIcon:Sprite = cast skillLayoutIcons[id];
                removeSkillBarStyle(id, oldIcon);
                oldIcon.removeEventListener(MouseEvent.MOUSE_DOWN, onSkillIconMouseDown, true);
                oldIcon.removeEventListener(TouchEvent.TOUCH_BEGIN, onSkillIconTouchBegin, true);
                this.layoutController.unregister(layoutId);
            }
            skillLayoutIcons[id] = icon;
            if (icon == null) {
                continue;
            }

            this.layoutController.register(layoutId, icon, icon.x, icon.y, icon.scaleX, icon.scaleY);
            this.layoutController.loadWidget(layoutId);
        }
        return changed;
    }

    private function onSkillIconMouseDown(event:MouseEvent):Void {
        if (!LayoutController.editMode || stage == null) return;
        var icon = getSkillIconForHitArea(cast event.currentTarget);
        if (icon == null) return;
        beginSkillIconDrag(icon, event.stageX, event.stageY);
        event.stopImmediatePropagation();
        stage.addEventListener(MouseEvent.MOUSE_MOVE, onSkillIconMouseMove, false, 0, true);
        stage.addEventListener(MouseEvent.MOUSE_UP, onSkillIconMouseUp, false, 0, true);
    }

    private function onSkillIconTouchBegin(event:TouchEvent):Void {
        if (!LayoutController.editMode || stage == null || skillLayoutTouchID != -1) return;
        var icon = getSkillIconForHitArea(cast event.currentTarget);
        if (icon == null) return;
        skillLayoutTouchID = event.touchPointID;
        beginSkillIconDrag(icon, event.stageX, event.stageY);
        event.stopImmediatePropagation();
        stage.addEventListener(TouchEvent.TOUCH_MOVE, onSkillIconTouchMove, false, 0, true);
        stage.addEventListener(TouchEvent.TOUCH_END, onSkillIconTouchEnd, false, 0, true);
    }

    private function getSkillIconForHitArea(hitArea:Sprite):Sprite {
        for (id in 1...7) {
            if (skillLayoutHitAreas[id] == hitArea) return cast skillLayoutIcons[id];
        }
        return null;
    }

    private function beginSkillIconDrag(icon:Sprite, stageX:Float, stageY:Float):Void {
        skillLayoutDragTarget = icon;
        this.layoutController.selectWidget(getSkillLayoutId(icon));
        skillLayoutDragOffset = icon.parent.globalToLocal(new flash.geom.Point(stageX, stageY));
        skillLayoutDragOffset.x -= icon.x;
        skillLayoutDragOffset.y -= icon.y;
    }

    private function onSkillIconMouseMove(event:MouseEvent):Void {
        moveSkillIcon(event.stageX, event.stageY);
    }

    private function onSkillIconMouseUp(event:MouseEvent):Void {
        if (stage != null) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onSkillIconMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onSkillIconMouseUp);
        }
        saveSkillIconPosition();
    }

    private function onSkillIconTouchMove(event:TouchEvent):Void {
        if (event.touchPointID == skillLayoutTouchID) moveSkillIcon(event.stageX, event.stageY);
    }

    private function onSkillIconTouchEnd(event:TouchEvent):Void {
        if (event.touchPointID != skillLayoutTouchID) return;
        if (stage != null) {
            stage.removeEventListener(TouchEvent.TOUCH_MOVE, onSkillIconTouchMove);
            stage.removeEventListener(TouchEvent.TOUCH_END, onSkillIconTouchEnd);
        }
        skillLayoutTouchID = -1;
        saveSkillIconPosition();
    }

    private function moveSkillIcon(stageX:Float, stageY:Float):Void {
        if (skillLayoutDragTarget == null || skillLayoutDragTarget.parent == null || skillLayoutDragOffset == null) return;
        var pointer = skillLayoutDragTarget.parent.globalToLocal(new flash.geom.Point(stageX, stageY));
        skillLayoutDragTarget.x = pointer.x - skillLayoutDragOffset.x;
        skillLayoutDragTarget.y = pointer.y - skillLayoutDragOffset.y;
        for (id in 1...7) {
            if (skillLayoutIcons[id] == skillLayoutDragTarget && skillLayoutHitAreas[id] != null) {
                var actBar:Sprite = cast skillLayoutDragTarget.parent;
                positionSkillLayoutHitArea(actBar, skillLayoutDragTarget, skillLayoutHitAreas[id]);
                break;
            }
        }
        applySkillBarStyle();
    }

    private function saveSkillIconPosition():Void {
        if (skillLayoutDragTarget != null) {
            this.layoutController.updatePosition(
                getSkillLayoutId(skillLayoutDragTarget),
                skillLayoutDragTarget.x,
                skillLayoutDragTarget.y
            );
        }
        skillLayoutDragTarget = null;
        skillLayoutDragOffset = null;
    }

    private function getSkillLayoutId(icon:Sprite):String {
        for (id in 1...7) {
            if (skillLayoutIcons[id] == icon) return HelperSetting.LAYOUT_SKILL_BAR + "_i" + id;
        }
        return "";
    }

    public function addShortcutButton(actionName:String, notify:Bool = true):Void {
        if (Reflect.field(shortcutButtons, actionName) != null) {
            if (notify) {
                ui.api.ApiNotificationManager.notify("Shortcut already placed: " + actionName);
            }
            return;
        }

        ensureAttached();

        var layoutKey:String = "shortcut_" + Helper.sanitize(actionName);
        var coords = getSmartDefaultPosition();

        var btn = new ShortcutButton(this.pocket, actionName);
        btn.name = layoutKey;
        btn.x = coords.x;
        btn.y = coords.y;

        this.layoutController.register(layoutKey, btn, coords.x, coords.y, btn.scaleX, btn.scaleY);
        this.layoutController.load();

        var added:ShortcutButton = cast addChild(btn);
        Reflect.setField(shortcutButtons, actionName, added);

        persistShortcuts();
        if (notify) {
            ui.api.ApiNotificationManager.notify("Added shortcut: " + actionName);
        }
    }

    private function getSmartDefaultPosition():{x:Float, y:Float} {
        var stageW:Float = (this.pocket != null && this.pocket.game != null && this.pocket.game.stage != null)
            ? this.pocket.game.stage.stageWidth : 960;
        var stageH:Float = (this.pocket != null && this.pocket.game != null && this.pocket.game.stage != null)
            ? this.pocket.game.stage.stageHeight : 550;
        if (stageW <= 0) stageW = 960;
        if (stageH <= 0) stageH = 550;

        if (!shortcutPlacementInitialized || shortcutPlacementWidth != stageW || shortcutPlacementHeight != stageH) {
            shortcutPlacementInitialized = true;
            shortcutPlacementWidth = stageW;
            shortcutPlacementHeight = stageH;
            nextShortcutX = (stageW - ShortcutButton.WIDTH) / 2;
            nextShortcutY = (stageH - ShortcutButton.HEIGHT) / 2;
        }

        var position = {x: nextShortcutX, y: nextShortcutY};
        nextShortcutX += ShortcutButton.WIDTH + 8;
        if (nextShortcutX + ShortcutButton.WIDTH > stageW) {
            nextShortcutX = (stageW - ShortcutButton.WIDTH) / 2;
            nextShortcutY += ShortcutButton.HEIGHT + 8;
            if (nextShortcutY + ShortcutButton.HEIGHT > stageH) {
                nextShortcutY = Math.max(0, stageH - ShortcutButton.HEIGHT);
            }
        }
        return position;
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
                addShortcutButton(trimmed, false);
            }
        }
    }

    private function persistShortcuts():Void {
        var keys:Array<String> = Reflect.fields(shortcutButtons);
        HelperSetting.setString(HelperSetting.OPTION_SHORTCUTS, keys.join(","));
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
        shortcutPlacementInitialized = false;
        persistShortcuts();
    }
}
