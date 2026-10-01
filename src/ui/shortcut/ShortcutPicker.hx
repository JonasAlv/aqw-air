package ui.shortcut;

import data.Action;
import flash.display.DisplayObject;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.Vector;
import ui.option.Check;
import ui.option.Menu;
import ui.option.Option;
import ui.util.Scroll;
import flash.display.Shape;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import util.HelperScroll;
import util.HelperSetting;

class ShortcutPicker extends Sprite {
    public static var ACTIONS:Array<Action> = [
        new Action("Fix Lag", function(pocket:Dynamic):Void {
            if (pocket != null && pocket.game != null) {
                pocket.game.stopAllMovieClips();
            }
        }),
        new Action("Hide Monsters"),
        new Action("Hide Players"),
        new Action("Hide UI"),
        new Action("Auto Attack", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null) return;
            var bar = pocket.game.ui.mcInterface.actBar;
            if (bar != null) {
                var icon:Dynamic = bar.getChildByName("i1");
                if (icon != null && icon.actObj != null) {
                    if (icon.actObj.auto == true) {
                        pocket.game.world.approachTarget();
                    } else {
                        pocket.game.world.testAction(icon.actObj);
                    }
                }
            }
        }),
        new Action("Skill 2", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null) return;
            var bar = pocket.game.ui.mcInterface.actBar;
            if (bar != null) {
                var icon:Dynamic = bar.getChildByName("i2");
                if (icon != null && icon.actObj != null) {
                    if (icon.actObj.auto == true) {
                        pocket.game.world.approachTarget();
                    } else {
                        pocket.game.world.testAction(icon.actObj);
                    }
                }
            }
        }),
        new Action("Skill 3", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null) return;
            var bar = pocket.game.ui.mcInterface.actBar;
            if (bar != null) {
                var icon:Dynamic = bar.getChildByName("i3");
                if (icon != null && icon.actObj != null) {
                    if (icon.actObj.auto == true) {
                        pocket.game.world.approachTarget();
                    } else {
                        pocket.game.world.testAction(icon.actObj);
                    }
                }
            }
        }),
        new Action("Skill 4", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null) return;
            var bar = pocket.game.ui.mcInterface.actBar;
            if (bar != null) {
                var icon:Dynamic = bar.getChildByName("i4");
                if (icon != null && icon.actObj != null) {
                    if (icon.actObj.auto == true) {
                        pocket.game.world.approachTarget();
                    } else {
                        pocket.game.world.testAction(icon.actObj);
                    }
                }
            }
        }),
        new Action("Skill 5", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null) return;
            var bar = pocket.game.ui.mcInterface.actBar;
            if (bar != null) {
                var icon:Dynamic = bar.getChildByName("i5");
                if (icon != null && icon.actObj != null) {
                    if (icon.actObj.auto == true) {
                        pocket.game.world.approachTarget();
                    } else {
                        pocket.game.world.testAction(icon.actObj);
                    }
                }
            }
        }),
        new Action("Skill 6", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null) return;
            var bar = pocket.game.ui.mcInterface.actBar;
            if (bar != null) {
                var icon:Dynamic = bar.getChildByName("i6");
                if (icon != null && icon.actObj != null) {
                    if (icon.actObj.auto == true) {
                        pocket.game.world.approachTarget();
                    } else {
                        pocket.game.world.testAction(icon.actObj);
                    }
                }
            }
        }),
        new Action("Target Random Monster"),
        new Action("Cancel Target"),
        new Action("Rest"),
        new Action("Dash"),
        new Action("Jump"),
        new Action("Player HP Bar"),
        new Action("Focus Chat", function(pocket:Dynamic):Void {
            if (pocket != null && pocket.game != null) {
                pocket.game.stage.focus = null;
                pocket.game.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 13, 13));
            }
        }),
        new Action("Inventory"),
        new Action("Bank"),
        new Action("Outfits"),
        new Action("Quest Log"),
        new Action("Character Panel"),
        new Action("Stats Overview"),
        new Action("Battle Analyzer"),
        new Action("Battle Analyzer Toggle"),
        new Action("Friends List"),
        new Action("Friendships UI"),
        new Action("Area List"),
        new Action("Options"),
        new Action("Custom Drops UI"),
        new Action("Decline All Drops"),
        new Action("Toggle World", function(pocket:Dynamic):Void {
            if (pocket != null && pocket.game != null && pocket.game.world != null && pocket.game.world.map != null) {
                pocket.game.world.map.visible = !pocket.game.world.map.visible;
            }
        }),
        new Action("Toggle Joystick", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.gameCore == null || pocket.gameCore.currentFrame != "Game") return;
            if (pocket.overlay != null && pocket.overlay.menus != null) {
                var menus:Dynamic = pocket.overlay.menus;
                var mLen:Int = untyped menus.length;
                for (i in 0...mLen) {
                    var menu:Dynamic = untyped menus[i];
                    if (menu != null && menu.options != null) {
                        var opts:Dynamic = menu.options;
                        var oLen:Int = untyped opts.length;
                        for (j in 0...oLen) {
                            var option:Dynamic = untyped opts[j];
                            if (option != null && option.key == HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE) {
                                (cast option : Check).onToggle();
                                return;
                            }
                        }
                    }
                }
            }
        }),
        new Action("Toggle Skills", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.gameCore == null || pocket.gameCore.currentFrame != "Game") return;
            if (pocket.overlay != null && pocket.overlay.menus != null) {
                var menus:Dynamic = pocket.overlay.menus;
                var mLen:Int = untyped menus.length;
                for (i in 0...mLen) {
                    var menu:Dynamic = untyped menus[i];
                    if (menu != null && menu.options != null) {
                        var opts:Dynamic = menu.options;
                        var oLen:Int = untyped opts.length;
                        for (j in 0...oLen) {
                            var option:Dynamic = untyped opts[j];
                            if (option != null && option.key == HelperSetting.OPTION_SHOW_SKILL_BAR) {
                                (cast option : Check).onToggle();
                                return;
                            }
                        }
                    }
                }
            }
        }),
        new Action("Toggle Skills Shortcuts", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null || pocket.gameUI == null) return;
            var isVisible:Null<Bool> = null;
            var btns:Dynamic = pocket.gameUI.shortcutButtons;
            if (btns != null) {
                for (actionName in Reflect.fields(btns)) {
                    switch (actionName) {
                        case "Auto Attack", "Skill 2", "Skill 3", "Skill 4", "Skill 5", "Skill 6":
                            var btn:Dynamic = Reflect.field(btns, actionName);
                            if (btn != null) {
                                if (isVisible == null) {
                                    isVisible = btn.visible;
                                }
                                btn.visible = !isVisible;
                            }
                    }
                }
            }
        }),
        new Action("Toggle Shortcuts", function(pocket:Dynamic):Void {
            if (pocket == null || pocket.game == null || pocket.gameUI == null) return;
            var btns:Dynamic = pocket.gameUI.shortcutButtons;
            if (btns != null) {
                for (actionName in Reflect.fields(btns)) {
                    if (actionName == "Toggle Shortcuts") continue;
                    var btn:Dynamic = Reflect.field(btns, actionName);
                    if (btn != null) {
                        btn.visible = !btn.visible;
                    }
                }
            }
        }),
        new Action("Travel Menu's Travel"),
        new Action("Camera Tool"),
        new Action("World Camera"),
        new Action("World Camera's Hide")
    ];

    public var closeBtn:SimpleButton;
    public var content:Sprite;
    public var contentMask:DisplayObject;
    public var contentScroll:Scroll;

    private var pocket:Dynamic;
    private var onPick:String->Void;

    public function new(pocket:Dynamic, onPick:String->Void) {
        super();
        this.pocket = pocket;
        this.onPick = onPick;
        this.name = "ShortcutPicker";

        addEventListener(Event.ADDED_TO_STAGE, onAdded, false, 0, true);
    }

    private function onAdded(e:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        buildPanel();
    }

    private function buildPanel():Void {
        if (closeBtn != null) {
            closeBtn.addEventListener(MouseEvent.CLICK, onDismiss, false, 0, true);
        }

        if (content != null) {
            var i:Int = 0;
            for (action in ACTIONS) {
                var shortcutRow = new ShortcutRow();
                shortcutRow.name = action.name;

                if (shortcutRow.shortcutTxt != null) {
                    shortcutRow.shortcutTxt.selectable = false;
                    shortcutRow.shortcutTxt.mouseEnabled = false;
                    shortcutRow.shortcutTxt.text = action.name;
                }

                shortcutRow.y = i * (shortcutRow.height > 0 ? shortcutRow.height : 30);
                shortcutRow.buttonMode = true;
                shortcutRow.useHandCursor = true;

                shortcutRow.addEventListener(MouseEvent.CLICK, onRowClick, false, 0, true);
                content.addChild(shortcutRow);
                i++;
            }

            if (contentScroll != null && contentMask != null) {
                new HelperScroll(contentScroll, content, contentMask);
            }
        } else {
            // Programmatic UI when SWF symbol is not available
            var stageW:Float = (stage != null && stage.stageWidth > 0) ? stage.stageWidth : 960;
            var stageH:Float = (stage != null && stage.stageHeight > 0) ? stage.stageHeight : 500;

            var backdrop = new Sprite();
            backdrop.graphics.beginFill(0x000000, 0.65);
            backdrop.graphics.drawRect(0, 0, stageW, stageH);
            backdrop.graphics.endFill();
            backdrop.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
                if (e.target == backdrop) onDismiss();
            });
            addChild(backdrop);

            var winW:Float = 480;
            var winH:Float = 400;
            var win = new Sprite();
            win.graphics.beginFill(0x161616, 0.98);
            win.graphics.lineStyle(1.5, 0x333333);
            win.graphics.drawRoundRect(0, 0, winW, winH, 8, 8);
            win.graphics.endFill();
            win.x = (stageW - winW) / 2;
            win.y = (stageH - winH) / 2;
            addChild(win);

            var title = new TextField();
            title.defaultTextFormat = new TextFormat("_sans", 13, 0xFFCC00, true);
            title.text = "SELECT SHORTCUT ACTION";
            title.autoSize = TextFieldAutoSize.LEFT;
            title.x = 16;
            title.y = 12;
            title.selectable = false;
            title.mouseEnabled = false;
            win.addChild(title);

            var closeBtnSp = new Sprite();
            closeBtnSp.graphics.beginFill(0x282828);
            closeBtnSp.graphics.drawRoundRect(0, 0, 24, 24, 4, 4);
            closeBtnSp.graphics.endFill();
            closeBtnSp.x = winW - 36;
            closeBtnSp.y = 8;
            closeBtnSp.buttonMode = true;
            var closeTxt = new TextField();
            closeTxt.defaultTextFormat = new TextFormat("_sans", 12, 0xAAAAAA, true);
            closeTxt.text = "✕";
            closeTxt.autoSize = TextFieldAutoSize.CENTER;
            closeTxt.x = 7;
            closeTxt.y = 4;
            closeTxt.selectable = false;
            closeTxt.mouseEnabled = false;
            closeBtnSp.addChild(closeTxt);
            closeBtnSp.addEventListener(MouseEvent.CLICK, onDismiss);
            win.addChild(closeBtnSp);

            var listContainer = new Sprite();
            listContainer.x = 16;
            listContainer.y = 44;
            win.addChild(listContainer);

            var maskSp = new Shape();
            maskSp.graphics.beginFill(0xFFFFFF);
            maskSp.graphics.drawRect(0, 0, winW - 32, winH - 56);
            maskSp.graphics.endFill();
            maskSp.x = 16;
            maskSp.y = 44;
            win.addChild(maskSp);
            listContainer.mask = maskSp;

            var colW:Float = (winW - 44) / 2;
            var rowH:Float = 32;
            var i:Int = 0;
            for (action in ACTIONS) {
                var col = i % 2;
                var row = Std.int(i / 2);
                var btn = new Sprite();
                btn.graphics.beginFill(0x222222);
                btn.graphics.lineStyle(1, 0x383838);
                btn.graphics.drawRoundRect(0, 0, colW, rowH - 4, 4, 4);
                btn.graphics.endFill();
                btn.x = col * (colW + 12);
                btn.y = row * rowH;
                btn.buttonMode = true;
                btn.mouseChildren = false;

                var txt = new TextField();
                txt.defaultTextFormat = new TextFormat("_sans", 11, 0xDDDDDD);
                txt.text = action.name;
                txt.autoSize = TextFieldAutoSize.CENTER;
                txt.width = colW;
                txt.y = 5;
                txt.selectable = false;
                txt.mouseEnabled = false;
                btn.addChild(txt);

                var actionName = action.name;
                btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
                    if (onPick != null) onPick(actionName);
                    onDismiss();
                });
                btn.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):Void {
                    btn.graphics.clear();
                    btn.graphics.beginFill(0x333333);
                    btn.graphics.lineStyle(1, 0x555555);
                    btn.graphics.drawRoundRect(0, 0, colW, rowH - 4, 4, 4);
                    btn.graphics.endFill();
                });
                btn.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):Void {
                    btn.graphics.clear();
                    btn.graphics.beginFill(0x222222);
                    btn.graphics.lineStyle(1, 0x383838);
                    btn.graphics.drawRoundRect(0, 0, colW, rowH - 4, 4, 4);
                    btn.graphics.endFill();
                });

                listContainer.addChild(btn);
                i++;
            }

            var totalRows = Std.int((ACTIONS.length + 1) / 2);
            var maxScroll = Math.max(0, totalRows * rowH - (winH - 56));
            win.addEventListener(MouseEvent.MOUSE_WHEEL, function(e:MouseEvent):Void {
                var newY = listContainer.y + (e.delta > 0 ? 30 : -30);
                if (newY > 44) newY = 44;
                if (newY < 44 - maxScroll) newY = 44 - maxScroll;
                listContainer.y = newY;
            });
        }
    }

    private function onRowClick(e:MouseEvent):Void {
        var target:Sprite = cast e.currentTarget;
        if (target != null && onPick != null) {
            onPick(target.name);
        }
    }

    private function onDismiss(?e:MouseEvent):Void {
        if (parent != null) {
            parent.removeChild(this);
        }
    }
}
