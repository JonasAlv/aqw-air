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

                    var resultBytes:ByteArray = null;
                    var errorMsg:String = null;

                    try {
                        var bytes:ByteArray = cast job.bytes;
                        var stripAnim:Bool = (job.stripAnimation == true);
                        var stripFilt:Bool = (job.stripFilters == true);
                        var stripSound:Bool = (job.stripSounds == true);
                        resultBytes = SWFStripper.process(bytes, stripAnim, stripFilt, stripSound);
                    } catch (err:Dynamic) {
                        errorMsg = Std.string(err);
                    }

                    toMain.send({
                        id: job.id,
                        bytes: resultBytes,
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
