package worker;

class PacketParserWorker {
    /**
     * Parses an individual raw packet string (SmartFox XT format or JSON format).
     * Runs completely off-thread to avoid blocking the render loop.
     */
    public static function parse(raw:String):Dynamic {
        if (raw == null || raw.length == 0) return null;

        var firstChar:String = raw.charAt(0);

        // 1. JSON-encoded SmartFox packet: {"t":"xt", ...}
        if (firstChar == "{" || firstChar == "[") {
            try {
                var json:Dynamic = haxe.Json.parse(raw);
                var cmd:String = "";
                var data:Dynamic = null;

                if (json != null && json.b != null && json.b.o != null) {
                    data = json.b.o;
                    if (data.cmd != null) cmd = Std.string(data.cmd);
                }

                return {
                    success: true,
                    format: "json",
                    cmd: cmd,
                    data: data,
                    raw: json
                };
            } catch (e:Dynamic) {
                return { success: false, format: "json", error: Std.string(e) };
            }
        }

        // 2. Delimited SmartFox XT packet: %xt%zm%cmd%roomId%arg1%arg2%...%
        if (firstChar == "%" || raw.indexOf("%") != -1) {
            try {
                var parts:Array<String> = raw.split("%");
                // Remove empty strings from leading/trailing '%'
                var tokens:Array<String> = [];
                for (p in parts) {
                    if (p != null && p.length > 0) tokens.push(p);
                }

                if (tokens.length < 3) {
                    return { success: false, format: "xt", error: "Malformed XT packet" };
                }

                var type:String = tokens[0]; // usually "xt"
                var zone:String = tokens[1]; // usually "zm" or sub-handler
                var cmd:String = tokens[2];  // e.g. "moveToCell", "uotls", "gar"
                var roomId:Int = (tokens.length > 3) ? Std.parseInt(tokens[3]) : -1;
                var args:Array<Dynamic> = [];

                if (tokens.length > 4) {
                    for (i in 4...tokens.length) {
                        var argStr:String = tokens[i];
                        // If argument looks like an embedded JSON payload, parse it
                        if (argStr.length > 1 && (argStr.charAt(0) == "{" || argStr.charAt(0) == "[")) {
                            try {
                                args.push(haxe.Json.parse(argStr));
                            } catch (_:Dynamic) {
                                args.push(argStr);
                            }
                        } else {
                            args.push(argStr);
                        }
                    }
                }

                return {
                    success: true,
                    format: "xt",
                    type: type,
                    zone: zone,
                    cmd: cmd,
                    roomId: roomId,
                    args: args
                };
            } catch (e:Dynamic) {
                return { success: false, format: "xt", error: Std.string(e) };
            }
        }

        return { success: false, format: "unknown", raw: raw };
    }

    /**
     * Parses a batch of raw packet strings in parallel.
     */
    public static function parseBatch(rawPackets:Array<String>):Array<Dynamic> {
        if (rawPackets == null) return [];
        var results:Array<Dynamic> = [];
        for (p in rawPackets) {
            results.push(parse(p));
        }
        return results;
    }
}
