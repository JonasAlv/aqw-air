package data;

class CategoryMap {
    public var pattern:String;
    public var check:Void->Bool;

    public function new(pattern:String, check:Void->Bool) {
        this.pattern = pattern;
        this.check = check;
    }
}
