package controller.walk;

import flash.errors.IllegalOperationError;

class WalkController {
    public var pocket:Dynamic;
    public var frameTick:Int = 0;

    public function new(pocket:Dynamic) {
        this.pocket = pocket;
    }

    public function update():Void {
        throw new IllegalOperationError("Must override update Function");
    }

    public function stop():Void {
        throw new IllegalOperationError("Must override stop Function");
    }
}
