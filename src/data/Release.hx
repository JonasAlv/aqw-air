package data;

class Release extends Data {
    public var tag_name:String = "";
    public var html_url:String = "";

    public function new(?obj:Dynamic) {
        super(obj);
    }
}
