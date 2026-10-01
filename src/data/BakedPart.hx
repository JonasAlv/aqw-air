package data;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.MovieClip;
import flash.Vector;

class BakedPart {
    public var part:MovieClip;
    public var bitmap:Bitmap;
    public var frames:Vector<BitmapData>;
    public var isTimeline:Bool;
    public var currentFrame:Float = 0;

    public function new(part:MovieClip, bitmap:Bitmap, frames:Vector<BitmapData>, isTimeline:Bool) {
        this.part = part;
        this.bitmap = bitmap;
        this.frames = frames;
        this.isTimeline = isTimeline;
    }
}
