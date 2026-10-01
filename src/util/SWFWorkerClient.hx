package util;

import flash.events.Event;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.utils.ByteArray;
import haxe.Timer;

@:native("util.SWFWorkerClient")
class SWFWorkerClient {
    private static var _instance:SWFWorkerClient;

    public static var instance(get, never):SWFWorkerClient;
    private static function get_instance():SWFWorkerClient {
        if (_instance == null) {
            _instance = new SWFWorkerClient();
        }
        return _instance;
    }

    private var bgWorker:Worker;
    private var toWorker:MessageChannel;
    private var fromWorker:MessageChannel;

    private var nextId:Int = 0;
    private var pending:Map<Int, Dynamic> = new Map<Int, Dynamic>();
    private inline static var TIMEOUT_MS:Int = 10000;
    public var supported:Bool = false;

    public function new() {
        supported = WorkerDomain.isSupported;
        if (!supported) return;

        try {
            var swfBytes:ByteArray = null;

            // 1. Try resolving embedded WorkerSWF class if available
            var WorkerSWFClass:Dynamic = Type.resolveClass("util.SWFWorkerClient_WorkerSWF");
            if (WorkerSWFClass != null) {
                swfBytes = cast(Type.createInstance(WorkerSWFClass, []), ByteArray);
            }

            // 2. Fallback: Try reading WorkerMain.swf from applicationDirectory
            if (swfBytes == null || swfBytes.length == 0) {
                try {
                    var fileClass:Dynamic = Type.resolveClass("flash.filesystem.File");
                    var fileStreamClass:Dynamic = Type.resolveClass("flash.filesystem.FileStream");
                    var fileModeClass:Dynamic = Type.resolveClass("flash.filesystem.FileMode");
                    if (fileClass != null && fileStreamClass != null && fileModeClass != null) {
                        var appDir = fileClass.applicationDirectory;
                        var workerFile = appDir.resolvePath("gamefiles/embed/WorkerMain.swf");
                        if (workerFile.exists) {
                            var fs = Type.createInstance(fileStreamClass, []);
                            fs.open(workerFile, fileModeClass.READ);
                            swfBytes = new ByteArray();
                            fs.readBytes(swfBytes);
                            fs.close();
                        }
                    }
                } catch (_:Dynamic) {}
            }

            if (swfBytes != null && swfBytes.length > 0) {
                bgWorker = WorkerDomain.current.createWorker(swfBytes);
                toWorker = Worker.current.createMessageChannel(bgWorker);
                fromWorker = bgWorker.createMessageChannel(Worker.current);

                bgWorker.setSharedProperty("toWorker", toWorker);
                bgWorker.setSharedProperty("fromWorker", fromWorker);

                fromWorker.addEventListener(Event.CHANNEL_MESSAGE, onWorkerMessage);
                bgWorker.start();
            } else {
                supported = false;
            }
        } catch (e:Dynamic) {
            supported = false;
        }
    }

    public function process(bytes:ByteArray, stripAnimation:Bool, stripFilters:Bool, onDone:ByteArray->Void):Void {
        if (!supported || toWorker == null) {
            onDone(bytes);
            return;
        }

        try {
            untyped bytes.shareable = true;
        } catch (_:Dynamic) {}

        var id:Int = nextId++;
        var completed:Bool = false;

        var timer = Timer.delay(function():Void {
            if (!completed) {
                completed = true;
                pending.remove(id);
                onDone(bytes);
            }
        }, TIMEOUT_MS);

        var job = {
            callback: onDone,
            originalBytes: bytes,
            timer: timer,
            id: id
        };

        pending.set(id, job);

        toWorker.send({
            id: id,
            type: "strip_swf",
            bytes: bytes,
            stripAnimation: stripAnimation,
            stripFilters: stripFilters
        });
    }

    private function onWorkerMessage(e:Event):Void {
        while (fromWorker != null && fromWorker.messageAvailable) {
            var result:Dynamic = fromWorker.receive();
            if (result == null) continue;

            var job:Dynamic = pending.get(result.id);
            if (job == null) continue;

            pending.remove(result.id);

            try {
                if (job.timer != null) job.timer.stop();
            } catch (_:Dynamic) {}

            var finalBytes:ByteArray = (result.error == true) ?
                job.originalBytes :
                ((result.bytes != null) ? cast(result.bytes, ByteArray) : job.originalBytes);

            job.callback(finalBytes);
        }
    }
}
