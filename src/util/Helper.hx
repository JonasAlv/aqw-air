package util;

import flash.filters.ColorMatrixFilter;

class Helper {
    public static var GRAYSCALE:ColorMatrixFilter = new ColorMatrixFilter([
        0.3, 0.59, 0.11, 0.0, 0.0,
        0.3, 0.59, 0.11, 0.0, 0.0,
        0.3, 0.59, 0.11, 0.0, 0.0,
        0.0, 0.0,  0.0,  1.0, 0.0
    ]);

    public static var ORIENTATIONS:Array<Dynamic> = [
        "default",
        "default",
        "rotatedLeft",
        "rotatedRight",
        "upsideDown"
    ];

    public static var RASTERIZER_LEVELS:Array<Float> = [
        1.0,
        1.5,
        2.0,
        3.0,
        0.5,
        0.1
    ];

    public static function sanitize(s:String):String {
        if (s == null) return "";
        var r = ~/[^a-zA-Z0-9]/g;
        return r.replace(s, "_");
    }

    public static function trimUrl(str:String):String {
        if (str == null || str.length == 0) {
            return str;
        }

        var end:Int = str.length - 1;

        if (StringTools.fastCodeAt(str, end) > 32) {
            return str;
        }

        while (end >= 0 && StringTools.fastCodeAt(str, end) <= 32) {
            end--;
        }

        return str.substring(0, end + 1);
    }

    public static function capitalizeFirstLetter(text:String):String {
        if (text == null || text.length == 0) return text;
        return text.charAt(0).toUpperCase() + text.substr(1);
    }
}
