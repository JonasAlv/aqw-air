package util;

import flash.events.Event;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.system.WorkerDomain;
import flash.utils.ByteArray;
import haxe.Timer;
import worker.WorkerSharedMemory;

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
    #if flash
    private var pending:flash.utils.Dictionary = new flash.utils.Dictionary();
    private inline function setJob(id:Int, job:Dynamic):Void {
        untyped pending[id] = job;
    }
    private inline function getJob(id:Int):Dynamic {
        return untyped pending[id];
    }
    private inline function removeJob(id:Int):Void {
        untyped __delete__(pending, id);
    }
    #else
    private var pending:Map<Int, Dynamic> = new Map<Int, Dynamic>();
    private inline function setJob(id:Int, job:Dynamic):Void {
        pending.set(id, job);
    }
    private inline function getJob(id:Int):Dynamic {
        return pending.get(id);
    }
    private inline function removeJob(id:Int):Void {
        pending.remove(id);
    }
    #end
    private inline static var TIMEOUT_MS:Int = 10000;

    public var supported:Bool = false;
    public var sharedMemory(default, null):WorkerSharedMemory;

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

                // Initialize 1MB zero-copy shared memory buffer
                sharedMemory = new WorkerSharedMemory();

                bgWorker.setSharedProperty("toWorker", toWorker);
                bgWorker.setSharedProperty("fromWorker", fromWorker);
                bgWorker.setSharedProperty("sharedMemory", sharedMemory.buffer);

                fromWorker.addEventListener(Event.CHANNEL_MESSAGE, onWorkerMessage);
                bgWorker.start();
            } else {
                supported = false;
            }
        } catch (e:Dynamic) {
            supported = false;
        }
    }

    /**
     * Core generic job dispatcher to the background worker.
     */
    public function sendJob(type:String, payload:Dynamic, onDone:(result:Dynamic, error:String)->Void, ?timeoutMs:Int):Int {
        var id:Int = nextId++;
        if (!supported || toWorker == null) {
            if (onDone != null) onDone(null, "Worker unsupported or unavailable");
            return id;
        }

        var effectiveTimeout:Int = (timeoutMs != null && timeoutMs > 0) ? timeoutMs : TIMEOUT_MS;
        var completed:Bool = false;

        var timer = Timer.delay(function():Void {
            if (!completed) {
                completed = true;
                removeJob(id);
                if (onDone != null) {
                    try {
                        onDone(null, "Job timed out after " + effectiveTimeout + "ms");
                    } catch (_:Dynamic) {}
                }
            }
        }, effectiveTimeout);

        setJob(id, {
            id: id,
            type: type,
            onDone: onDone,
            timer: timer
        });

        var message:Dynamic = (payload != null) ? payload : {};
        Reflect.setField(message, "id", id);
        Reflect.setField(message, "type", type);

        toWorker.send(message);
        return id;
    }

    /**
     * Off-thread SWF asset stripping & optimization (Animation, Filters, Sounds).
     */
    public function process(bytes:ByteArray, stripAnimation:Bool, stripFilters:Bool, ?stripSounds:Bool = false, onDone:ByteArray->Void):Void {
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
                removeJob(id);
                if (onDone != null) {
                    try {
                        onDone(bytes);
                    } catch (_:Dynamic) {}
                }
            }
        }, TIMEOUT_MS);

        setJob(id, {
            id: id,
            type: "strip_swf",
            callback: onDone,
            originalBytes: bytes,
            timer: timer
        });

        toWorker.send({
            id: id,
            type: "strip_swf",
            bytes: bytes,
            stripAnimation: stripAnimation,
            stripFilters: stripFilters,
            stripSounds: stripSounds
        });
    }

    /**
     * Off-thread JSON parser (Eliminates main-thread parsing stutters on large payloads).
     */
    public function parseJson(rawJson:String, onDone:(parsed:Dynamic, error:String)->Void):Void {
        if (!supported || toWorker == null) {
            try {
                var res = haxe.Json.parse(rawJson);
                onDone(res, null);
            } catch (e:Dynamic) {
                onDone(null, Std.string(e));
            }
            return;
        }

        sendJob("parse_json", { data: rawJson }, onDone);
    }

    /**
     * Off-thread SmartFox packet parser (XT strings and embedded JSON).
     */
    public function parsePacket(rawPacket:String, onDone:(parsed:Dynamic, error:String)->Void):Void {
        if (!supported || toWorker == null) {
            var res = worker.PacketParserWorker.parse(rawPacket);
            onDone(res, null);
            return;
        }

        sendJob("parse_packet", { data: rawPacket }, onDone);
    }

    /**
     * Off-thread batch packet parser for high-density packet storms.
     */
    public function parsePacketBatch(packets:Array<String>, onDone:(batch:Array<Dynamic>, error:String)->Void):Void {
        if (!supported || toWorker == null) {
            var res = worker.PacketParserWorker.parseBatch(packets);
            onDone(res, null);
            return;
        }

        sendJob("parse_packet_batch", { data: packets }, onDone);
    }

    /**
     * Off-thread item fuzzy search, filtering, and sorting (1,000+ Bank/Inventory items).
     */
    public function searchItems(query:String, items:Array<Dynamic>, options:Dynamic, onDone:Dynamic->Void):Void {
        if (!supported || toWorker == null) {
            var res = worker.SearchIndexWorker.search(query, items, null, options);
            onDone(res);
            return;
        }

        sendJob("search_items", { query: query, items: items, options: options }, function(res, err) {
            onDone(res);
        });
    }

    /**
     * Stores an item list in the worker cache to eliminate re-sending data across threads.
     */
    public function indexItems(cacheKey:String, items:Array<Dynamic>, ?onDone:Int->Void):Void {
        if (!supported || toWorker == null) {
            var count = worker.SearchIndexWorker.indexItems(cacheKey, items);
            if (onDone != null) onDone(count);
            return;
        }

        sendJob("index_items", { cacheKey: cacheKey, items: items }, function(res, err) {
            if (onDone != null) onDone((res != null) ? Std.int(res) : 0);
        });
    }

    /**
     * Searches items directly against an already indexed cache in the worker.
     */
    public function searchIndexedItems(cacheKey:String, query:String, options:Dynamic, onDone:Dynamic->Void):Void {
        if (!supported || toWorker == null) {
            var res = worker.SearchIndexWorker.search(query, null, cacheKey, options);
            onDone(res);
            return;
        }

        sendJob("search_items", { cacheKey: cacheKey, query: query, options: options }, function(res, err) {
            onDone(res);
        });
    }

    /**
     * Clears indexed items cache in worker memory.
     */
    public function clearIndex(?cacheKey:String):Void {
        if (!supported || toWorker == null) {
            if (cacheKey != null) worker.SearchIndexWorker.clearIndex(cacheKey);
            else worker.SearchIndexWorker.clearAll();
            return;
        }

        sendJob("clear_index", { cacheKey: cacheKey }, null);
    }

    /**
     * Off-thread combat calculation and optimal rotation solver.
     */
    public function solveCombat(combatState:Dynamic, onDone:Dynamic->Void):Void {
        if (!supported || toWorker == null) {
            var res = worker.CombatSolverWorker.solve(combatState);
            onDone(res);
            return;
        }

        sendJob("combat_solve", { state: combatState }, function(res, err) {
            onDone(res);
        });
    }

    /**
     * Off-thread ZLIB compression.
     */
    public function compressBytes(bytes:ByteArray, onDone:ByteArray->Void):Void {
        if (!supported || toWorker == null) {
            bytes.position = 0;
            bytes.compress();
            bytes.position = 0;
            onDone(bytes);
            return;
        }

        sendJob("compress_bytes", { bytes: bytes }, function(res, err) {
            onDone(cast res);
        });
    }

    /**
     * Off-thread ZLIB decompression.
     */
    public function uncompressBytes(bytes:ByteArray, onDone:ByteArray->Void):Void {
        if (!supported || toWorker == null) {
            bytes.position = 0;
            bytes.uncompress();
            bytes.position = 0;
            onDone(bytes);
            return;
        }

        sendJob("uncompress_bytes", { bytes: bytes }, function(res, err) {
            onDone(cast res);
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

            var err:String = (result.error != null) ? Std.string(result.error) : null;

            // Specialized handler for SWF stripper jobs
            if (job.type == "strip_swf" && job.callback != null) {
                var finalBytes:ByteArray = (result.error != null) ?
                    job.originalBytes :
                    ((result.bytes != null) ? cast(result.bytes, ByteArray) : job.originalBytes);
                try {
                    job.callback(finalBytes);
                } catch (cbErr:Dynamic) {
                    trace("SWF callback error: " + Std.string(cbErr));
                }
                continue;
            }

            // Generic job handler
            if (job.onDone != null) {
                var data = (result.bytes != null) ? result.bytes : result.data;
                try {
                    job.onDone(data, err);
                } catch (cbErr:Dynamic) {
                    trace("Job onDone error: " + Std.string(cbErr));
                }
            }
        }
    }
}
