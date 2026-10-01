package ui.shortcut;

import controller.LayoutController;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Multitouch;
import util.Helper;

/**
 * Modern Quick Action / Shortcut Button created from scratch.
 * Supports direct drag-and-drop repositioning and one-tap deletion in Edit Mode.
 */
class ShortcutButton extends Sprite {
    public var actionName:String;
    public var shortcutBtn:SimpleButton;
    public var shortcutTxt:TextField;

    private var pocket:Dynamic;
    private var bg:Sprite;
    private var deleteBadge:Sprite;

    public static inline var WIDTH:Float = 60;
    public static inline var HEIGHT:Float = 50;
    private static inline var RADIUS:Float = 8;

    // Dragging state in edit mode
    private var isDragging:Bool = false;
    private var dragStartMouseX:Float = 0;
    private var dragStartMouseY:Float = 0;
    private var dragStartX:Float = 0;
    private var dragStartY:Float = 0;

    public function new(pocket:Dynamic, actionName:String) {
        super();
        this.pocket = pocket;
        this.actionName = actionName;

        this.buttonMode = true;
        this.useHandCursor = true;
        this.mouseChildren = true;

        // 1. Background
        bg = new Sprite();
        renderBackground(false, false);
        addChild(bg);

        // 2. Icon / Category Accent Badge
        var accentColor = getActionAccentColor(actionName);
        var accent = new Sprite();
        accent.graphics.beginFill(accentColor, 0.85);
        accent.graphics.drawRoundRect(4, 4, 6, 6, 2, 2);
        accent.graphics.endFill();
        addChild(accent);

        // 3. Label
        var txt = new TextField();
        var tf = new TextFormat("_sans", 9, 0xFFFFFF, true);
        tf.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = tf;
        txt.text = formatLabel(actionName);
        txt.width = WIDTH - 6;
        txt.height = HEIGHT - 8;
        txt.x = 3;
        txt.y = Math.max(3, (HEIGHT - txt.textHeight) / 2 - 2);
        txt.wordWrap = true;
        txt.multiline = true;
        txt.selectable = false;
        txt.mouseEnabled = false;
        addChild(txt);
        this.shortcutTxt = txt;

        // 4. Delete Badge (visible only in Edit Mode)
        deleteBadge = new Sprite();
        deleteBadge.graphics.beginFill(0xDC3545, 0.95);
        deleteBadge.graphics.lineStyle(1.5, 0xFFFFFF, 0.9);
        deleteBadge.graphics.drawCircle(0, 0, 9);
        deleteBadge.graphics.endFill();

        // Crisp vector X cross
        deleteBadge.graphics.lineStyle(1.8, 0xFFFFFF, 1.0);
        deleteBadge.graphics.moveTo(-4, -4);
        deleteBadge.graphics.lineTo(4, 4);
        deleteBadge.graphics.moveTo(4, -4);
        deleteBadge.graphics.lineTo(-4, 4);

        deleteBadge.x = WIDTH - 2;
        deleteBadge.y = 2;
        deleteBadge.visible = false;
        deleteBadge.buttonMode = true;
        deleteBadge.useHandCursor = true;

        deleteBadge.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            e.stopPropagation();
            if (this.pocket != null && this.pocket.gameUI != null) {
                this.pocket.gameUI.removeShortcutButton(this.actionName);
            }
        });
        addChild(deleteBadge);

        // 5. Compatibility dummy
        var dummy = new Sprite();
        dummy.graphics.beginFill(0, 0);
        dummy.graphics.drawRect(0, 0, WIDTH, HEIGHT);
        dummy.graphics.endFill();
        this.shortcutBtn = new SimpleButton(dummy, dummy, dummy, dummy);

        // 6. Interaction
        addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
        addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
        addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownHandler, false, 0, true);
        addEventListener(MouseEvent.CLICK, onClickHandler, false, 0, true);

        if (Multitouch.supportsTouchEvents) {
            addEventListener(TouchEvent.TOUCH_TAP, onClickHandler, false, 0, true);
        }
    }

    public function setEditMode(active:Bool):Void {
        deleteBadge.visible = active;
        renderBackground(false, active);
    }

    private function renderBackground(isHover:Bool, isEdit:Bool):Void {
        bg.graphics.clear();

        if (isEdit) {
            // Gold dashed outline in edit mode
            bg.graphics.beginFill(0x1F1F1F, 0.9);
            bg.graphics.lineStyle(2, 0xFFCC00, 1.0);
            bg.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, RADIUS, RADIUS);
            bg.graphics.endFill();
            return;
        }

        var fill = isHover ? 0x2E2E2E : 0x1A1A1A;
        var border = isHover ? 0xFFCC00 : 0x404040;
        var borderAlpha = isHover ? 0.95 : 0.8;

        bg.graphics.beginFill(fill, 0.88);
        bg.graphics.lineStyle(1.5, border, borderAlpha);
        bg.graphics.drawRoundRect(0, 0, WIDTH, HEIGHT, RADIUS, RADIUS);
        bg.graphics.endFill();

        // Top glossy highlight
        bg.graphics.lineStyle(1, 0xFFFFFF, isHover ? 0.25 : 0.12);
        bg.graphics.moveTo(RADIUS, 2);
        bg.graphics.lineTo(WIDTH - RADIUS, 2);
    }

    private function onRollOver(e:MouseEvent):Void {
        if (!LayoutController.editMode) {
            renderBackground(true, false);
        }
    }

    private function onRollOut(e:MouseEvent):Void {
        renderBackground(false, LayoutController.editMode);
    }

    private function onMouseDownHandler(e:MouseEvent):Void {
        if (LayoutController.editMode && stage != null) {
            isDragging = true;
            dragStartMouseX = stage.mouseX;
            dragStartMouseY = stage.mouseY;
            dragStartX = this.x;
            dragStartY = this.y;

            stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, 0, true);
            e.stopPropagation();
        }
    }

    private function onStageMouseMove(e:MouseEvent):Void {
        if (!isDragging || stage == null) return;
        var dx = stage.mouseX - dragStartMouseX;
        var dy = stage.mouseY - dragStartMouseY;
        this.x = dragStartX + dx;
        this.y = dragStartY + dy;
    }

    private function onStageMouseUp(e:MouseEvent):Void {
        if (!isDragging) return;
        isDragging = false;
        if (stage != null) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }

        // Save position in LayoutController
        if (this.pocket != null && this.pocket.gameUI != null && this.pocket.gameUI.layoutController != null) {
            this.pocket.gameUI.layoutController.updatePosition(this.name, this.x, this.y);
        }
    }

    private function onClickHandler(e:Dynamic):Void {
        if (LayoutController.editMode) return;
        executeAction();
    }

    private function getActionAccentColor(action:String):Int {
        return switch (action) {
            case "Auto Attack", "Skill 2", "Skill 3", "Skill 4", "Skill 5", "Skill 6", "Battle Analyzer", "Battle Analyzer Toggle": 0xFF4444; // Red combat
            case "Bank", "Inventory", "Outfits", "Custom Drops UI", "Decline All Drops": 0x3399FF; // Blue storage
            case "Rest", "Jump", "Dash", "Area List", "Toggle World": 0x28A745; // Green mobility
            case "Target Random Monster", "Cancel Target": 0xFFAA00; // Orange target
            case "Hide Monsters", "Hide Players", "Hide UI": 0x9B59B6; // Purple visibility
            default: 0xFFCC00; // Gold
        };
    }

    private function formatLabel(raw:String):String {
        if (raw == null) return "";
        return switch (raw) {
            case "Auto Attack": "AUTO\nATK";
            case "Target Random Monster": "TARGET\nMON";
            case "Cancel Target": "CANCEL\nTGT";
            case "Character Panel": "CHAR\nPANEL";
            case "Player HP Bar": "HP\nBAR";
            case "Quest Log": "QUEST\nLOG";
            case "Fix Lag": "FIX\nLAG";
            case "Skill 2": "SKILL 2";
            case "Skill 3": "SKILL 3";
            case "Skill 4": "SKILL 4";
            case "Skill 5": "SKILL 5";
            case "Skill 6": "SKILL 6";
            case "Inventory": "INV";
            case "Bank": "BANK";
            case "Outfits": "OUTFITS";
            case "Rest": "REST";
            case "Jump": "JUMP";
            case "Dash": "DASH";
            case "Hide Monsters": "HIDE\nMONS";
            case "Hide Players": "HIDE\nPLAYERS";
            case "Hide UI": "HIDE\nUI";
            case "Focus Chat": "CHAT";
            case "Friends List": "FRIENDS";
            case "Friendships UI": "FRIEND\nSHIPS";
            case "Area List": "AREA\nLIST";
            case "Options": "OPTIONS";
            case "Decline All Drops": "DECLINE\nDROPS";
            case "Custom Drops UI": "DROPS\nUI";
            case "Battle Analyzer": "DPS\nMETER";
            case "Battle Analyzer Toggle": "METER\nTOGGLE";
            case "Toggle World": "WORLD\nMAP";
            case "Toggle Joystick": "JOYSTICK";
            case "Toggle Skills": "SKILL\nBAR";
            case "Toggle Shortcuts": "TOGGLE\nBTNS";
            default: raw;
        };
    }

    public function executeAction():Void {
        if (this.pocket == null || this.pocket.game == null) return;

        var p = this.pocket;
        var g:Dynamic = (p != null) ? p.game : null;
        var w:Dynamic = (g != null) ? g.world : null;
        var ui:Dynamic = (g != null) ? g.ui : null;
        var mc:Dynamic = (ui != null) ? ui.mcInterface : null;

        switch (this.actionName) {
            case "Auto Attack":
                var bar:Dynamic = (mc != null) ? mc.actBar : null;
                if (bar != null) {
                    var icon:Dynamic = bar.getChildByName("i1");
                    if (icon != null && icon.actObj != null) {
                        if (icon.actObj.auto == true) w.approachTarget();
                        else w.testAction(icon.actObj);
                    }
                } else if (com.aqwapi.Api.combat != null) {
                    com.aqwapi.Api.combat.attack("*");
                }

            case "Skill 2", "Skill 3", "Skill 4", "Skill 5", "Skill 6":
                var skillIdx:Int = switch (this.actionName) {
                    case "Skill 2": 2;
                    case "Skill 3": 3;
                    case "Skill 4": 4;
                    case "Skill 5": 5;
                    case "Skill 6": 6;
                    default: 1;
                };
                var bar:Dynamic = (mc != null) ? mc.actBar : null;
                if (bar != null) {
                    var icon:Dynamic = bar.getChildByName("i" + skillIdx);
                    if (icon != null && icon.actObj != null) {
                        if (icon.actObj.auto == true) w.approachTarget();
                        else w.testAction(icon.actObj);
                    }
                } else if (com.aqwapi.Api.combat != null) {
                    com.aqwapi.Api.combat.useSkill(skillIdx - 1);
                }

            case "Bank":
                if (com.aqwapi.Api.inventory != null) {
                    com.aqwapi.Api.inventory.toggleBank();
                } else if (w != null && w.toggleBank != null) {
                    w.toggleBank();
                }

            case "Inventory":
                if (mc != null && mc.bInventory != null) {
                    mc.bInventory.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                } else if (w != null && w.toggleInventory != null) {
                    w.toggleInventory();
                }

            case "Quest Log":
                if (mc != null && mc.bQuest != null) {
                    mc.bQuest.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                } else if (w != null && w.toggleQuestLog != null) {
                    w.toggleQuestLog();
                }

            case "Character Panel":
                if (mc != null && mc.bChar != null) {
                    mc.bChar.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                }

            case "Options":
                if (mc != null && mc.bOption != null) {
                    mc.bOption.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                }

            case "Rest":
                if (com.aqwapi.Api.player != null) {
                    com.aqwapi.Api.player.rest();
                } else if (w != null && w.rest != null) {
                    w.rest();
                }

            case "Jump":
                var curCell = (com.aqwapi.Api.player != null && com.aqwapi.Api.player.cell != null) ? com.aqwapi.Api.player.cell : "Enter";
                var curPad = (com.aqwapi.Api.player != null && com.aqwapi.Api.player.pad != null) ? com.aqwapi.Api.player.pad : "Spawn";
                if (com.aqwapi.Api.map != null) {
                    com.aqwapi.Api.map.jump(curCell, curPad);
                } else if (w != null && w.moveToMouse != null) {
                    w.moveToMouse();
                }

            case "Dash":
                if (w != null && w.myAvatar != null && w.myAvatar.pMC != null) {
                    try {
                        w.myAvatar.pMC.spAtt();
                    } catch (_:Dynamic) {}
                }

            case "Target Random Monster":
                if (com.aqwapi.Api.combat != null) {
                    com.aqwapi.Api.combat.attack("*");
                } else if (w != null && w.approachTarget != null) {
                    w.approachTarget();
                }

            case "Cancel Target":
                if (com.aqwapi.Api.combat != null) {
                    com.aqwapi.Api.combat.cancelTarget();
                } else if (w != null && w.cancelTarget != null) {
                    w.cancelTarget();
                }

            case "Fix Lag":
                if (g != null && g.stopAllMovieClips != null) {
                    try {
                        g.stopAllMovieClips();
                        ui.api.ApiNotificationManager.notify("Lag Fixed: Stopped background animations");
                    } catch (_:Dynamic) {}
                }

            case "Hide Monsters":
                if (w != null) {
                    try {
                        var isVis:Bool = (w.strMonVis != "none");
                        w.strMonVis = isVis ? "none" : "all";
                        if (w.showMonsters != null) w.showMonsters(!isVis);
                    } catch (_:Dynamic) {}
                }

            case "Hide Players":
                if (w != null) {
                    try {
                        var curHide:Bool = (w.hidePlayers == true);
                        w.hidePlayers = !curHide;
                        if (w.showPlayers != null) w.showPlayers(curHide);
                    } catch (_:Dynamic) {}
                }

            case "Hide UI":
                if (ui != null) {
                    ui.visible = !ui.visible;
                }

            case "Player HP Bar":
                if (ui != null && mc != null && mc.showPFrame != null) {
                    try {
                        mc.showPFrame();
                    } catch (_:Dynamic) {}
                }

            case "Focus Chat":
                if (g != null && g.stage != null) {
                    g.stage.focus = null;
                    g.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 13, 13));
                }

            case "Friends List":
                if (mc != null && mc.bFriends != null) {
                    mc.bFriends.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                }

            case "Friendships UI":
                ui.api.ApiFriendshipModal.show(this.pocket);

            case "Area List":
                ui.api.ApiCellNavModal.show(this.pocket);

            case "Outfits":
                ui.api.ApiPresetModal.show(this.pocket);

            case "Battle Analyzer":
                ui.api.ApiCombatAnalyzerModal.show(this.pocket);

            case "Battle Analyzer Toggle":
                ui.api.ApiHudManager.toggleHud();

            case "Custom Drops UI":
                ui.api.ApiDropsModal.show(this.pocket);

            case "Decline All Drops":
                if (ui != null && ui.dropStack != null) {
                    try {
                        while (ui.dropStack.numChildren > 0) {
                            ui.dropStack.removeChildAt(0);
                        }
                    } catch (_:Dynamic) {}
                }

            case "Toggle World":
                if (w != null && w.map != null) {
                    w.map.visible = !w.map.visible;
                }

            case "Toggle Joystick":
                var cur = util.HelperSetting.getBool(util.HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE, true);
                var next = !cur;
                util.HelperSetting.setBool(util.HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE, next);
                if (p.gameUI != null) {
                    if (next) p.gameUI.showJoystickMouseSimulator();
                    else p.gameUI.hideJoystickMouseSimulator();
                }

            case "Toggle Skills":
                var cur = util.HelperSetting.getBool(util.HelperSetting.OPTION_SHOW_SKILL_BAR, true);
                var next = !cur;
                util.HelperSetting.setBool(util.HelperSetting.OPTION_SHOW_SKILL_BAR, next);
                if (p.gameUI != null) {
                    if (next) p.gameUI.showSkillBar();
                    else p.gameUI.hideSkillBar();
                }

            case "Toggle Shortcuts":
                if (p.gameUI != null && p.gameUI.shortcutButtons != null) {
                    for (name in Reflect.fields(p.gameUI.shortcutButtons)) {
                        if (name == "Toggle Shortcuts") continue;
                        var btn:Dynamic = Reflect.field(p.gameUI.shortcutButtons, name);
                        if (btn != null) btn.visible = !btn.visible;
                    }
                }

            default:
                if (g != null && Reflect.hasField(g, "triggerGameAction")) {
                    try {
                        Reflect.callMethod(g, Reflect.field(g, "triggerGameAction"), [this.actionName]);
                    } catch (_:Dynamic) {}
                }
        }
    }
}
