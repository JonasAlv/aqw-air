package load.handlers;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import load.Load;
import util.HelperLoader;

@:native("load.handlers.BackgroundLoad")
class BackgroundLoad extends Load {
    public function new(pocket:Dynamic) {
        super(pocket);
    }

    override public function start():Void {
        if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
            this.pocket.overlay.debug.log("Loading background: " + this.pocket.version.sBG);
        }

        if (this.pocket.loadingTxt != null) {
            this.pocket.loadingTxt.text = "Loading Background...";
        }

        this.url = Config.GAME_BASE_URL + "gamefiles/title/" + this.pocket.version.sBG;
        super.start();
    }

    override private function onCompleted(event:Event):Void {
        try {
            var TitleScreenClass:Dynamic = this.domain.getDefinition("TitleScreen");
            if (TitleScreenClass != null) {
                var titleScreen:DisplayObject = Type.createInstance(TitleScreenClass, []);
                titleScreen.x = 0;
                titleScreen.y = 0;

                while (this.pocket.background.numChildren > 0) {
                    this.pocket.background.removeChildAt(0);
                }

                this.pocket.background.addChild(titleScreen);
            }
        } catch (error:Dynamic) {
            if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
                this.pocket.overlay.debug.logError("Failed to instantiate background: " + Std.string(error));
            }
        }

        this.pocket.advance();
    }

    override private function onProgress(progressEvent:ProgressEvent):Void {
        if (this.pocket.loadingTxt != null) {
            this.pocket.loadingTxt.text = "Loading Background " + HelperLoader.progressPercent(progressEvent) + "%";
        }
    }

    override private function onError(error:IOErrorEvent):Void {
        if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
            this.pocket.overlay.debug.logError("Background load failed: " + error.text);
        }
        this.pocket.advance();
    }
}
