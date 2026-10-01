package data;

class Action {
    public var name:String;
    public var onClick:Dynamic->Void;

    public function new(name:String, ?onClick:Dynamic->Void) {
        this.name = name;
        this.onClick = onClick;
    }
}
