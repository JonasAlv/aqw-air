package load.handlers;

import data.Release;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import haxe.Json;
import load.Load;
import util.HelperLoader;

@:native("load.handlers.UpdateLoad")
class UpdateLoad extends Load {
    public function new(pocket:Dynamic) {
        super(pocket);
    }

    override public function start():Void {
        this.url = Config.GITHUB_RELEASES_URL;
        super.start();
    }

    override private function load():Void {
        var urlLoader = new URLLoader(new URLRequest(this.url));
        urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
        urlLoader.addEventListener(Event.COMPLETE, this.onCompleted, false, 0, true);
        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, this.onError, false, 0, true);
    }

    override private function onCompleted(event:Event):Void {
        try {
            var loader:URLLoader = cast(event.target, URLLoader);
            this.pocket.release = new Release(Json.parse(loader.data));

            var latest:String = this.pocket.release.tag_name;
            var current:String = Config.APP_VERSION;

            if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
                this.pocket.overlay.debug.log("Update fetched");
                this.pocket.overlay.debug.log("Latest: " + latest);
                this.pocket.overlay.debug.log("Current: " + current);
            }

            if (latest != current) {
                if (this.pocket.overlay != null) {
                    this.pocket.overlay.notification("Update available <font color='#f0c040'>" + latest + "</font> <a href='" + this.pocket.release.html_url + "'><font color='#6ec6ff'><u>DOWNLOAD</u></font></a>");
                }
                if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
                    this.pocket.overlay.debug.log("New release available: " + latest + " (" + this.pocket.release.html_url + ")");
                }
            } else {
                if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
                    this.pocket.overlay.debug.log("App is up to date.");
                }
            }
        } catch (error:Dynamic) {
            if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
                this.pocket.overlay.debug.logError("Failed to parse release response: " + Std.string(error));
            }
        }

        this.pocket.advance();
    }

    override private function onProgress(progressEvent:ProgressEvent):Void {
        if (this.pocket.loadingTxt != null) {
            this.pocket.loadingTxt.text = "Checking for updates… " + HelperLoader.progressPercent(progressEvent) + "%";
        }
    }

    override private function onError(error:IOErrorEvent):Void {
        if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
            this.pocket.overlay.debug.logError("Update check failed: " + error.text);
            this.pocket.overlay.notification("Could not check for updates. Check your connection.");
        }
        this.pocket.advance();
    }
}
