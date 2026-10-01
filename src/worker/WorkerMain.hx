package worker;

#if flash
import flash.display.Sprite;
import flash.events.Event;
import flash.system.MessageChannel;
import flash.system.Worker;
import flash.utils.ByteArray;

class WorkerMain extends Sprite {
    private var sharedMem:WorkerSharedMemory;

    public function new() {
        super();
        var curWorker:Worker = Worker.current;
        if (curWorker == null || curWorker.isPrimordial) {
            return;
        }

        var fromMain:MessageChannel = cast curWorker.getSharedProperty("toWorker");
        var toMain:MessageChannel = cast curWorker.getSharedProperty("fromWorker");

        // Attach shared memory page if provided by main thread
        var rawSharedMem:ByteArray = cast curWorker.getSharedProperty("sharedMemory");
        if (rawSharedMem != null) {
            sharedMem = new WorkerSharedMemory(rawSharedMem);
        }

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
                                var stripAnim:Bool = (job.stripAnimation == true);
                                var stripFilt:Bool = (job.stripFilters == true);
                                var stripSound:Bool = (job.stripSounds == true);
                                resultBytes = SWFStripper.process(bytes, stripAnim, stripFilt, stripSound);

                            case "parse_json":
                                var rawStr:String = Std.string(job.data);
                                responseData = haxe.Json.parse(rawStr);

                            case "parse_packet":
                                var rawPacket:String = Std.string(job.data);
                                responseData = PacketParserWorker.parse(rawPacket);

                            case "parse_packet_batch":
                                var batch:Array<String> = cast job.data;
                                responseData = PacketParserWorker.parseBatch(batch);

                            case "search_items":
                                var query:String = job.query;
                                var items:Array<Dynamic> = (job.items != null) ? cast job.items : null;
                                var cacheKey:String = job.cacheKey;
                                var options:Dynamic = job.options;
                                responseData = SearchIndexWorker.search(query, items, cacheKey, options);

                            case "index_items":
                                var cacheKey:String = job.cacheKey;
                                var items:Array<Dynamic> = cast job.items;
                                responseData = SearchIndexWorker.indexItems(cacheKey, items);

                            case "clear_index":
                                var cacheKey:String = job.cacheKey;
                                if (cacheKey != null) {
                                    SearchIndexWorker.clearIndex(cacheKey);
                                } else {
                                    SearchIndexWorker.clearAll();
                                }
                                responseData = true;

                            case "combat_solve":
                                var combatState:Dynamic = job.state;
                                responseData = CombatSolverWorker.solve(combatState);

                            case "compress_bytes":
                                var inBytes:ByteArray = cast job.bytes;
                                if (inBytes != null) {
                                    inBytes.position = 0;
                                    inBytes.compress();
                                    inBytes.position = 0;
                                    resultBytes = inBytes;
                                }

                            case "uncompress_bytes":
                                var inBytes:ByteArray = cast job.bytes;
                                if (inBytes != null) {
                                    inBytes.position = 0;
                                    inBytes.uncompress();
                                    inBytes.position = 0;
                                    resultBytes = inBytes;
                                }

                            case "shared_process":
                                if (sharedMem != null) {
                                    var cmdId:Int = sharedMem.getCommandId();
                                    var payloadStr:String = sharedMem.readUTF();
                                    var parsed:Dynamic = PacketParserWorker.parse(payloadStr);
                                    sharedMem.writeUTF(cmdId, haxe.Json.stringify(parsed));
                                    sharedMem.setStatus(WorkerSharedMemory.STATUS_WORKER_DONE);
                                    responseData = true;
                                }

                            case "ping":
                                responseData = {
                                    status: "pong",
                                    workerTime: flash.Lib.getTimer(),
                                    hasSharedMem: (sharedMem != null)
                                };

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
