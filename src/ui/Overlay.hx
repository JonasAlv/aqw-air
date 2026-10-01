package ui;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;
import flash.net.URLRequest;
import flash.ui.Multitouch;
import flash.Vector;
import controller.walk.MouseWalkSimulatorController;
import ui.Notification;
import ui.option.Button;
import ui.option.Check;
import ui.option.Menu;
import ui.option.Option;
import ui.option.Toggle;
import ui.shortcut.ShortcutPicker;
import ui.util.Scroll;
import ui.api.ApiDashboardModal;
import util.Helper;
import util.HelperScroll;
import util.HelperSetting;

class Overlay extends MovieClip {
    public var showPanelBtn:SimpleButton;
    public var hidePanelBtn:SimpleButton;
    public var reportBugBtn:SimpleButton;
    public var updateBtn:SimpleButton;
    public var discordBtn:SimpleButton;

    public var contentMenu:Sprite;
    public var contentOptions:Sprite;
    public var contentMask:DisplayObject;
    public var contentScroll:Scroll;

    public var debug:Debug;
    public var notifications:Sprite;

    public var pocket:Dynamic;
    private var scrollHelper:HelperScroll;

    public var menus:Dynamic;

    public function getPocket():Dynamic {
        if (this.pocket != null) return this.pocket;
        if (this.parent != null) return this.parent;
        try {
            var g:Dynamic = untyped __global__["Pocket"];
            if (g != null && g.SINGLETON != null) return g.SINGLETON;
        } catch (e:Dynamic) {}
        return null;
    }

    public function new(pocket:Dynamic) {
        super();
        this.pocket = pocket;
        this.debug = new Debug();

        initMenus();

        #if flash
        untyped this.addFrameScript(0, initFrame, 1, panelFrame);
        #end

        if (this.pocket != null && this.pocket.addChild != null) {
            this.pocket.addChild(this);
        }

        this.notifications = new Sprite();
        addChild(this.notifications);
    }

    private static inline function isMobile():Bool {
        return Multitouch.supportsTouchEvents;
    }

