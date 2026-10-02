package load;

#if flash
import flash.utils.ByteArray;
import flash.events.Event;
import flash.events.IOErrorEvent;

class SWFCache {
    private static var _memoryCache:Map<String, ByteArray> = new Map<String, ByteArray>();
    private static var _generation:Int = 0;
    private static var _enabled:Bool = true;
    private static var _writeQueue:Array<String> = [];
    private static var _queuedWrites:Map<String, Dynamic> = new Map<String, Dynamic>();
    private static var _writeInProgress:Bool = false;
    private static var _deleteWhenIdle:Bool = false;

    public static inline var CACHE_DIR_NAME:String = "cache/swf";

    public static function isEnabled():Bool {
        return _enabled;
    }

    public static function setEnabled(val:Bool):Void {
        _enabled = val;
    }

    private static function remember(key:String, bytes:ByteArray):Void {
        if (bytes == null || bytes.length == 0) return;
        bytes.position = 0;
        _memoryCache.set(key, bytes);
    }

    private static function cloneMemoryEntry(key:String):ByteArray {
        var cached:ByteArray = _memoryCache.get(key);
        if (cached == null) return null;
        var clone:ByteArray = new ByteArray();
        cached.position = 0;
        cached.readBytes(clone);
        clone.position = 0;
        return clone;
    }

    private static function sanitizeKey(url:String):String {
        if (url == null) return null;
        return "swf_" + haxe.crypto.Md5.encode(url) + ".swf";
    }

    private static function getCacheDir():Dynamic {
        try {
            var fileCls:Dynamic = untyped __global__["flash.filesystem.File"];
            if (fileCls != null && fileCls.applicationStorageDirectory != null) {
                return fileCls.applicationStorageDirectory.resolvePath(CACHE_DIR_NAME);
            }
        } catch (_:Dynamic) {}
        return null;
    }

    private static function finishDiskWrite(fs:Dynamic, continueQueue:Bool = true):Void {
        if (fs != null) {
            try {
                fs.close();
            } catch (error:Dynamic) {
                trace("SWF cache close failed: " + Std.string(error));
            }
        }
        _writeInProgress = false;
        if (_deleteWhenIdle) {
            _deleteWhenIdle = false;
            deleteCacheDirectory();
        }
        if (continueQueue) writeNextToDisk();
    }

    private static function deleteCacheDirectory():Void {
        try {
            var cacheDir:Dynamic = getCacheDir();
            if (cacheDir != null && cacheDir.exists) cacheDir.deleteDirectory(true);
        } catch (error:Dynamic) {
            trace("SWF cache clear failed: " + Std.string(error));
        }
    }

    private static function enqueueDiskWrite(key:String, bytes:ByteArray):Void {
        var queued = _queuedWrites.get(key);
        var snapshot:ByteArray = new ByteArray();
        bytes.position = 0;
        bytes.readBytes(snapshot, 0, bytes.length);
        snapshot.position = 0;
        bytes.position = 0;

        if (queued != null) {
            queued.bytes = snapshot;
            queued.generation = _generation;
        } else {
            _queuedWrites.set(key, { bytes: snapshot, generation: _generation });
            _writeQueue.push(key);
        }
        writeNextToDisk();
    }

