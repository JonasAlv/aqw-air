package ui.shortcut;

import controller.LayoutController;
import data.Action;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Multitouch;
import util.Helper;

class ShortcutButton extends Sprite {
    public var shortcutBtn:SimpleButton;
    public var shortcutTxt:TextField;

    public var actionName:String;
    private var pocket:Dynamic;
    private var bg:Sprite;

    private static inline var BTN_W:Float = 58;
    private static inline var BTN_H:Float = 48;
    private static inline var RADIUS:Float = 6;

    public function new(pocket:Dynamic, actionName:String) {
        super();
        this.pocket = pocket;
        this.actionName = actionName;

        this.mouseChildren = false;
        this.mouseEnabled = true;
        this.buttonMode = true;
        this.useHandCursor = true;

        // 1. Programmatic background
        bg = new Sprite();
        drawBackground(0x1E1E1E, 0x444444, 0.85);
        addChild(bg);

        // 2. Programmatic text label
        var txt = new TextField();
        var tf = new TextFormat("_sans", 9, 0xFFFFFF, true);
        tf.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = tf;
        txt.text = formatLabel(actionName);
        txt.width = BTN_W - 4;
        txt.height = BTN_H - 6;
        txt.x = 2;
        txt.y = Math.max(2, (BTN_H - txt.textHeight) / 2 - 3);
        txt.wordWrap = true;
        txt.multiline = true;
        txt.selectable = false;
        txt.mouseEnabled = false;
        addChild(txt);
        this.shortcutTxt = txt;

        // 3. SimpleButton dummy for backward compatibility with LayoutController
        var dummyState = new Sprite();
        dummyState.graphics.beginFill(0, 0);
        dummyState.graphics.drawRect(0, 0, BTN_W, BTN_H);
        dummyState.graphics.endFill();
        this.shortcutBtn = new SimpleButton(dummyState, dummyState, dummyState, dummyState);

        // 4. Interaction events
        addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 0, true);
        addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 0, true);
        addEventListener(MouseEvent.MOUSE_DOWN, onMouseDownState, false, 0, true);
        addEventListener(MouseEvent.MOUSE_UP, onMouseUpState, false, 0, true);
        addEventListener(MouseEvent.CLICK, onClick, false, 0, true);

        if (Multitouch.supportsTouchEvents) {
            addEventListener(TouchEvent.TOUCH_TAP, onClick, false, 0, true);
        }
    }

    private function drawBackground(fillColor:Int, borderColor:Int, alphaVal:Float):Void {
        bg.graphics.clear();
        bg.graphics.beginFill(fillColor, alphaVal);
        bg.graphics.lineStyle(1.5, borderColor, 0.95);
        bg.graphics.drawRoundRect(0, 0, BTN_W, BTN_H, RADIUS, RADIUS);
        bg.graphics.endFill();

        // Subtle top gloss line
        bg.graphics.lineStyle(1, 0xFFFFFF, 0.15);
        bg.graphics.moveTo(RADIUS, 2);
        bg.graphics.lineTo(BTN_W - RADIUS, 2);
    }

    private function onRollOver(e:MouseEvent):Void {
        if (!LayoutController.editMode) {
            drawBackground(0x2D2D2D, 0xFFCC00, 0.95);
        }
    }

    private function onRollOut(e:MouseEvent):Void {
        drawBackground(0x1E1E1E, 0x444444, 0.85);
    }

    private function onMouseDownState(e:MouseEvent):Void {
        if (!LayoutController.editMode) {
            drawBackground(0x121212, 0xFFAA00, 1.0);
        }
    }

    private function onMouseUpState(e:MouseEvent):Void {
        if (!LayoutController.editMode) {
            drawBackground(0x2D2D2D, 0xFFCC00, 0.95);
        }
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
            case "Options": "OPTIONS";
            case "Decline All Drops": "DECLINE\nDROPS";
            case "Toggle World": "WORLD\nMAP";
            case "Toggle Joystick": "JOYSTICK";
            case "Toggle Skills": "SKILL\nBAR";
            default: raw;
        };
    }

    private function onClick(e:Dynamic):Void {
        if (LayoutController.editMode) {
            return;
        }

        if (this.pocket == null || this.pocket.game == null) {
            return;
        }

        // 1. Check custom action handlers defined in ShortcutPicker
        for (action in ShortcutPicker.ACTIONS) {
            if (action.name == this.actionName) {
                if (action.onClick != null) {
                    action.onClick(this.pocket);
                    return;
                }
                break;
            }
        }

        // 2. Comprehensive fallback action execution
        var p = this.pocket;
        var g:Dynamic = (p != null) ? p.game : null;
        var w:Dynamic = (g != null) ? g.world : null;
        var ui:Dynamic = (g != null) ? g.ui : null;
        var mc:Dynamic = (ui != null) ? ui.mcInterface : null;

        switch (this.actionName) {
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

            case "Decline All Drops":
                if (ui != null && ui.dropStack != null) {
                    try {
                        while (ui.dropStack.numChildren > 0) {
                            ui.dropStack.removeChildAt(0);
                        }
                    } catch (_:Dynamic) {}
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
