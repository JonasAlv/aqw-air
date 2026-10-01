package data;

class Data {
    public function new(?obj:Dynamic) {
        if (obj != null) {
            fromObject(obj);
        }
    }

    public function fromObject(obj:Dynamic):Void {
        if (obj == null) return;
        for (p in Reflect.fields(obj)) {
            var val = Reflect.field(obj, p);
            if (Reflect.hasField(this, p)) {
                var cur = Reflect.field(this, p);
                if (Std.isOfType(cur, Bool)) {
                    var sVal:String = Std.string(val);
                    var bVal:Bool = (sVal != "false" && sVal != "0" && sVal != "null" && sVal != "");
                    Reflect.setField(this, p, bVal);
                } else {
                    Reflect.setField(this, p, val);
                }
            }
        }
    }
}
