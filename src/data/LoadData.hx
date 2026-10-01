package data;

import flash.display.Loader;
import flash.system.LoaderContext;
import util.Helper;

class LoadData {
    public var kind:String;
    public var key:String;
    public var loader:Loader;
    public var context:LoaderContext;
    public var url:String;
    public var onComplete:Dynamic->Void;
    public var onProgress:Dynamic->Void;
    public var onError:Dynamic->Void;
    public var onHTTPError:Dynamic->Void;
    public var isQueued:Bool;

    public function new(
        kind:String,
        key:String,
        loader:Loader,
        context:LoaderContext,
        url:String,
        onComplete:Dynamic->Void,
        ?onProgress:Dynamic->Void,
        ?onError:Dynamic->Void,
        ?onHTTPError:Dynamic->Void,
        isQueued:Bool = true
    ) {
        this.kind = kind;
        this.key = key;
        this.loader = loader;
        this.context = context;
        this.url = Helper.trimUrl(url);
        this.onComplete = onComplete;
        this.onProgress = onProgress;
        this.onError = onError;
        this.onHTTPError = onHTTPError;
        this.isQueued = isQueued;
    }
}
