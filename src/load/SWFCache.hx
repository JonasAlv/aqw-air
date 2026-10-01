package load;

#if flash
import flash.utils.ByteArray;

class SWFCache {
    private static var _memoryCache:Map<String, ByteArray> = new Map<String, ByteArray>();
    private static var _enabled:Bool = true;

    public static inline var CACHE_DIR_NAME:String = "cache/swf";

    public static function isEnabled():Bool {
        return _enabled;
    }

    public static function setEnabled(val:Bool):Void {
        _enabled = val;
    }

    private static function sanitizeKey(url:String):String {
        if (url == null) return null;
        var clean = url;

        // Strip query string (?ver=...)
        var qIdx = clean.indexOf("?");
        if (qIdx != -1) clean = clean.substr(0, qIdx);

        // Strip protocol
        if (clean.indexOf("://") != -1) {
            clean = clean.substr(clean.indexOf("://") + 3);
        }

        // Replace illegal filesystem characters with underscores
        var safe = "";
        for (i in 0...clean.length) {
            var c = clean.charAt(i);
            if ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || (c >= "0" && c <= "9") || c == "." || c == "_") {
                safe += c;
            } else {
                safe += "_";
            }
        }

        if (!StringTools.endsWith(safe, ".swf")) {
            safe += ".swf";
        }
        return safe;
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
        if (_memoryCache.exists(key)) {
            var cached:ByteArray = _memoryCache.get(key);
            if (cached != null) {
                var clone:ByteArray = new ByteArray();
                cached.position = 0;
                cached.readBytes(clone);
                clone.position = 0;
                return clone;
            }
        }

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
                        _memoryCache.set(key, diskBytes);

                        var outClone:ByteArray = new ByteArray();
                        diskBytes.readBytes(outClone);
                        outClone.position = 0;
                        return outClone;
                    }
                }
            }
        } catch (_:Dynamic) {}

        return null;
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
        _memoryCache.set(key, ramCopy);

        // Store on local Disk
        try {
            var cacheDir:Dynamic = getCacheDir();
            if (cacheDir != null) {
                if (!cacheDir.exists) {
                    cacheDir.createDirectory();
                }
                var targetFile:Dynamic = cacheDir.resolvePath(key);
                var fsCls:Dynamic = untyped __global__["flash.filesystem.FileStream"];
                var fmCls:Dynamic = untyped __global__["flash.filesystem.FileMode"];
                if (fsCls != null && fmCls != null) {
                    var fs:Dynamic = Type.createInstance(fsCls, []);
                    fs.open(targetFile, fmCls.WRITE);
                    bytes.position = 0;
                    fs.writeBytes(bytes, 0, bytes.length);
                    fs.close();
                    bytes.position = 0;
                }
            }
        } catch (_:Dynamic) {}
    }

    /**
     * Clears both hot RAM cache and local disk cache.
     */
    public static function clear():Void {
        _memoryCache = new Map<String, ByteArray>();
        try {
            var cacheDir:Dynamic = getCacheDir();
            if (cacheDir != null && cacheDir.exists) {
                cacheDir.deleteDirectory(true);
            }
        } catch (_:Dynamic) {}
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
