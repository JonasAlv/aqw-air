package pocket;

import flash.display.DisplayObjectContainer;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import flash.geom.Matrix;
import game.ItemFavorite;
import game.ItemPagination;
import util.HelperSetting;

class GameCore {
    private var pocket:Dynamic;
    public var itemPagination:ItemPagination;
    public var itemFavorite:ItemFavorite;

    private var _currentFrame:String = "Init";
    public var currentFrame(get, set):String;

    private var _lastDetectedFrame:String = "";
    private var _displayListCheckFrame:Int = 0;

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
        this.itemPagination = new ItemPagination(this.pocket);
        this.itemFavorite = new ItemFavorite(this.pocket);

        // Continuous state monitor attached to main MovieClip
        if (Lib.current != null) {
            Lib.current.addEventListener(Event.ENTER_FRAME, onEnterFrameWatcher, false, 0, true);
        } else if (this.pocket != null && Std.isOfType(this.pocket, flash.events.IEventDispatcher)) {
            cast(this.pocket, flash.events.IEventDispatcher).addEventListener(Event.ENTER_FRAME, onEnterFrameWatcher, false, 0, true);
        }
    }

    public function get_currentFrame():String {
        if (this.pocket != null && this.pocket.game != null) {
            try {
                // If player avatar is loaded in world, we are DEFINITELY in Game
                if (this.pocket.game.world != null && this.pocket.game.world.myAvatar != null) {
                    return "Game";
                }
                var lbl:String = this.pocket.game.currentLabel;
                if (lbl != null && lbl.length > 0) {
                    return lbl;
                }
            } catch (_:Dynamic) {}
        }
        return _currentFrame;
    }

    public function set_currentFrame(val:String):String {
        _currentFrame = val;
        return val;
    }

    private function onEnterFrameWatcher(e:Event):Void {
        if (this.pocket == null || this.pocket.game == null) return;

        var detected = get_currentFrame();
        if (detected != _lastDetectedFrame) {
            _lastDetectedFrame = detected;
            onFrameChange(detected);
        }

        if ((_displayListCheckFrame++ % 4) != 0) return;

        // Keep gameUI and overlay safely at the top of game
        try {
            var g:MovieClip = this.pocket.game;
            if (this.pocket.gameUI != null && this.pocket.game.ui != null
                && this.pocket.game.ui.mcInterface != null && this.pocket.game.ui.mcInterface.actBar != null) {
                if (this.pocket.gameUI.registerSkillBarWidgets(cast this.pocket.game.ui.mcInterface.actBar)) {
                    this.pocket.gameUI.applySkillBarStyle();
                }
            }
            if (this.pocket.gameUI != null) {
                if (this.pocket.gameUI.parent != g) {
                    g.addChild(this.pocket.gameUI);
                }
                if (g.numChildren > 1 && g.getChildIndex(this.pocket.gameUI) < g.numChildren - 2) {
                    g.setChildIndex(this.pocket.gameUI, g.numChildren - 1);
                }
            }
            if (this.pocket.overlay != null) {
                if (this.pocket.overlay.parent != g) {
                    g.addChild(this.pocket.overlay);
                }
                if (g.numChildren > 1 && g.getChildIndex(this.pocket.overlay) != g.numChildren - 1) {
                    g.setChildIndex(this.pocket.overlay, g.numChildren - 1);
                }
            }
        } catch (_:Dynamic) {}
    }

    public function setWorldFilters(filters:Array<Dynamic>):Void {
        if (this.pocket != null && this.pocket.game != null && this.pocket.game.world != null) {
            try {
                this.pocket.game.world.map.filters = filters;
                this.pocket.game.world.CHARS.filters = filters;
            } catch (e:Dynamic) {}
        }
    }

    public function coolDownAct(actData:Dynamic, overrideCD:Int = -1, overrideTS:Float = -1):Void {
        var world:Dynamic = this.pocket.game.world;
        var actBar:Dynamic = this.pocket.game.ui.mcInterface.actBar;
        var useOverride = overrideCD != -1;
        var showCD = !useOverride && this.pocket.game.litePreference.data.bSkillCD;
        var icons:Array<Dynamic> = cast world.getActIcons(actData);
        var iconCT:Dynamic = world.iconCT;
        var iconFlareClass:Dynamic = null;

        if (!useOverride) {
            iconFlareClass = world.getClass("iconFlare");
        }

        var actMaskClass:Dynamic = null;
        for (iconMC in icons) {
            if (iconMC.icon2 == null) {
                var bmpData = new BitmapData(50, 50, true, 0);

                // Draw the cooldown copy unmasked, then restore any client or style mask.
                var styleMask:DisplayObject = cast iconMC.mask;
                iconMC.mask = null;
                bmpData.draw(cast iconMC, null, cast iconCT);
                iconMC.mask = styleMask;

                var iconBitmap:Bitmap = cast actBar.addChild(new Bitmap(bmpData));
                iconMC.icon2 = iconBitmap;

                if (useOverride) {
                    iconBitmap.transform = iconMC.transform;
                    iconMC.ts = overrideTS;
                    iconMC.cd = overrideCD;
                } else {
                    var flare:DisplayObject = cast Type.createInstance(cast iconFlareClass, []);
                    actBar.addChild(flare);
                    iconBitmap.transform = flare.transform = iconMC.transform;
                    iconMC.ts = actData.ts;
                    iconMC.cd = actData.cd;
                }

                iconMC.tsg = Lib.getTimer();

                if (actMaskClass == null) {
                    actMaskClass = world.getClass("ActMask");
                }

                var maskMC:Dynamic = Type.createInstance(cast actMaskClass, []);
                actBar.addChild(cast maskMC);
                maskMC.scaleX = 0.33;
                maskMC.scaleY = 0.33;
                maskMC.x = Std.int(iconBitmap.x + iconBitmap.width * 0.5 - maskMC.width * 0.5);
                maskMC.y = Std.int(iconBitmap.y + iconBitmap.height * 0.5 - maskMC.height * 0.5);

                for (j in 0...4) {
                    Reflect.setField(maskMC, "e" + j + "oy", Reflect.field(Reflect.field(maskMC, "e" + j), "y"));
                }
                iconBitmap.mask = cast maskMC;
                applyInfinityCooldownClip(actBar, iconMC, iconBitmap);
            } else {
                var iconBitmap:Bitmap = cast iconMC.icon2;
                if (useOverride) {
                    iconMC.ts = overrideTS;
                    iconMC.cd = overrideCD;
                } else {
                    iconMC.ts = actData.ts;
                    iconMC.cd = actData.cd;
                }
                iconMC.tsg = Lib.getTimer();
                applyInfinityCooldownClip(actBar, iconMC, iconBitmap);
            }

            if (showCD) {
                switch (actData.ref) {
                    case "aa":
                        iconMC.ref = "txtCD0";
                    case "i1":
                        iconMC.ref = "txtCD5";
                    default:
                        iconMC.ref = "txtCD" + actData.ref.slice(1);
                }

                var cdText:Dynamic = actBar.getChildByName(iconMC.ref);
                actBar.setChildIndex(cast cdText, actBar.numChildren - 1);
                cdText.text = Std.string(Math.round(iconMC.cd * 0.1) / 100);
                cdText.visible = true;
            }

            var cooldownMask:Dynamic = cast iconMC.icon2.mask;
            for (j in 0...4) {
                var wedge:Dynamic = Reflect.field(cooldownMask, "e" + j);
                wedge.stop();
            }

            iconMC.removeEventListener(Event.ENTER_FRAME, world.countDownAct);
            iconMC.addEventListener(Event.ENTER_FRAME, world.countDownAct, false, 0, true);
        }
    }

    private function applyInfinityCooldownClip(actBar:Dynamic, icon:Dynamic, bitmap:Bitmap):Void {
        if (HelperSetting.getInt(HelperSetting.OPTION_SKILL_BAR_STYLE, HelperSetting.SKILL_BAR_STYLE_CLASSIC)
            != HelperSetting.SKILL_BAR_STYLE_INFINITY || Reflect.field(icon, "icon2Clip") != null) {
            return;
        }

        var originalTransform:Matrix = bitmap.transform.matrix.clone();
        var clipContainer = new Sprite();
        clipContainer.name = "InfinityCooldownClip";
        clipContainer.transform.matrix = originalTransform;
        actBar.addChild(clipContainer);

        if (bitmap.parent != null) bitmap.parent.removeChild(bitmap);
        bitmap.transform.matrix = new Matrix();
        clipContainer.addChild(bitmap);

        var circleMask = new Sprite();
        circleMask.name = "InfinityCooldownCircleMask";
        circleMask.visible = false;
        circleMask.graphics.beginFill(0xFFFFFF);
        circleMask.graphics.drawCircle(bitmap.bitmapData.width * 0.5, bitmap.bitmapData.height * 0.5,
            Math.min(bitmap.bitmapData.width, bitmap.bitmapData.height) * 0.5);
        circleMask.graphics.endFill();
        circleMask.transform.matrix = clipContainer.transform.matrix.clone();
        actBar.addChild(circleMask);
        clipContainer.mask = circleMask;

        Reflect.setField(icon, "icon2Clip", clipContainer);
        Reflect.setField(icon, "icon2CircleMask", circleMask);
    }

    private function removeInfinityCooldownClip(icon:Dynamic):Void {
        var clipContainer:Sprite = cast Reflect.field(icon, "icon2Clip");
        var circleMask:Sprite = cast Reflect.field(icon, "icon2CircleMask");
        if (clipContainer != null && clipContainer.parent != null) clipContainer.parent.removeChild(clipContainer);
        if (circleMask != null && circleMask.parent != null) circleMask.parent.removeChild(circleMask);
        Reflect.setField(icon, "icon2Clip", null);
        Reflect.setField(icon, "icon2CircleMask", null);
    }

    public function countDownAct(event:Event):Void {
        var iconMC:Dynamic = event.target;
        var icon2:Bitmap = cast iconMC.icon2;
        var world:Dynamic = this.pocket.game.world;

        if (icon2 == null || icon2.mask == null) {
            iconMC.removeEventListener(Event.ENTER_FRAME, world.countDownAct);
            return;
        }

        var actBar:Dynamic = this.pocket.game.ui.mcInterface.actBar;
        var now:Int = Lib.getTimer();
        var cd:Float;
        if (world.myAvatar != null && world.myAvatar.dataLeaf != null && world.myAvatar.dataLeaf.sta != null) {
            var haste:Float = Reflect.field(world.myAvatar.dataLeaf.sta, "$tha");
            cd = Math.round(iconMC.cd * (1 - Math.min(Math.max(haste, -1), 0.5)));
        } else {
            cd = iconMC.cd;
        }

        var progress:Float = (now - iconMC.tsg) / cd;
        var wedgeIndex:Int = Math.floor(progress * 4);
        var wedgeFrame:Int = Std.int((progress * 360) % 90) + 1;
        if (iconMC.actObj.lock) return;

        var cooldownMask:Dynamic = cast icon2.mask;
        if (progress < 0.99) {
            if (iconMC.ref != null) {
                actBar.getChildByName(iconMC.ref).text = Std.string(Math.round((1 - progress) * (cd / 1000) * 10) / 10);
            }

            for (w in 0...4) {
                var wedge:Dynamic = Reflect.field(cooldownMask, "e" + w);
                if (w < wedgeIndex) {
                    wedge.y = -300;
                } else {
                    wedge.y = Reflect.field(cooldownMask, "e" + w + "oy");
                    if (w > wedgeIndex) wedge.gotoAndStop(0);
                }
            }
            Reflect.field(cooldownMask, "e" + wedgeIndex).gotoAndStop(wedgeFrame);
        } else {
            if (iconMC.ref != null) actBar.getChildByName(iconMC.ref).visible = false;

            var oldMask:DisplayObject = icon2.mask;
            icon2.mask = null;
            oldMask.parent.removeChild(oldMask);
            iconMC.removeEventListener(Event.ENTER_FRAME, world.countDownAct);
            icon2.parent.removeChild(icon2);
            removeInfinityCooldownClip(iconMC);
            icon2.bitmapData.dispose();
            iconMC.icon2 = null;
        }
    }

    /**
     * Called by Game & Pocket
     * @param frame
     */
    public function onFrameChange(frame:String):Void {
        this._currentFrame = frame;

        if (this.pocket != null && this.pocket.overlay != null && this.pocket.overlay.setOverlayButtonTransform != null) {
            this.pocket.overlay.setOverlayButtonTransform();
        }

        if (this.pocket != null && this.pocket.game != null) {
            try {
                if (this.pocket.gameUI != null) {
                    if (this.pocket.gameUI.parent != this.pocket.game) {
                        this.pocket.game.addChild(this.pocket.gameUI);
                    }
                    this.pocket.game.setChildIndex(this.pocket.gameUI, this.pocket.game.numChildren - 1);
                }
                if (this.pocket.overlay != null) {
                    if (this.pocket.overlay.parent != this.pocket.game) {
                        this.pocket.game.addChild(this.pocket.overlay);
                    }
                    this.pocket.game.setChildIndex(this.pocket.overlay, this.pocket.game.numChildren - 1);
                }
            } catch (e:Dynamic) {}
        }

        // When entering Game frame, ensure persisted shortcuts & joysticks are active
        if (frame == "Game" && this.pocket != null && this.pocket.gameUI != null) {
            try {
                this.pocket.gameUI.applySkillBarStyle();
                this.pocket.gameUI.loadPersistedShortcuts();
                if (util.HelperSetting.getBool(util.HelperSetting.OPTION_SHOW_JOYSTICK_MOUSE, false)) {
                    this.pocket.gameUI.showJoystickMouseSimulator();
                }
                if (util.HelperSetting.getBool(util.HelperSetting.OPTION_SHOW_JOYSTICK_KEYBOARD, false)) {
                    this.pocket.gameUI.showJoystickKeyboardSimulator();
                }
            } catch (_:Dynamic) {}
        }
    }
}