    private function initMenus():Void {
        var menuList = new Vector<Menu>();

        // 1. General Menu
        var generalOpts = new Vector<Option>();
        generalOpts.push(new Toggle(
            HelperSetting.OPTION_FPS,
            0,
            "Frame Rate",
            "Choose the target FPS",
            true,
            ["24", "30", "60", "75", "120"],
            function(option:Dynamic):Void {
                var fpsValues:Array<Int> = [24, 30, 60, 75, 120];
                if (stage != null) stage.frameRate = fpsValues[option.getIndex()];
            },
            null,
            function(frame:String):Void {
                var fpsValues:Array<Int> = [24, 30, 60, 75, 120];
                var savedIndex:Int = HelperSetting.getInt(HelperSetting.OPTION_FPS);
                if (stage != null && savedIndex >= 0 && savedIndex < fpsValues.length) {
                    stage.frameRate = fpsValues[savedIndex];
                }
            }
        ));

        generalOpts.push(new Toggle(
            HelperSetting.OPTION_LANGUAGE,
            0,
            "Language",
            "Translate quest text only",
            true,
            ["English", "Português", "Tagalog", "Español", "Bahasa Indonesia", "Cebuano"],
            function(option:Dynamic):Void {
                var languages:Array<String> = ['en', 'pt', 'tl', 'es', 'id', 'ceb'];
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) {
                    pkt.config.option_language = languages[option.getIndex()];
                }
            },
            null,
            function(frame:String):Void {
                var languages:Array<String> = ['en', 'pt', 'tl', 'es', 'id', 'ceb'];
                var savedIndex:Int = HelperSetting.getInt(HelperSetting.OPTION_LANGUAGE);
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null && savedIndex >= 0 && savedIndex < languages.length) {
                    pkt.config.option_language = languages[savedIndex];
                }
            }
        ));

        generalOpts.push(new Toggle(
            HelperSetting.OPTION_LOCK_ORIENTATION,
            0,
            "Screen Orientation",
            "Choose how the screen rotates",
            isMobile(),
            ["Landscape", "Portrait", "Landscape Left", "Landscape Right", "Portrait Flipped"],
            function(option:Dynamic):Void {
                if (stage == null) return;
                try {
                    if (option.getIndex() == 0) {
                        untyped stage.autoOrients = true;
                        untyped stage.setAspectRatio("landscape");
                        return;
                    }
                    untyped stage.autoOrients = false;
                    untyped stage.setAspectRatio("any");
                    untyped stage.setOrientation(Helper.ORIENTATIONS[option.getIndex()]);
                } catch (e:Dynamic) {}
            },
            null,
            function(frame:String):Void {
                if (stage == null) return;
                var savedIndex:Int = HelperSetting.getInt(HelperSetting.OPTION_LOCK_ORIENTATION);
                try {
                    if (savedIndex == 0) {
                        untyped stage.autoOrients = true;
                        untyped stage.setAspectRatio("landscape");
                    } else {
                        untyped stage.autoOrients = false;
                        untyped stage.setAspectRatio("any");
                        untyped stage.setOrientation(Helper.ORIENTATIONS[savedIndex]);
                    }
                } catch (e:Dynamic) {}
            }
        ));

        generalOpts.push(new Check(
            HelperSetting.OPTION_PAGINATION,
            true,
            "Pagination",
            "Enable pagination in the inventory, bank...",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_pagination = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_pagination = HelperSetting.getBool(HelperSetting.OPTION_PAGINATION);
            }
        ));

        generalOpts.push(new Check(
            HelperSetting.OPTION_EQUIPPED_ON_TOP,
            true,
            "Equipped On Top",
            "Show equipped items at the top of the inventory, bank...",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_equipped_on_top = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_equipped_on_top = HelperSetting.getBool(HelperSetting.OPTION_EQUIPPED_ON_TOP);
            }
        ));

        generalOpts.push(new Check(
            HelperSetting.OPTION_DISCORD_RPC,
            true,
            "Discord RPC",
            "Enable Discord Rich Presence",
            !isMobile(),
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && untyped pkt.discordRichPresence != null) {
                    try {
                        if (option.state) {
                            pkt.discordRichPresence.enable();
                        } else {
                            pkt.discordRichPresence.disable();
                        }
                    } catch (e:Dynamic) {}
                }
            }
        ));

        generalOpts.push(new Button(
            null,
            "Hide Pocket",
            "Hide the Pocket overlay",
            "Hide Pocket",
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null) {
                    if (pkt.gameUI != null && pkt.gameUI.parent != null) pkt.gameUI.parent.removeChild(pkt.gameUI);
                    if (pkt.overlay != null && pkt.overlay.parent != null) pkt.overlay.parent.removeChild(pkt.overlay);
                }
            }
        ));

        generalOpts.push(new Check(
            null,
            false,
            "Show Debug",
            "Display debug on screen",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.overlay != null) {
                    if (option.state) {
                        if (pkt.overlay.debug != null && pkt.overlay.debug.parent == null) {
                            pkt.overlay.addChild(pkt.overlay.debug);
                        }
                    } else {
                        if (pkt.overlay.debug != null && pkt.overlay.debug.parent != null && pkt.overlay.contains(pkt.overlay.debug)) {
                            pkt.overlay.removeChild(pkt.overlay.debug);
                        }
                    }
                }
            }
        ));
        menuList.push(new Menu("General", generalOpts));

        // 2. Gameplay Menu
        var gameplayOpts = new Vector<Option>();
        gameplayOpts.push(new Check(
            HelperSetting.OPTION_SKILL_TOOLTIPS,
            true,
            "Show Skill Tooltips",
            "Display skill tooltips when hovering over skills.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_skill_tooltips = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_skill_tooltips = HelperSetting.getBool(HelperSetting.OPTION_SKILL_TOOLTIPS);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_DISABLE_CUTSCENES,
            false,
            "Disable cutscenes",
            "Skip cutscenes during gameplay.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_disable_cutscenes = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_disable_cutscenes = HelperSetting.getBool(HelperSetting.OPTION_DISABLE_CUTSCENES);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_SLOW_WALK,
            false,
            "Slow Walk",
            "Move slower when gently pushing the joystick, and at full speed when pushed further.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_slow_walk = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_slow_walk = HelperSetting.getBool(HelperSetting.OPTION_SLOW_WALK);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_PLAYER_ANIMATION_SKILL,
            true,
            "Player Skill Animations",
            "Disable other players' skill animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_player_animation_skill = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_player_animation_skill = HelperSetting.getBool(HelperSetting.OPTION_PLAYER_ANIMATION_SKILL);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_PLAYER_ANIMATION_AURA,
            true,
            "Player Aura Animations",
            "May hide other players' important buffs.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_player_animation_aura = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_player_animation_aura = HelperSetting.getBool(HelperSetting.OPTION_PLAYER_ANIMATION_AURA);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_MONSTER_ANIMATION_SKILL,
            true,
            "Monster Skill Animations",
            "Disable monster skill animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_monster_animation_skill = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_monster_animation_skill = HelperSetting.getBool(HelperSetting.OPTION_MONSTER_ANIMATION_SKILL);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_MONSTER_ANIMATION_AURA,
            true,
            "Monster Aura Animations",
            "May hide important boss mechanics.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_monster_animation_aura = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_monster_animation_aura = HelperSetting.getBool(HelperSetting.OPTION_MONSTER_ANIMATION_AURA);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_SELF_ANIMATION_SKILL,
            true,
            "Self Skill Animations",
            "Disable your own skill animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_self_animation_skill = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_self_animation_skill = HelperSetting.getBool(HelperSetting.OPTION_SELF_ANIMATION_SKILL);
            }
        ));

        gameplayOpts.push(new Check(
            HelperSetting.OPTION_SELF_ANIMATION_AURA,
            true,
            "Self Aura Animations",
            "Disable your own aura animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_self_animation_aura = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_self_animation_aura = HelperSetting.getBool(HelperSetting.OPTION_SELF_ANIMATION_AURA);
            }
        ));
        menuList.push(new Menu("Gameplay", gameplayOpts));

        // 3. Graphics Menu
        var graphicsOpts = new Vector<Option>();
        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_MONSTER,
            false,
            "Disable Monster Animations",
            "Freeze monster animations to improve FPS in battle.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_monster_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_monster_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MONSTER);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_HELM,
            false,
            "Disable Helm Animations",
            "Freeze animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_helm_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_helm_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_HELM);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_ARMOR,
            false,
            "Disable Armor Animations",
            "Freeze animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_armor_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_armor_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_ARMOR);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_CAPE,
            false,
            "Disable Cape Animations",
            "Freeze animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_cape_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_cape_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_CAPE);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_HAIR,
            false,
            "Disable Hair Animations",
            "Freeze animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_hair_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_hair_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_HAIR);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_WEAPON,
            false,
            "Disable Weapon Animations",
            "Freeze animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_weapon_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_weapon_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_WEAPON);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_MISC,
            false,
            "Disable Grounds Animations",
            "Freeze animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_misc_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_misc_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_MISC);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_ANIMATION_PET,
            false,
            "Disable Pet Animations",
            "Freeze animations.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_pet_off = option.state;
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_animation_pet_off = HelperSetting.getBool(HelperSetting.OPTION_ANIMATION_PET);
            }
        ));

        graphicsOpts.push(new Check(
            HelperSetting.OPTION_FILTER,
            false,
            "Disable Filters",
            "Remove glows, drop-shadows and other visual effects.",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null) {
                    if (pkt.config != null) pkt.config.option_filter_off = option.state;
                    if (pkt.game != null && pkt.game.MsgBox != null) {
                        try {
                            pkt.game.MsgBox.notify("Filter setting saved. Join a new map/relog to take effect.");
                        } catch (e:Dynamic) {}
                    }
                }
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.config != null) pkt.config.option_filter_off = HelperSetting.getBool(HelperSetting.OPTION_FILTER);
            }
        ));
        menuList.push(new Menu("Graphics", graphicsOpts));

        // 4. Controls Menu
        var controlsOpts = new Vector<Option>();
        controlsOpts.push(new Check(
            HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE,
            true,
            "Show Joystick",
            "Display joystick on screen",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.game == null || pkt.gameCore == null || pkt.gameCore.currentFrame != "Game") return;
                if (option.state) {
                    pkt.gameUI.showJoystickMouseSimulator();
                } else {
                    pkt.gameUI.hideJoystickMouseSimulator();
                }
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.gameUI == null) return;
                if (!HelperSetting.getBool(HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE)) return;
                if (frame != "Game") {
                    pkt.gameUI.hideJoystickMouseSimulator();
                } else {
                    pkt.gameUI.showJoystickMouseSimulator();
                }
            }
        ));

        controlsOpts.push(new Check(
            HelperSetting.OPTION_SHOW_JOYSTICK_KEYBOARD,
            false,
            "Show Arrow keys",
            "Keyboard arrow key simulator",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.game == null || pkt.gameCore == null || pkt.gameCore.currentFrame != "Game") return;
                if (option.state) {
                    pkt.gameUI.showJoystickKeyboardSimulator();
                } else {
                    pkt.gameUI.hideJoystickKeyboardSimulator();
                }
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.gameUI == null) return;
                if (!HelperSetting.getBool(HelperSetting.OPTION_SHOW_JOYSTICK_KEYBOARD)) return;
                if (frame != "Game") {
                    pkt.gameUI.hideJoystickKeyboardSimulator();
                } else {
                    pkt.gameUI.showJoystickKeyboardSimulator();
                }
            }
        ));

        controlsOpts.push(new Check(
            HelperSetting.OPTION_SHOW_SKILL_BAR,
            true,
            "Show Skill Bar",
            "Display skill bar on screen",
            true,
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.game == null || pkt.gameCore == null || pkt.gameCore.currentFrame != "Game") return;
                if (option.state) {
                    pkt.gameUI.showSkillBar();
                } else {
                    pkt.gameUI.hideSkillBar();
                }
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.gameUI == null) return;
                if (!HelperSetting.getBool(HelperSetting.OPTION_SHOW_SKILL_BAR)) return;
                if (frame != "Game") {
                    pkt.gameUI.hideSkillBar();
                } else {
                    pkt.gameUI.showSkillBar();
                }
            }
        ));

        controlsOpts.push(new Check(
            HelperSetting.OPTION_JOYSTICK_DASH,
            false,
            "Joystick Dash",
            "Enable dashing using joystick",
            true,
            function(option:Dynamic):Void {
                MouseWalkSimulatorController.IS_DASHING_ON = option.state;
            },
            function(frame:String):Void {
                MouseWalkSimulatorController.IS_DASHING_ON = HelperSetting.getBool(HelperSetting.OPTION_JOYSTICK_DASH);
            }
        ));
        menuList.push(new Menu("Controls", controlsOpts));

        // 5. Shortcuts Menu
        var shortcutsOpts = new Vector<Option>();
        shortcutsOpts.push(new Button(
            null,
            "Add Shortcut",
            "Place an action button on screen",
            "Add",
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.game == null || pkt.gameCore == null || pkt.gameCore.currentFrame != "Game") {
                    if (pkt != null && pkt.game != null && pkt.game.MsgBox != null) {
                        try { pkt.game.MsgBox.notify("Only available in-game."); } catch (e:Dynamic) {}
                    }
                    return;
                }

                if (pkt.overlay != null) pkt.overlay.onHidePanel(null);

                var shortcutPicker:DisplayObject = pkt.game.stage.getChildByName("ShortcutPicker");
                if (shortcutPicker != null && shortcutPicker.parent != null) {
                    shortcutPicker.parent.removeChild(shortcutPicker);
                }

                pkt.game.stage.addChild(new ShortcutPicker(pkt, function(actionName:String):Void {
                    pkt.gameUI.addShortcutButton(actionName);
                }));
            }
        ));

        shortcutsOpts.push(new Button(
            null,
            "Remove Shortcut",
            "Remove a shortcut button from screen",
            "Remove",
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.game == null || pkt.gameCore == null || pkt.gameCore.currentFrame != "Game") return;

                if (pkt.overlay != null) pkt.overlay.onHidePanel(null);

                var shortcutPicker:DisplayObject = pkt.game.stage.getChildByName("ShortcutPicker");
                if (shortcutPicker != null && shortcutPicker.parent != null) {
                    shortcutPicker.parent.removeChild(shortcutPicker);
                }

                pkt.game.stage.addChild(new ShortcutPicker(pkt, function(actionName:String):Void {
                    pkt.gameUI.removeShortcutButton(actionName);
                }));
            }
        ));

        shortcutsOpts.push(new Button(
            null,
            "Reset Shortcuts",
            "Remove all shortcut buttons from screen",
            "Reset",
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) {
                    pkt.gameUI.resetShortcuts();
                    if (pkt.game != null && pkt.game.MsgBox != null) {
                        try { pkt.game.MsgBox.notify("Shortcuts cleared."); } catch (e:Dynamic) {}
                    }
                }
            }
        ));
        menuList.push(new Menu("Shortcuts", shortcutsOpts));

        // 6. Layout Menu
        var layoutOpts = new Vector<Option>();
        layoutOpts.push(new Check(
            HelperSetting.OPTION_SNAP_TO_GRID,
            true,
            "Snap To Grid",
            "Show an alignment grid while editing layout",
            true
        ));

        layoutOpts.push(new Button(
            null,
            "Edit Layout",
            "Drag to reposition UI elements",
            "Edit",
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt == null || pkt.game == null || pkt.gameCore == null || pkt.gameCore.currentFrame != "Game") {
                    if (pkt != null && pkt.game != null && pkt.game.MsgBox != null) {
                        try { pkt.game.MsgBox.notify("Cannot edit outside the game screen."); } catch (e:Dynamic) {}
                    }
                    return;
                }

                pkt.gameCore.setWorldFilters([Helper.GRAYSCALE]);
                if (pkt.overlay != null) pkt.overlay.onHidePanel(null);
                pkt.gameUI.showEditLayout();
            },
            function(frame:String):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null && pkt.gameUI != null) pkt.gameUI.hideEditLayout();
            }
        ));

        layoutOpts.push(new Button(
            null,
            "Reset Layout",
            "Restore default positions",
            "Reset",
            function(option:Dynamic):Void {
                var pkt:Dynamic = getPocket();
                if (pkt != null) {
                    if (pkt.game != null && pkt.game.MsgBox != null) {
                        try { pkt.game.MsgBox.notify("Layout successfully restored."); } catch (e:Dynamic) {}
                    }
                    if (pkt.gameUI != null) pkt.gameUI.resetLayout();
                }
            }
        ));
        menuList.push(new Menu("Layout", layoutOpts));

        this.menus = menuList;
    }

    private function initFrame():Void {
        if (this.showPanelBtn != null) {
            this.showPanelBtn.addEventListener(MouseEvent.CLICK, onShowPanel);
        }

        var mList:Dynamic = this.menus;
        if (mList != null) {
            var mLen:Int = untyped mList.length;
            for (i in 0...mLen) {
                var menu:Dynamic = untyped mList[i];
                if (menu != null && menu.options != null) {
                    var opts:Dynamic = menu.options;
                    var oLen:Int = untyped opts.length;
                    for (j in 0...oLen) {
                        var option:Dynamic = untyped opts[j];
                        if (option != null && option.onOverlayStateChange != null) {
                            option.onOverlayStateChange("Init");
                        }
                    }
                }
            }
        }

        setOverlayButtonTransform();

        if (this.pocket != null && this.pocket.gameUI != null) {
            this.pocket.gameUI.loadPersistedShortcuts();
        }

        stop();
    }

    private function panelFrame():Void {
        this.visible = false;

        if (this.contentMenu != null) {
            while (this.contentMenu.numChildren > 0) {
                this.contentMenu.removeChildAt(0);
            }
        }

        if (this.hidePanelBtn != null) {
            this.hidePanelBtn.addEventListener(MouseEvent.CLICK, onHidePanel);
        }

        var heightTotal:Float = 0;
        var mList:Dynamic = this.menus;

        if (mList != null && this.contentMenu != null) {
            var mLen:Int = untyped mList.length;
            for (i in 0...mLen) {
                var menu:Dynamic = untyped mList[i];
                if (menu == null) continue;
                this.contentMenu.addChild(menu);
                menu.y = heightTotal;
                heightTotal += menu.height + 10;

                if (menu.options != null) {
                    var opts:Dynamic = menu.options;
                    var oLen:Int = untyped opts.length;
                    for (j in 0...oLen) {
                        var option:Dynamic = untyped opts[j];
                        if (option != null && option.onOverlayStateChange != null) {
                            option.onOverlayStateChange("Panel");
                        }
                    }
                }
            }
        }

        var firstMenu:Dynamic = (mList != null && untyped mList.length > 0) ? untyped mList[0] : null;
        if (firstMenu != null) {
            selectMenu(firstMenu);
        }

        if (this.reportBugBtn != null) this.reportBugBtn.addEventListener(MouseEvent.CLICK, onReportBug);
        if (this.updateBtn != null) this.updateBtn.addEventListener(MouseEvent.CLICK, onUpdate);
        if (this.discordBtn != null) this.discordBtn.addEventListener(MouseEvent.CLICK, onDiscord);

        this.visible = true;
        stop();
    }

    public function selectMenu(menu:Menu):Void {
        if (this.contentOptions == null || menu == null) return;

        while (this.contentOptions.numChildren > 0) {
            this.contentOptions.removeChildAt(0);
        }

        var heightTotal:Float = 0;
        if (menu.options != null) {
            var opts:Dynamic = menu.options;
            var oLen:Int = untyped opts.length;
            for (i in 0...oLen) {
                var option:Dynamic = untyped opts[i];
                if (option == null || !option.visible) continue;

                this.contentOptions.addChild(option);
                option.x = 17;
                option.y = heightTotal + 17;
                heightTotal += option.height + 5;
            }
        }

        if (this.scrollHelper != null) {
            this.scrollHelper.dispose();
            this.scrollHelper = null;
        }

        if (this.contentScroll != null && this.contentMask != null) {
            this.scrollHelper = new HelperScroll(this.contentScroll, this.contentOptions, this.contentMask);
        }
    }

    public function onShowPanel(?mouseEvent:MouseEvent):Void {
        ApiDashboardModal.show(this, this.pocket);
    }

    public function onHidePanel(?mouseEvent:MouseEvent):Void {
        ApiDashboardModal.close();
    }

    private function onReportBug(e:MouseEvent):Void {}

    private function onUpdate(e:MouseEvent):Void {}

    private function onDiscord(e:MouseEvent):Void {}

    public function notification(message:String):Void {
        ui.api.ApiNotificationManager.notify(message);
    }

    public function setOverlayButtonTransform():Void {
        if (this.pocket == null || this.pocket.game == null || this.showPanelBtn == null) {
            return;
        }

        var curFrame:String = (this.pocket.gameCore != null) ? this.pocket.gameCore.currentFrame : "";
        switch (curFrame) {
            case "Game":
                this.showPanelBtn.width = this.showPanelBtn.height = 24;
                this.showPanelBtn.x = this.showPanelBtn.y = 2;
            default:
                this.showPanelBtn.width = this.showPanelBtn.height = 37.3;
                this.showPanelBtn.x = 7.1;
                this.showPanelBtn.y = 264.9;
        }
    }
}
