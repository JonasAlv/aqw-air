package worker;

#if flash
import flash.display.Sprite;
import flash.events.Event;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.utils.ByteArray;

class WorkerMain extends Sprite {
    public function new() {
        super();
        var curWorker:Worker = Worker.current;
        if (curWorker == null || curWorker.isPrimordial) {
            return;
        }

        var fromMain:MessageChannel = cast curWorker.getSharedProperty("toWorker");
        var toMain:MessageChannel = cast curWorker.getSharedProperty("fromWorker");

        if (fromMain != null && toMain != null) {
            fromMain.addEventListener(Event.CHANNEL_MESSAGE, function(e:Event):Void {
                while (fromMain.messageAvailable) {
                    var job:Dynamic = fromMain.receive();
                    if (job == null) continue;

                    var type:String = (Reflect.hasField(job, "type")) ? job.type : "strip_swf";
                    var resultBytes:ByteArray = null;
                    var errorMsg:String = null;
                    var responseData:Dynamic = null;

                    try {
                        switch (type) {
                            case "strip_swf":
                                var bytes:ByteArray = cast job.bytes;
                                var stripAnim:Bool = job.stripAnimation;
                                var stripFilt:Bool = job.stripFilters;
                                resultBytes = SWFStripper.process(bytes, stripAnim, stripFilt);

                            case "parse_json":
                                var rawStr:String = Std.string(job.data);
                                responseData = haxe.Json.parse(rawStr);

                            case "ping":
                                responseData = "pong";

                            default:
                                errorMsg = "Unknown job type: " + type;
                        }
                    } catch (err:Dynamic) {
                        errorMsg = Std.string(err);
                    }

                    toMain.send({
                        id: job.id,
                        bytes: resultBytes,
                        data: responseData,
                        error: errorMsg
                    });
                }
            });
        }
    }

    public static function main() {
        new WorkerMain();
    }
}
#else
class WorkerMain {
    public static function main() {}
}
#end
