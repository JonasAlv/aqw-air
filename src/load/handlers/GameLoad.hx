package load.handlers;

import flash.display.Loader;
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import game.Network;
import load.Load;
import util.HelperLoader;

@:native("load.handlers.GameLoad")
class GameLoad extends Load {
    public function new(pocket:Dynamic) {
        super(pocket);
    }

    override public function start():Void {
        if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
            this.pocket.overlay.debug.log("Loading game");
        }

        if (this.pocket.loadingTxt != null) {
            this.pocket.loadingTxt.text = "Loading Game...";
        }

        this.url = "app:/gamefiles/game.swf";
        super.start();
    }

    override private function onCompleted(event:Event):Void {
        if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
            this.pocket.overlay.debug.log("Game client loaded");
        }

        try {
            if (this.pocket.overlay != null && this.pocket.overlay.parent == this.pocket) {
                this.pocket.removeChild(this.pocket.overlay);
            }
            if (this.pocket.gameUI != null && this.pocket.gameUI.parent == this.pocket) {
                this.pocket.removeChild(this.pocket.gameUI);
            }
        } catch (_:Dynamic) {}

        var targetLoader:Loader = untyped event.target.loader;
        var gameMC:MovieClip = cast(targetLoader.content, MovieClip);

        untyped gameMC.pocket = this.pocket;

        this.pocket.game = cast(this.pocket.stage.addChild(gameMC), MovieClip);

        if (this.pocket.overlay != null) {
            this.pocket.game.addChild(this.pocket.overlay);
        }
        if (this.pocket.gameUI != null) {
            this.pocket.gameUI.pocket = this.pocket;
            this.pocket.game.addChild(this.pocket.gameUI);
        }

        if (this.pocket.game.params != null) {
            this.pocket.game.params.sTitle = this.pocket.version.sTitle;
            this.pocket.game.params.isWeb = false;
            this.pocket.game.params.sURL = Config.GAME_BASE_URL;
            this.pocket.game.params.sBG = this.pocket.version.sBG;
            this.pocket.game.params.isEU = false;
            this.pocket.game.params.doSignup = false;
            this.pocket.game.params.loginURL = Config.API_LOGIN_URL;
            this.pocket.game.params.test = false;
        }

        try {
            this.pocket.stage.setChildIndex(this.pocket.game, 0);
            if (this.pocket.parent == this.pocket.stage) {
                this.pocket.stage.removeChild(this.pocket);
            }
        } catch (_:Dynamic) {}

        this.pocket.networkCore = new Network(this.pocket);

        if (this.pocket.gameCore != null) {
            this.pocket.gameCore.onFrameChange("Init");
        }

        this.pocket.advance();
    }

    override private function onProgress(progressEvent:ProgressEvent):Void {
        if (this.pocket.loadingTxt != null) {
            this.pocket.loadingTxt.text = "Loading Game " + HelperLoader.progressPercent(progressEvent) + "%";
        }
    }

    override private function onError(error:IOErrorEvent):Void {
        if (this.pocket.loadingErrorTxt != null) {
            this.pocket.loadingErrorTxt.htmlText =
                "Failed to load the game client.\n" +
                "Your installation may be <font color='#FFCC00'>corrupt or incomplete</font>.\n\n" +
                "Try <font color='#FFCC00'>reinstalling the launcher</font> to fix this.\n\n" +
                "<font color='#888888'>Error: " + error.text + "</font>";
        }

        if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
            this.pocket.overlay.debug.logError("Game load failed: " + error.text);
        }
    }
}
