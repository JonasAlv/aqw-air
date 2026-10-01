package game;

import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.events.Event;
import flash.Lib;

class Core {
    private var pocket:Dynamic;
    public var itemPagination:ItemPagination;
    public var itemFavorite:ItemFavorite;

    private var _currentFrame:String = "Init";
    public var currentFrame(get, set):String;

    private var _lastDetectedFrame:String = "";

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

        // Keep gameUI and overlay safely at the top of game
        try {
            var g:MovieClip = this.pocket.game;
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
