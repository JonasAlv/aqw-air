package load;

import flash.display.Loader;
import flash.errors.IllegalOperationError;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import util.HelperLoader;

@:native("load.Load")
class Load {
    public var domain:ApplicationDomain;
    public var context:LoaderContext;

    private var pocket:Dynamic;
    private var url:String = "";

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
        this.domain = new ApplicationDomain();
        this.context = new LoaderContext(false, this.domain);
        this.context.allowCodeImport = true;
    }

    public function start():Void {
        this.load();
    }

    private function load():Void {
        LoadManager.load(new Loader(), this.url, this.context, this.onCompleted, this.onProgress, this.onError);
    }

    private function onCompleted(event:Event):Void {
        throw new IllegalOperationError("Must override onCompleted Function");
    }

    private function onProgress(event:ProgressEvent):Void {
        throw new IllegalOperationError("Must override onProgress Function");
    }

    private function onError(error:IOErrorEvent):Void {
        throw new IllegalOperationError("Must override onError Function");
    }
}
