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
    private var workerSwfBytes:ByteArray;

    private var nextId:Int = 0;
    private var pendingIds:Array<Int> = [];
    private var outbound:Array<Dynamic> = [];
    private var activeJobId:Int = -1;
    private var failedSwfVariants:Map<String, Bool> = new Map<String, Bool>();
    private static inline var MAX_PENDING_JOBS:Int = 32;
    #if flash
    private var pending:flash.utils.Dictionary = new flash.utils.Dictionary();
    private inline function setJob(id:Int, job:Dynamic):Void {
        untyped pending[id] = job;
        pendingIds.push(id);
    }
    private inline function getJob(id:Int):Dynamic {
        return untyped pending[id];
    }
    private inline function removeJob(id:Int):Void {
        if (getJob(id) == null) return;
        untyped __delete__(pending, id);
        var index = pendingIds.indexOf(id);
        if (index >= 0) pendingIds.splice(index, 1);
    }
    #else
    private var pending:Map<Int, Dynamic> = new Map<Int, Dynamic>();
    private inline function setJob(id:Int, job:Dynamic):Void {
        pending.set(id, job);
        pendingIds.push(id);
    }
    private inline function getJob(id:Int):Dynamic {
        return pending.get(id);
    }
    private inline function removeJob(id:Int):Void {
        if (!pending.exists(id)) return;
        pending.remove(id);
        var index = pendingIds.indexOf(id);
        if (index >= 0) pendingIds.splice(index, 1);
    }
    #end
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
                workerSwfBytes = cloneBytes(swfBytes);
                launchWorker();
            } else {
                supported = false;
            }
        } catch (e:Dynamic) {
            supported = false;
            trace("Worker initialization failed: " + Std.string(e));
        }
    }

    private function launchWorker():Void {
        if (workerSwfBytes == null || workerSwfBytes.length == 0) {
            supported = false;
            return;
        }
        bgWorker = WorkerDomain.current.createWorker(cloneBytes(workerSwfBytes));
        toWorker = Worker.current.createMessageChannel(bgWorker);
        fromWorker = bgWorker.createMessageChannel(Worker.current);
        bgWorker.setSharedProperty("toWorker", toWorker);
        bgWorker.setSharedProperty("fromWorker", fromWorker);
        fromWorker.addEventListener(Event.CHANNEL_MESSAGE, onWorkerMessage);
        bgWorker.start();
        supported = true;
    }

    private static function cloneBytes(source:ByteArray):ByteArray {
        var copy = new ByteArray();
        source.position = 0;
        source.readBytes(copy, 0, source.length);
        copy.position = 0;
        source.position = 0;
        return copy;
    }

    private function failJob(job:Dynamic, error:String):Void {
        if (job == null) return;
        trace("SWF worker job " + job.id + " failed; using original asset: " + error);
        var original:ByteArray = cast job.originalBytes;
        try {
            job.callback(ensureNonShared(original));
        } catch (callbackError:Dynamic) {
            trace("SWF fallback callback failed: " + Std.string(callbackError));
        }
    }

    private function recoverWorker(timeoutId:Int, reason:String):Void {
        var ids = pendingIds.copy();
        outbound = [];
        activeJobId = -1;
        var failedJobs:Array<Dynamic> = [];
        try {
            if (fromWorker != null) fromWorker.removeEventListener(Event.CHANNEL_MESSAGE, onWorkerMessage);
            if (bgWorker != null) bgWorker.terminate();
        } catch (error:Dynamic) {
            trace("Worker termination failed: " + Std.string(error));
        }
        fromWorker = null;
        toWorker = null;
        bgWorker = null;

        for (id in ids) {
            var job = getJob(id);
            removeJob(id);
            try {
                if (job != null && job.timer != null) job.timer.stop();
            } catch (_:Dynamic) {}
            failedJobs.push({
                id: id,
                job: job,
                error: (id == timeoutId) ? reason : "Worker restarted after another job timed out"
            });
        }

        try {
            launchWorker();
        } catch (error:Dynamic) {
            supported = false;
            trace("Worker restart failed: " + Std.string(error));
        }
        for (failed in failedJobs) failJob(failed.job, failed.error);
    }

    private function enqueueJob(message:Dynamic):Void {
        outbound.push(message);
        dispatchNext();
    }

    private function dispatchNext():Void {
        if (activeJobId >= 0 || !supported || toWorker == null) return;

        while (outbound.length > 0) {
            var message:Dynamic = outbound.shift();
            var id:Int = message.id;
            var job:Dynamic = getJob(id);
            if (job == null) continue;

            if (job.failureKey != null && failedSwfVariants.exists(job.failureKey)) {
                removeJob(id);
                trace("Skipping previously failed SWF processing for " + job.failureKey);
                try {
                    job.callback(ensureNonShared(cast job.originalBytes));
                } catch (callbackError:Dynamic) {
                    trace("SWF fallback callback failed: " + Std.string(callbackError));
                }
                continue;
            }

            activeJobId = id;
            var effectiveTimeout:Int = (job.timeoutMs != null) ? job.timeoutMs : TIMEOUT_MS;
            job.timer = Timer.delay(function():Void {
                if (getJob(id) != null) {
                    recoverWorker(id, "Job timed out after " + effectiveTimeout + "ms");
                }
            }, effectiveTimeout);

            try {
                toWorker.send(message);
            } catch (error:Dynamic) {
                job.timer.stop();
                removeJob(id);
                activeJobId = -1;
                failJob(job, "Failed to send worker job: " + Std.string(error));
                if (activeJobId >= 0) return;
                continue;
            }
            return;
        }
    }

    /**
     * Off-thread SWF asset stripping & optimization (Animation, Filters, Sounds).
     */
    public function process(bytes:ByteArray, stripAnimation:Bool, stripFilters:Bool, ?stripSounds:Bool = false, onDone:ByteArray->Void, ?assetUrl:String):Void {
        if (!supported || toWorker == null) {
            onDone(ensureNonShared(bytes));
            return;
        }
        if (!stripAnimation && !stripFilters && !stripSounds) {
            onDone(ensureNonShared(bytes));
            return;
        }

        var failureKey:String = (assetUrl == null || assetUrl.length == 0) ? null :
            assetUrl + "|" + stripAnimation + "|" + stripFilters + "|" + stripSounds;
        if (failureKey != null && failedSwfVariants.exists(failureKey)) {
            onDone(ensureNonShared(bytes));
            return;
        }

        var id:Int = nextId++;
        if (pendingIds.length >= MAX_PENDING_JOBS) {
            trace("SWF processing bypassed: worker queue is full (" + MAX_PENDING_JOBS + " pending jobs)");
            onDone(ensureNonShared(bytes));
            return;
        }

        setJob(id, {
            id: id,
            callback: onDone,
            originalBytes: bytes,
            assetUrl: assetUrl,
            failureKey: failureKey,
            timeoutMs: TIMEOUT_MS,
            timer: null
        });

        enqueueJob({
            id: id,
            type: "strip_swf",
            bytes: bytes,
            stripAnimation: stripAnimation,
            stripFilters: stripFilters,
            stripSounds: stripSounds
        });
    }

    private function onWorkerMessage(e:Event):Void {
        while (fromWorker != null && fromWorker.messageAvailable) {
            var result:Dynamic = null;
            try {
                result = fromWorker.receive();
            } catch (_:Dynamic) {
                break;
            }
            if (result == null) continue;

            var job:Dynamic = getJob(result.id);
            if (job == null) continue;

            removeJob(result.id);

            try {
                if (job.timer != null) job.timer.stop();
            } catch (_:Dynamic) {}
            if (activeJobId == result.id) activeJobId = -1;

            var err:String = (result.error != null) ? Std.string(result.error) : null;
            if (err != null) {
                if (job.failureKey != null) failedSwfVariants.set(job.failureKey, true);
                var assetLabel:String = (job.assetUrl != null) ? job.assetUrl : "unknown asset";
                trace("SWF processing failed for " + assetLabel + "; using original asset: " + err);
            } else if (result.bytes == null) {
                trace("SWF worker returned no output; using original asset");
            }

            var rawBytes:ByteArray = (err != null || result.bytes == null) ?
                job.originalBytes : cast(result.bytes, ByteArray);
            try {
                job.callback(ensureNonShared(rawBytes));
            } catch (cbErr:Dynamic) {
                trace("SWF callback error: " + Std.string(cbErr));
            }
            dispatchNext();
        }
    }

    /**
     * Guards against Flash Player ArgumentError #3735 ('This API cannot accept shared ByteArrays').
     * If a ByteArray is marked shareable=true by the AIR Worker subsystem, clones it into a
     * clean, non-shared ByteArray before returning to the main thread or passing to Loader.loadBytes.
     */
    public static function ensureNonShared(bytes:ByteArray):ByteArray {
        if (bytes == null) return null;
        try {
            if (untyped bytes.shareable == true) {
                var clean:ByteArray = new ByteArray();
                bytes.position = 0;
                bytes.readBytes(clean, 0, bytes.length);
                clean.position = 0;
                return clean;
            }
        } catch (_:Dynamic) {}
        bytes.position = 0;
        return bytes;
    }
}
