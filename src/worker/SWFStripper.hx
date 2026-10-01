package worker;

#if flash
import flash.utils.ByteArray;

class SWFStripper {
    public static function process(originalBytes:ByteArray, stripAnimation:Bool, stripFilters:Bool, stripSounds:Bool = false):ByteArray {
        if (originalBytes == null) return null;
        originalBytes.position = 0;

        var swfCls:Dynamic = untyped __global__["com.codeazur.as3swf.SWF"];
        if (swfCls == null) return originalBytes;

        try {
            var swf:Dynamic = untyped __new__(swfCls, originalBytes);

            stripTags(swf.tags, stripAnimation, stripFilters, stripSounds);

            if (swf.tagsRaw != null && swf.tagsRaw.length > swf.tags.length) {
                swf.tagsRaw.length = swf.tags.length;
            }

            // Fix: If original SWF was LZMA compressed, as3swf cannot publish LZMA. Fall back to ZLIB!
            try {
                if (Reflect.field(swf, "compressionMethod") == "lzma") {
                    Reflect.setField(swf, "compressionMethod", "zlib");
                }
            } catch (_:Dynamic) {}

            var newBytes:ByteArray = new ByteArray();
            // NEVER set newBytes.shareable = true! Loader.loadBytes rejects shareable ByteArrays with Error #3735.
            swf.publish(newBytes);
            newBytes.position = 0;
            return newBytes;
        } catch (e:Dynamic) {
            trace("SWFStripper error: " + Std.string(e));
            originalBytes.position = 0;
            return originalBytes;
        }
    }

    private static function stripTags(tags:Dynamic, stripAnimation:Bool, stripFilters:Bool, stripSounds:Bool):Void {
        if (tags == null) return;
        var tagFrameLabelCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagFrameLabel"];
        var tagShowFrameCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagShowFrame"];
        var tagDefineSpriteCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagDefineSprite"];
        var tagPlaceObjectCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagPlaceObject"];
        var tagRemoveObjectCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagRemoveObject"];
        var tagRemoveObject2Cls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagRemoveObject2"];
        var tagEndCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagEnd"];
        var tagDefineSoundCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagDefineSound"];
        var tagStartSoundCls:Dynamic = untyped __global__["com.codeazur.as3swf.tags.TagStartSound"];

        var hasFrameLabels:Bool = false;
        if (stripAnimation) {
            var len:Int = tags.length;
            for (i in 0...len) {
                var t = tags[i];
                if (Std.isOfType(t, tagFrameLabelCls)) {
                    hasFrameLabels = true;
                    break;
                }
            }
        }

        var shownFirstFrame:Bool = false;
        var newTags:Array<Dynamic> = (hasFrameLabels || stripSounds) ? [] : null;

        var i:Int = 0;
        while (i < tags.length) {
            var tag:Dynamic = tags[i];

            if (stripAnimation && !hasFrameLabels && Std.isOfType(tag, tagShowFrameCls)) {
                tags.length = i + 1;
                tags.push(untyped __new__(tagEndCls));
                break;
            }

            if (stripSounds && (Std.isOfType(tag, tagDefineSoundCls) || Std.isOfType(tag, tagStartSoundCls))) {
                i++;
                continue; // Strip sound tags
            }

            if (Std.isOfType(tag, tagDefineSpriteCls)) {
                stripTags(tag.tags, stripAnimation, stripFilters, stripSounds);
                if (tag.tagsRaw != null && tag.tagsRaw.length > tag.tags.length) {
                    tag.tagsRaw.length = tag.tags.length;
                }
            } else if (stripFilters && Std.isOfType(tag, tagPlaceObjectCls)) {
                if (tag.hasFilterList && tag.surfaceFilterList != null && tag.surfaceFilterList.length > 0) {
                    tag.surfaceFilterList.length = 0;
                    tag.hasFilterList = false;
                }
            }

            if (hasFrameLabels) {
                var isFrameContent:Bool = Std.isOfType(tag, tagPlaceObjectCls) || 
                                          Std.isOfType(tag, tagRemoveObjectCls) || 
                                          Std.isOfType(tag, tagRemoveObject2Cls);

                if (stripAnimation && shownFirstFrame && isFrameContent) {
                    // Stripped looping animation frames
                } else {
                    if (newTags != null) newTags.push(tag);
                }

                if (Std.isOfType(tag, tagShowFrameCls)) {
                    shownFirstFrame = true;
                }
            } else if (newTags != null) {
                newTags.push(tag);
            }

            i++;
        }

        if (newTags != null) {
            tags.length = 0;
            for (t in newTags) {
                tags.push(t);
            }
        }
    }
}
#else
class SWFStripper {
    public static function process(originalBytes:Dynamic, stripAnimation:Bool, stripFilters:Bool, stripSounds:Bool = false):Dynamic {
        return originalBytes;
    }
}
#end