    private static function writeNextToDisk():Void {
        if (_writeInProgress) return;
        while (_writeQueue.length > 0) {
            var key:String = _writeQueue.shift();
            var write:Dynamic = _queuedWrites.get(key);
            _queuedWrites.remove(key);
            if (write == null || write.generation != _generation || !_enabled) continue;

            var fs:Dynamic = null;
            try {
                var cacheDir:Dynamic = getCacheDir();
                if (cacheDir == null) continue;
                if (!cacheDir.exists) cacheDir.createDirectory();

                var targetFile:Dynamic = cacheDir.resolvePath(key);
                var fsCls:Dynamic = untyped __global__["flash.filesystem.FileStream"];
                var fmCls:Dynamic = untyped __global__["flash.filesystem.FileMode"];
                if (fsCls == null || fmCls == null) continue;

                fs = Type.createInstance(fsCls, []);
                _writeInProgress = true;
                if (Reflect.isFunction(Reflect.field(fs, "openAsync"))) {
                    var generation:Int = write.generation;
                    fs.addEventListener(Event.OPEN, function(e:Event):Void {
                        if (generation != _generation || !_enabled) {
                            finishDiskWrite(fs);
                            return;
                        }
                        try {
                            var bytes:ByteArray = cast write.bytes;
                            bytes.position = 0;
                            fs.writeBytes(bytes, 0, bytes.length);
                            finishDiskWrite(fs);
                        } catch (error:Dynamic) {
                            trace("SWF cache write failed for " + key + ": " + Std.string(error));
                            finishDiskWrite(fs);
                        }
                    });
                    fs.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):Void {
                        trace("SWF cache write failed for " + key + ": " + e.text);
                        finishDiskWrite(fs);
                    });
                    fs.openAsync(targetFile, fmCls.WRITE);
                    return;
                }

                fs.open(targetFile, fmCls.WRITE);
                var bytes:ByteArray = cast write.bytes;
                bytes.position = 0;
                fs.writeBytes(bytes, 0, bytes.length);
                finishDiskWrite(fs, false);
            } catch (error:Dynamic) {
                trace("SWF cache write failed for " + key + ": " + Std.string(error));
                if (fs != null) finishDiskWrite(fs, false);
                else _writeInProgress = false;
            }
        }
    }

    /**
     * Attempts to retrieve cached SWF bytes from RAM or local storage.
     * Returns null on cache miss.
     */
    public static function get(url:String):ByteArray {
        if (!_enabled || url == null || url.length == 0) return null;
        // Don't cache local app:/ assets (they are already on local disk)
        if (StringTools.startsWith(url, "app:/")) return null;

        var key:String = sanitizeKey(url);
        if (key == null) return null;

        // 1. Hot RAM Cache
        var hotBytes:ByteArray = cloneMemoryEntry(key);
        if (hotBytes != null) return hotBytes;

        // 2. Persistent Disk Cache
        try {
            var cacheDir:Dynamic = getCacheDir();
            if (cacheDir != null) {
                var targetFile:Dynamic = cacheDir.resolvePath(key);
                if (targetFile != null && targetFile.exists) {
                    var fsCls:Dynamic = untyped __global__["flash.filesystem.FileStream"];
                    var fmCls:Dynamic = untyped __global__["flash.filesystem.FileMode"];
                    if (fsCls != null && fmCls != null) {
                        var fs:Dynamic = Type.createInstance(fsCls, []);
                        fs.open(targetFile, fmCls.READ);
                        var diskBytes:ByteArray = new ByteArray();
                        fs.readBytes(diskBytes);
                        fs.close();

                        diskBytes.position = 0;
                        remember(key, diskBytes);

                        var outClone:ByteArray = new ByteArray();
                        diskBytes.position = 0;
                        diskBytes.readBytes(outClone);
                        outClone.position = 0;
                        return outClone;
                    }
                }
            }
        } catch (_:Dynamic) {}

        return null;
    }

    public static function getAsync(url:String, onDone:ByteArray->Void):Void {
        if (onDone == null) return;
        if (!_enabled || url == null || url.length == 0 || StringTools.startsWith(url, "app:/")) {
            onDone(null);
            return;
        }

        var key:String = sanitizeKey(url);
        if (key == null) {
            onDone(null);
            return;
        }

        var hotBytes:ByteArray = cloneMemoryEntry(key);
        if (hotBytes != null) {
            onDone(hotBytes);
            return;
        }

        try {
            var cacheDir:Dynamic = getCacheDir();
            if (cacheDir == null) {
                onDone(null);
                return;
            }
            var targetFile:Dynamic = cacheDir.resolvePath(key);
            if (targetFile == null || !targetFile.exists) {
                onDone(null);
                return;
            }

            var fsCls:Dynamic = untyped __global__["flash.filesystem.FileStream"];
            var fmCls:Dynamic = untyped __global__["flash.filesystem.FileMode"];
            if (fsCls == null || fmCls == null) {
                onDone(get(url));
                return;
            }

            var fs:Dynamic = Type.createInstance(fsCls, []);
            if (!Reflect.isFunction(Reflect.field(fs, "openAsync"))) {
                onDone(get(url));
                return;
            }

            var generation:Int = _generation;
            var completed:Bool = false;
            var finish = function(bytes:ByteArray):Void {
                if (completed) return;
                completed = true;
                try {
                    fs.close();
                } catch (_:Dynamic) {}
                if (generation != _generation || !_enabled) {
                    onDone(null);
                    return;
                }
                if (bytes != null && bytes.length > 0) {
                    bytes.position = 0;
                    remember(key, bytes);
                    var cachedBytes:ByteArray = cloneMemoryEntry(key);
                    if (cachedBytes != null) {
                        onDone(cachedBytes);
                    } else {
                        bytes.position = 0;
                        onDone(bytes);
                    }
                } else {
                    onDone(null);
                }
            };

            fs.addEventListener(Event.COMPLETE, function(e:Event):Void {
                try {
                    var available:Int = Std.int(fs.bytesAvailable);
                    if (available <= 0) {
                        finish(null);
                        return;
                    }
                    fs.position = 0;
                    var diskBytes:ByteArray = new ByteArray();
                    fs.readBytes(diskBytes, 0, available);
                    diskBytes.position = 0;
                    finish(diskBytes);
                } catch (error:Dynamic) {
                    trace("SWF cache read failed: " + Std.string(error));
                    finish(null);
                }
            });
            fs.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):Void {
                trace("SWF cache read failed: " + e.text);
                finish(null);
            });
            fs.openAsync(targetFile, fmCls.READ);
        } catch (error:Dynamic) {
            trace("SWF cache read failed: " + Std.string(error));
            onDone(null);
        }
    }

    /**
     * Stores SWF bytes into hot RAM cache and writes asynchronously to disk.
     */
    public static function put(url:String, bytes:ByteArray):Void {
        if (!_enabled || url == null || bytes == null || bytes.length == 0) return;
        if (StringTools.startsWith(url, "app:/")) return;

        var key:String = sanitizeKey(url);
        if (key == null) return;

        // Store in RAM
        var ramCopy:ByteArray = new ByteArray();
        bytes.position = 0;
        bytes.readBytes(ramCopy);
        ramCopy.position = 0;
        bytes.position = 0;
        remember(key, ramCopy);

        enqueueDiskWrite(key, ramCopy);
    }

    /**
     * Clears both hot RAM cache and local disk cache.
     */
    public static function clear():Void {
        _memoryCache = new Map<String, ByteArray>();
        _generation++;
        _writeQueue = [];
        _queuedWrites = new Map<String, Dynamic>();
        if (_writeInProgress) _deleteWhenIdle = true;
        else deleteCacheDirectory();
    }

    /**
     * Calculates total bytes cached on disk.
     */
    public static function getDiskSizeFormatted():String {
        try {
            var cacheDir:Dynamic = getCacheDir();
            if (cacheDir != null && cacheDir.exists) {
                var totalBytes:Float = 0;
                var files:Array<Dynamic> = cacheDir.getDirectoryListing();
                if (files != null) {
                    for (f in files) {
                        if (f != null && f.size != null) {
                            totalBytes += f.size;
                        }
                    }
                }

                if (totalBytes <= 0) return "0 MB";
                var mb:Float = totalBytes / (1024 * 1024);
                return (Math.round(mb * 10) / 10) + " MB";
            }
        } catch (_:Dynamic) {}
        return "0 MB";
    }
}
#else
class SWFCache {
    public static function get(url:String):Dynamic return null;
    public static function put(url:String, bytes:Dynamic):Void {}
    public static function clear():Void {}
    public static function getDiskSizeFormatted():String return "0 MB";
    public static function isEnabled():Bool return false;
    public static function setEnabled(val:Bool):Void {}
}
#end
