package load;

import data.CategoryMap;
import data.LoadData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;
import util.HelperLoader;
import util.SWFWorkerClient;

@:native("load.LoadManager")
class LoadManager {
    public static inline var MAX_CONCURRENT:Int = 15;

    public static inline var KIND_NO_QUEUE:String = "no_queue";
    public static inline var KIND_STATIC:String = "static";
    public static inline var KIND_MAP:String = "map";
    public static inline var KIND_AVATAR:String = "avatar";

    private static var _CATEGORY_MAP:Array<CategoryMap> = null;

    private static function getCategoryMap():Array<CategoryMap> {
        if (_CATEGORY_MAP == null) {
            var getPocketConfig = function():Dynamic {
                var p = pocket.PocketRoot.SINGLETON;
                return (p != null) ? p.config : null;
            };

            _CATEGORY_MAP = [
                new CategoryMap("gamefiles/mon/", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_monster_off;
                }),
                new CategoryMap("gamefiles/hairs", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_hair_off;
                }),
                new CategoryMap("gamefiles/classes", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_armor_off;
                }),
                new CategoryMap("gamefiles/items/helms", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_helm_off;
                }),
                new CategoryMap("gamefiles/items/capes", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_cape_off;
                }),
                new CategoryMap("gamefiles/items/grounds", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_misc_off;
                }),
                new CategoryMap("gamefiles/items/pets", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_pet_off;
                }),
                new CategoryMap("gamefiles/items/swords", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/maces", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/gauntlets", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/daggers", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/polearms", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/guns", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/staves", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/scythes", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/axes", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/bows", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                }),
                new CategoryMap("gamefiles/items/whips", function():Bool {
                    var c = getPocketConfig();
                    return c != null && c.option_animation_weapon_off;
                })
            ];
        }
        return _CATEGORY_MAP;
    }

    public var applicationDomainStatic:ApplicationDomain;
    public var applicationDomainMap:ApplicationDomain;
    public var applicationDomainAvatar:ApplicationDomain;

    private var loaderContextStatic:LoaderContext;
    private var loaderContextMap:LoaderContext;
    private var loaderContextAvatar:LoaderContext;

    private var queue:Array<LoadData> = [];
    private var concurrentCount:Int = 0;
    private var loaderStack:Map<String, Dynamic> = new Map<String, Dynamic>();

    public function new() {
        applicationDomainStatic = new ApplicationDomain(ApplicationDomain.currentDomain);
        applicationDomainMap = new ApplicationDomain(ApplicationDomain.currentDomain);
        applicationDomainAvatar = new ApplicationDomain(ApplicationDomain.currentDomain);

        loaderContextStatic = new LoaderContext(false, applicationDomainStatic);
        loaderContextMap = new LoaderContext(false, applicationDomainMap);
        loaderContextAvatar = new LoaderContext(false, applicationDomainAvatar);

        HelperLoader.prepareContext(loaderContextStatic);
        HelperLoader.prepareContext(loaderContextMap);
        HelperLoader.prepareContext(loaderContextAvatar);
    }

    public static function load(loader:Loader, url:String, context:LoaderContext, onComplete:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null, onHTTPError:Dynamic = null):Void {
        var p = pocket.PocketRoot.SINGLETON;
        if (p != null && p.loadManager != null) {
            p.loadManager.loadDirect(loader, url, context, onComplete, onProgress, onError, onHTTPError);
        }
    }

    public function loadDirect(loader:Loader, url:String, context:LoaderContext, onComplete:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null, onHTTPError:Dynamic = null):Void {
        HelperLoader.prepareContext(context);
        onLoad(new LoadData(KIND_NO_QUEUE, null, loader, context, url, onComplete, onProgress, onError, onHTTPError, false));
    }

    public function loadStatic(url:String, key:String, onComplete:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
        queue.push(new LoadData(KIND_STATIC, key, null, loaderContextStatic, url, onComplete, onProgress, onError));
        loadNext();
    }

    public function loadMap(url:String, key:String, onComplete:Dynamic, onProgress:Dynamic = null, onError:Dynamic = null):Void {
        queue.push(new LoadData(KIND_MAP, key, null, loaderContextMap, url, onComplete, onProgress, onError));
        loadNext();
    }

    public function loadAvatar(url:String, key:String, onComplete:Dynamic, onError:Dynamic = null):Void {
        queue.push(new LoadData(KIND_AVATAR, key, null, loaderContextAvatar, url, onComplete, null, onError));
        loadNext();
    }

    public function clearLoader(key:String):Void {
        if (!loaderStack.exists(key)) return;

        try {
            var entry:Dynamic = loaderStack.get(key);
            if (entry != null && entry.loader != null) {
                var ldr:Loader = cast(entry.loader, Loader);
                ldr.unloadAndStop();
            }
        } catch (_:Dynamic) {}

        loaderStack.remove(key);
    }

    public function clearLoaderByKind(kind:String):Void {
        for (key in loaderStack.keys()) {
            var entry:Dynamic = loaderStack.get(key);
            if (entry != null && entry.kind == kind) {
                try {
                    if (entry.loader != null) {
                        var ldr:Loader = cast(entry.loader, Loader);
                        ldr.unloadAndStop();
                    }
                } catch (_:Dynamic) {}
                loaderStack.remove(key);
            }
        }
    }

    private function resolveCategoryCheck(url:String):Void->Bool {
        if (url == null) return null;
        var lowerUrl = url.toLowerCase();
        for (entry in getCategoryMap()) {
            if (lowerUrl.indexOf(entry.pattern) > -1) {
                return entry.check;
            }
        }
        return null;
    }

    private function createFinishLoad(loadData:LoadData):ByteArray->Void {
        return function(finalBytes:ByteArray):Void {
            var byteLoader:Loader = (loadData.loader == null) ? new Loader() : loadData.loader;

            if (finalBytes == null || finalBytes.length == 0) {
                var errorEvent:IOErrorEvent = new IOErrorEvent(
                    IOErrorEvent.IO_ERROR,
                    false,
                    false,
                    "Received empty SWF data for " + loadData.url
                );
                if (loadData.onError != null) {
                    try {
                        loadData.onError(errorEvent);
                    } catch (error:Dynamic) {
                        trace("Failed to load empty SWF data: " + Std.string(error));
                    }
                } else if (loadData.loader != null) {
                    try {
                        loadData.loader.dispatchEvent(errorEvent);
                    } catch (error:Dynamic) {
                        trace("Failed to dispatch empty SWF error: " + Std.string(error));
                    }
                }
                if (loadData.isQueued) {
                    concurrentCount--;
                    loadNext();
                }
                return;
            }

            if (loadData.isQueued) {
                byteLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):Void {
                    try {
                        if (loadData.onComplete != null) {
                            loadData.onComplete(e);
                        }
                        if (loadData.key != null) {
                            clearLoader(loadData.key);
                            loaderStack.set(loadData.key, {
                                kind: loadData.kind,
                                loader: byteLoader
                            });
                        }
                    } catch (error:Dynamic) {
                        trace("Failed to load: " + Std.string(error));
                    }

                    concurrentCount--;
                    loadNext();
                });

                if (loadData.onHTTPError != null) {
                    byteLoader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, loadData.onHTTPError);
                }

                byteLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):Void {
                    if (loadData.onError != null) {
                        try {
                            loadData.onError(event);
                        } catch (error:Dynamic) {
                            trace("Failed to load bytes: " + Std.string(error));
                        }
                    }
                    concurrentCount--;
                    loadNext();
                });
            } else {
                if (loadData.onComplete != null) {
                    byteLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadData.onComplete);
                }
                if (loadData.onHTTPError != null) {
                    byteLoader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, loadData.onHTTPError);
                }
                byteLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):Void {
                    if (loadData.onError != null) {
                        loadData.onError(event);
                        return;
                    }
                    try {
                        byteLoader.dispatchEvent(event);
                    } catch (_:Dynamic) {}
                });
            }

            var targetBytes:ByteArray = finalBytes;
            try {
                if (finalBytes != null && untyped finalBytes.shareable == true) {
                    targetBytes = new ByteArray();
                    finalBytes.position = 0;
                    finalBytes.readBytes(targetBytes, 0, finalBytes.length);
                    targetBytes.position = 0;
                }
            } catch (_:Dynamic) {}
            if (targetBytes != null) targetBytes.position = 0;

            try {
                byteLoader.loadBytes(targetBytes, loadData.context);
            } catch (e:Dynamic) {
                trace("loadBytes error: " + Std.string(e));
                if (loadData.isQueued) {
                    concurrentCount--;
                    loadNext();
                }
            }
        };
    }

    private function onLoad(loadData:LoadData):Void {
        var finishLoad = createFinishLoad(loadData);

        var categoryCheck = resolveCategoryCheck(loadData.url);
        var p = pocket.PocketRoot.SINGLETON;
        var config:Dynamic = (p != null) ? p.config : null;
        var isMapAsset:Bool = loadData.kind == KIND_MAP;
        var animationOn:Bool = (categoryCheck != null && categoryCheck())
            || (isMapAsset && config != null && config.option_animation_map_off);
        var filterOn:Bool = (categoryCheck != null && config != null && config.option_filter_off);
        var soundStripOn:Bool = (config != null && config.option_sound_off);

        var processBytes = function(rawBytes:ByteArray):Void {
            if (animationOn || filterOn || soundStripOn) {
                SWFWorkerClient.instance.process(rawBytes, animationOn, filterOn, soundStripOn, finishLoad, loadData.url);
            } else {
                finishLoad(rawBytes);
            }
        };

        SWFCache.getAsync(loadData.url, function(cachedBytes:ByteArray):Void {
            if (cachedBytes != null) {
                processBytes(cachedBytes);
            } else {
                loadRemote(loadData, processBytes);
            }
        });
    }

    private function loadRemote(loadData:LoadData, processBytes:ByteArray->Void):Void {
        var urlLoader = new URLLoader();
        urlLoader.dataFormat = URLLoaderDataFormat.BINARY;

        urlLoader.addEventListener(Event.COMPLETE, function(event:Event):Void {
            var rawBytes:ByteArray = cast(cast(event.target, URLLoader).data, ByteArray);

            if (rawBytes == null || rawBytes.length == 0) {
                var errorEvent:IOErrorEvent = new IOErrorEvent(
                    IOErrorEvent.IO_ERROR,
                    false,
                    false,
                    "Received empty SWF response for " + loadData.url
                );
                if (loadData.onError != null) {
                    try {
                        loadData.onError(errorEvent);
                    } catch (error:Dynamic) {
                        trace("Failed to handle empty SWF response: " + Std.string(error));
                    }
                } else if (loadData.loader != null) {
                    loadData.loader.dispatchEvent(errorEvent);
                }
                if (loadData.isQueued) {
                    concurrentCount--;
                    loadNext();
                }
                return;
            }

            // Store downloaded bytes into hot RAM & local disk cache
            SWFCache.put(loadData.url, rawBytes);
            processBytes(rawBytes);
        });

        if (loadData.onProgress != null) {
            urlLoader.addEventListener(ProgressEvent.PROGRESS, loadData.onProgress);
        }

        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):Void {
            if (loadData.onError != null) {
                if (loadData.isQueued) {
                    try {
                        loadData.onError(event);
                    } catch (error:Dynamic) {
                        trace("Failed to load URL: " + Std.string(error));
                    }
                } else {
                    loadData.onError(event);
                }
            } else if (!loadData.isQueued && loadData.loader != null) {
                try {
                    loadData.loader.dispatchEvent(event);
                } catch (_:Dynamic) {}
            }

            if (loadData.isQueued) {
                concurrentCount--;
                loadNext();
            }
        });

        urlLoader.load(HelperLoader.buildRequest(loadData.url));
    }

    private function loadNext():Void {
        if (queue.length <= 0 || concurrentCount >= MAX_CONCURRENT) {
            return;
        }

        concurrentCount++;
        onLoad(queue.shift());
    }
}
