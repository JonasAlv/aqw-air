package load.handlers;

import data.Version;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import haxe.Json;
import load.Load;
import util.HelperLoader;

@:native("load.handlers.VersionLoad")
class VersionLoad extends Load {
    public function new(pocket:Dynamic) {
        super(pocket);
    }

    override public function start():Void {
        this.url = Config.API_VERSION_URL;
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
            var rawData:Dynamic = Json.parse(loader.data);
            this.pocket.version = new Version(rawData);

            var backgrounds = [
                "DageScorn.swf",
                "Mirror2.swf",
                "ravenloss2.swf",
                "EtherstormPlague.swf",
                "BrightFallCommanderTitle.swf",
                this.pocket.version.sBG
            ];

            this.pocket.version.sBG = backgrounds[Math.floor(Math.random() * backgrounds.length)];

            if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
                this.pocket.overlay.debug.log("Version fetched");
                this.pocket.overlay.debug.log("File: " + this.pocket.version.sFile);
                this.pocket.overlay.debug.log("Title: " + this.pocket.version.sTitle);
                this.pocket.overlay.debug.log("Background: " + this.pocket.version.sBG);
                this.pocket.overlay.debug.log("Version: " + this.pocket.version.sVersion);
            }

            this.pocket.advance();
        } catch (error:Dynamic) {
            if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
                this.pocket.overlay.debug.logError("Failed to parse version response: " + Std.string(error));
            }
        }
    }

    override private function onProgress(progressEvent:ProgressEvent):Void {
        if (this.pocket.loadingTxt != null) {
            this.pocket.loadingTxt.text = "API " + HelperLoader.progressPercent(progressEvent) + "%";
        }
    }

    override private function onError(error:IOErrorEvent):Void {
        if (this.pocket.loadingErrorTxt != null) {
            this.pocket.loadingErrorTxt.htmlText =
                "Version load failed. Check your internet connection and try again.\n\n" +
                "1. Open your browser, visit <font color='#FFCC00'><a href='https://www.aq.com'>www.aq.com</a></font> then relaunch the game.\n" +
                "2. Disable your <font color='#FFCC00'>VPN or proxy</font> if you are using one.\n" +
                "3. Restart your <font color='#FFCC00'>modem/router</font> to get a fresh IP.\n\n" +
                "<font color='#888888'>Error: " + error.text + "</font>";
        }

        if (this.pocket.overlay != null && this.pocket.overlay.debug != null) {
            this.pocket.overlay.debug.logError("Version load failed: " + error.text);
        }
    }
}
