package ui.api;

#if flash
import com.aqwapi.Api;
import com.aqwapi.modules.CombatEngine;
import com.aqwapi.modules.ScriptManager;
import com.aqwapi.utils.ApiLogger;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import ui.Overlay;
import util.HelperSetting;

class ApiMenus {
    private static var _injected:Bool = false;
    private static var _overlay:Overlay;
    private static var _floatingMenuBtn:Sprite = null;

    public static function resetMenuButtonPosition():Void {
        HelperSetting.setInt("api_floating_menu_x", 80);
        HelperSetting.setInt("api_floating_menu_y", 10);
        if (_floatingMenuBtn != null) {
            _floatingMenuBtn.x = 80;
            _floatingMenuBtn.y = 10;
        }
    }

    public static function inject(overlay:Overlay):Void {
        if (_injected) return;
        _injected = true;
        _overlay = overlay;

        var pocket:Dynamic = (overlay.pocket != null) ? overlay.pocket : ((overlay.parent != null) ? overlay.parent : null);
        if (pocket == null) {
            try {
                var g:Dynamic = untyped __global__["Pocket"];
                if (g != null && g.SINGLETON != null) pocket = g.SINGLETON;
            } catch (e:Dynamic) {}
        }

        // 1. Initialize notification HUD container
        var apiNotifs = new Sprite();
        overlay.addChild(apiNotifs);
        ApiNotificationManager.instance.init(apiNotifs);

        // 2. Restore Combat Manager state from persistent settings
        CombatEngine.farmClass = HelperSetting.getString("api_farm_class", "Current");
        CombatEngine.farmMode = HelperSetting.getString("api_farm_mode", "Auto");
        CombatEngine.soloClass = HelperSetting.getString("api_solo_class", "Current");
        CombatEngine.soloMode = HelperSetting.getString("api_solo_mode", "Auto");
        CombatEngine.bossClass = HelperSetting.getString("api_boss_class", "Current");
        CombatEngine.bossMode = HelperSetting.getString("api_boss_mode", "Auto");
        CombatEngine.dodgeClass = HelperSetting.getString("api_dodge_class", "Current");
        CombatEngine.dodgeMode = HelperSetting.getString("api_dodge_mode", "Auto");
        CombatEngine.smartClass = HelperSetting.getString("api_smart_class", "Current");
        CombatEngine.skillMode = HelperSetting.getString("api_smart_mode", "Auto");

        if (Api.combat != null) {
            Api.combat.infiniteRange = HelperSetting.getBool("api_infinite_range", false);
        }
        if (Api.map != null) {
            Api.map.autoDeathSpawn = HelperSetting.getBool("api_death_spawn", false);
            Api.map.usePrivateRoom = HelperSetting.getBool("api_private_rooms", true);
            Api.map.skipCutscenes = HelperSetting.getBool("api_skip_cutscenes", false);
        }
        ApiLogger.printToChat = HelperSetting.getBool("api_chat_logging", true);

        // 3. Restore loot and AC settings
        var initialLootState = HelperSetting.getBool("api_accept_loot", false);
        if (Api.drop != null) {
            Api.drop.acceptAll = initialLootState;
            if (initialLootState) {
                Api.drop.scanScreenDrops();
                Api.drop.acceptAllDrops();
            }
        }
        var initialACState = HelperSetting.getBool("api_accept_ac_drops", false);
        if (Api.drop != null) {
            Api.drop.acceptACs = initialACState;
            if (initialACState && !initialLootState) {
                Api.drop.scanScreenDrops();
                Api.drop.acceptACDrops();
            }
        }

        // 4. Floating menu button
        setupFloatingMenuButton(pocket, overlay);

        // 5. On-Screen HUD Buttons
        ApiHudManager.init(pocket, overlay);

        // 6. Frame hooks
        setupFrameHooks(pocket, overlay);
    }

