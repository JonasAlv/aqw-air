package data;

import flash.display.Sprite;
import ui.util.Handle;

class WidgetEntry {
    public var id:String;
    public var target:Sprite;
    public var defaultPositionX:Float;
    public var defaultPositionY:Float;
    public var defaultScaleX:Float;
    public var defaultScaleY:Float;
    public var handle:Handle;

    public function new(id:String, target:Sprite, defaultPositionX:Float, defaultPositionY:Float, defaultScaleX:Float, defaultScaleY:Float) {
        this.id = id;
        this.target = target;
        this.defaultPositionX = defaultPositionX;
        this.defaultPositionY = defaultPositionY;
        this.defaultScaleX = defaultScaleX;
        this.defaultScaleY = defaultScaleY;
    }
}
