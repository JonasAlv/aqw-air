package pocket;

import data.Version;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import game.Network;
import pocket.GameCore;
import load.LoadManager;
import load.handlers.BackgroundLoad;
import load.handlers.GameLoad;
import load.handlers.VersionLoad;
import ui.GameUI;
import ui.Overlay;
import util.HelperLoader;

@:native("pocket.PocketRoot")
class PocketRoot extends Sprite {
    public static var SINGLETON:Dynamic;

    public var load:Dynamic;

    public var loadingTxt:TextField;
    public var versionTxt:TextField;
    public var loadingErrorTxt:TextField;
    public var background:MovieClip;

    public var overlay:Overlay;
    public var gameUI:GameUI;
    public var game:MovieClip;
    public var gameCore:GameCore;
    public var networkCore:Network;
    public var isMobileInput:Bool = false;

    private var backgroundLoad:BackgroundLoad;
    private var gameLoader:GameLoad;
    private var versionLoad:VersionLoad;

    public var version:Version;

    public var loadManager:LoadManager;
    public var config:Config;

    public function new() {
        super();
        SINGLETON = this;
        load = LoadManager.load;

        #if flash
        try {
            var proto:Dynamic = untyped flash.display.MovieClip["prototype"];
            if (proto != null && proto.removeAllChildren == null) {
                proto.removeAllChildren = function():Void {
                    var self:Dynamic = untyped __this__;
                    if (self != null && self.numChildren != null) {
                        var i:Int = Std.int(self.numChildren) - 1;
                        while (i >= 0) {
                            self.removeChildAt(i);
                            i--;
                        }
                    }
                };
            }
        } catch (_:Dynamic) {}
        #end

        // Keep system awake if on AIR
        try {
            var nativeAppClass:Dynamic = Type.resolveClass("flash.desktop.NativeApplication");
            if (nativeAppClass != null && nativeAppClass.nativeApplication != null) {
                nativeAppClass.nativeApplication.systemIdleMode = "keepAwake";
            }
        } catch (_:Dynamic) {}

        if (stage != null) {
            stage.color = 0x000000;
        }

        // Programmatic fallback UI for background & loading text
        background = new MovieClip();
        addChild(background);

        loadingTxt = new TextField();
        loadingTxt.width = 960;
        loadingTxt.y = 230;
        loadingTxt.defaultTextFormat = new TextFormat("_sans", 20, 0xFFFFFF, true, null, null, null, null, TextFormatAlign.CENTER);
        loadingTxt.selectable = false;
        addChild(loadingTxt);

        versionTxt = new TextField();
        versionTxt.width = 960;
        versionTxt.y = 510;
        versionTxt.defaultTextFormat = new TextFormat("_sans", 11, 0x888888, true, true, null, null, null, TextFormatAlign.CENTER);
        versionTxt.selectable = false;
        addChild(versionTxt);

        loadingErrorTxt = new TextField();
        loadingErrorTxt.width = 960;
        loadingErrorTxt.y = 280;
        loadingErrorTxt.defaultTextFormat = new TextFormat("_sans", 13, 0xFF4444, null, null, null, null, null, TextFormatAlign.CENTER);
        loadingErrorTxt.selectable = false;
        addChild(loadingErrorTxt);

        versionTxt.text = "Version " + Config.APP_VERSION;

        config = new Config();
        loadManager = new LoadManager();
        overlay = new Overlay(this);
        gameUI = new GameUI(this);
        gameCore = new GameCore(this);

        versionLoad = new VersionLoad(this);
        backgroundLoad = new BackgroundLoad(this);
        gameLoader = new GameLoad(this);

        if (overlay.debug != null) {
            overlay.debug.log("Init");
        }

        // Initialize Mod UI and API Automation
        initModBootstrap();

        check();
    }

    public function setInputPlatform(isMobile:Bool):Void {
        isMobileInput = isMobile;
        if (!isMobile) return;

        var mtClass:Dynamic = Type.resolveClass("flash.ui.Multitouch");
        if (mtClass == null) {
            throw "Multitouch is unavailable for the mobile input target.";
        }
        mtClass.inputMode = "touchPoint";
    }

    private var _gameInitialized:Bool = false;

    public function initModBootstrap():Void {
        try {
            var host:Dynamic = this;

            // 1. Mount Overlay and GameUI
            if (host.overlay != null && host.overlay.parent == null) {
                host.addChild(host.overlay);
            }
            if (host.gameUI != null && host.gameUI.parent == null) {
                host.addChild(host.gameUI);
            }

            try {
                flash.system.Security.allowDomain("*");
                flash.system.Security.allowInsecureDomain("*");
            } catch (_:Dynamic) {}

            try {
                var apiClass:Dynamic = Type.resolveClass("com.aqwapi.Api");
                if (apiClass != null) {
                    if (apiClass.ensureMathShims != null) apiClass.ensureMathShims();
                    if (apiClass.preloadAssets != null) apiClass.preloadAssets();
                }
            } catch (_:Dynamic) {}

            // 2. Inject Mod Menus & Notifications into Overlay
            if (host.overlay != null) {
                try {
                    ui.api.ApiMenus.inject(host.overlay);
                } catch (err:Dynamic) {
                    trace("[Pocket] ApiMenus.inject error: " + Std.string(err));
                }
            }

            // 3. Watch for game loading to initialize Api
            if (host.overlay != null) {
                host.overlay.addEventListener(flash.events.Event.ENTER_FRAME, onEnterFrameCheckGame);
            }
        } catch (e:Dynamic) {
            trace("[Pocket] Bootstrap error: " + Std.string(e));
        }
    }

    private function onEnterFrameCheckGame(e:flash.events.Event):Void {
        if (_gameInitialized) return;

        if (this.game != null) {
            _gameInitialized = true;
            if (this.overlay != null) {
                this.overlay.removeEventListener(flash.events.Event.ENTER_FRAME, onEnterFrameCheckGame);
            }

            try {
                var apiClass:Dynamic = Type.resolveClass("com.aqwapi.Api");
                if (apiClass != null && apiClass.init != null) {
                    apiClass.init(this.game);
                }
            } catch (err:Dynamic) {
                trace("[Pocket] Api.init error: " + Std.string(err));
            }
        }
    }

    public function check():Void {
        switch (HelperLoader.COUNT) {
            case 0:
                versionLoad.start();
            case 1:
                backgroundLoad.start();
            case 2:
                gameLoader.start();
            case 3:
                // Finished loading
        }
    }

    public function advance():Void {
        HelperLoader.COUNT++;
        check();
    }
}