    private static function setupFloatingMenuButton(pocket:Dynamic, overlay:Overlay):Void {
        var icon = new Sprite();
        var btnW:Float = 76;
        var btnH:Float = 26;

        icon.graphics.beginFill(0x161616, 0.95);
        icon.graphics.lineStyle(1, 0x333333);
        icon.graphics.drawRoundRect(0, 0, btnW, btnH, 6, 6);
        icon.graphics.endFill();

        var txt = new TextField();
        var fmt = new TextFormat("_sans", 11, 0xEEEEEE, true);
        fmt.align = TextFormatAlign.CENTER;
        txt.defaultTextFormat = fmt;
        txt.text = "Control";
        txt.width = btnW;
        txt.height = 18;
        txt.y = 4;
        txt.selectable = false;
        txt.mouseEnabled = false;
        icon.addChild(txt);

        icon.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent):Void {
            icon.graphics.clear();
            icon.graphics.beginFill(0x222222, 1);
            icon.graphics.lineStyle(1, 0x880000);
            icon.graphics.drawRoundRect(0, 0, btnW, btnH, 6, 6);
            icon.graphics.endFill();
            txt.textColor = 0xFFFFFF;
        });
        icon.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent):Void {
            icon.graphics.clear();
            icon.graphics.beginFill(0x161616, 0.95);
            icon.graphics.lineStyle(1, 0x333333);
            icon.graphics.drawRoundRect(0, 0, btnW, btnH, 6, 6);
            icon.graphics.endFill();
            txt.textColor = 0xEEEEEE;
        });

        _floatingMenuBtn = icon;
        var savedMenuX = HelperSetting.getInt("api_floating_menu_x", -1);
        var savedMenuY = HelperSetting.getInt("api_floating_menu_y", -1);
        icon.x = (savedMenuX >= 0) ? savedMenuX : 80;
        icon.y = (savedMenuY >= 0) ? savedMenuY : 10;
        icon.buttonMode = true;

        var theStage:Dynamic = (pocket != null && pocket.stage != null) ? pocket.stage : overlay.stage;
        if (theStage != null) {
            theStage.addChild(icon);
        } else {
            overlay.addEventListener(Event.ADDED_TO_STAGE, function(ev:Event):Void {
                if (overlay.stage != null) {
                    overlay.stage.addChild(icon);
                }
            });
        }

        var isDragging:Bool = false;
        var hasDragged:Bool = false;
        var dragStartX:Float = 0;
        var dragStartY:Float = 0;

        icon.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):Void {
            isDragging = true;
            hasDragged = false;
            dragStartX = e.stageX - icon.x;
            dragStartY = e.stageY - icon.y;
        });

        if (theStage != null) {
            theStage.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent):Void {
                if (isDragging) {
                    hasDragged = true;
                    var nx:Float = e.stageX - dragStartX;
                    var ny:Float = e.stageY - dragStartY;
                    var sw:Float = theStage.stageWidth > 0 ? theStage.stageWidth : 960;
                    var sh:Float = theStage.stageHeight > 0 ? theStage.stageHeight : 500;
                    if (nx < 0) nx = 0;
                    if (ny < 0) ny = 0;
                    if (nx > sw - btnW) nx = sw - btnW;
                    if (ny > sh - btnH) ny = sh - btnH;
                    icon.x = nx;
                    icon.y = ny;
                }
            });
            theStage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent):Void {
                if (isDragging && hasDragged) {
                    HelperSetting.setInt("api_floating_menu_x", Math.round(icon.x));
                    HelperSetting.setInt("api_floating_menu_y", Math.round(icon.y));
                }
                isDragging = false;
            });
        }

        icon.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):Void {
            if (hasDragged) return;
            if (ApiDashboardModal.isOpen()) {
                ApiDashboardModal.close();
            } else {
                ApiDashboardModal.show(overlay, pocket);
            }
        });

        // Hide floating button while dashboard is open
        overlay.addEventListener(Event.ENTER_FRAME, function(e:Event):Void {
            icon.visible = !ApiDashboardModal.isOpen();
        });
    }

    private static function setupFrameHooks(pocket:Dynamic, overlay:Overlay):Void {
        overlay.addEventListener(Event.ENTER_FRAME, function(e:Event):Void {
            // Cutscene skipping
            try {
                if (pocket.config.option_disable_cutscenes && pocket.game != null && pocket.game.world != null) {
                    var world = pocket.game.world;
                    if (world.mcExtSWF != null && world.mcExtSWF.numChildren > 0) {
                        var ext = world.mcExtSWF.getChildAt(0);
                        if (ext != null && Reflect.hasField(ext, "totalFrames")) {
                            ext.gotoAndPlay(Reflect.field(ext, "totalFrames") - 2);
                            if (Reflect.hasField(world, "showInterface")) {
                                world.showInterface();
                            }
                        }
                    }
                }
            } catch (err:Dynamic) {}

            // Infinite range & Death spawn tick
            var isScriptRunning = ScriptManager.SINGLETON.isRunning;
            var infiniteRangeActive = isScriptRunning || HelperSetting.getBool("api_infinite_range", false);
            var deathSpawnActive = isScriptRunning || HelperSetting.getBool("api_death_spawn", false);

            if (Api.map != null) {
                Api.map.autoDeathSpawn = deathSpawnActive;
                if (deathSpawnActive) {
                    Api.map.checkAutoDeathSpawn();
                }
            }
            if (Api.combat != null) {
                Api.combat.infiniteRange = infiniteRangeActive;
                if (infiniteRangeActive) {
                    Api.combat.applyInfiniteRange();
                }
            }
        });
    }
}
#else
class ApiMenus {
    public static function inject(overlay:Dynamic):Void {}
    public static function resetMenuButtonPosition():Void {}
}
#end
