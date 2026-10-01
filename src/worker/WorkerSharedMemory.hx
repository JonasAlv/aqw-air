package worker;

#if flash
import flash.utils.ByteArray;

class WorkerSharedMemory {
    public static inline var DEFAULT_CAPACITY:Int = 1048576; // 1 MB shared page

    // Memory Header Offsets
    public static inline var OFFSET_STATUS:Int = 0;       // Int32: Status flag
    public static inline var OFFSET_CMD_ID:Int = 4;       // Int32: Command / Job ID
    public static inline var OFFSET_DATA_LEN:Int = 8;     // Int32: Payload length in bytes
    public static inline var OFFSET_RESULT_CODE:Int = 12; // Int32: Return/Error code
    public static inline var OFFSET_TIMESTAMP:Int = 16;   // Float64: High-precision timestamp
    public static inline var OFFSET_PAYLOAD:Int = 24;     // Raw payload buffer start

    // Status Constants
    public static inline var STATUS_IDLE:Int = 0;
    public static inline var STATUS_MAIN_WRITING:Int = 1;
    public static inline var STATUS_WORKER_BUSY:Int = 2;
    public static inline var STATUS_WORKER_DONE:Int = 3;
    public static inline var STATUS_ERROR:Int = 4;

    public var buffer:ByteArray;

    public function new(?existingBuffer:ByteArray, capacity:Int = DEFAULT_CAPACITY) {
        if (existingBuffer != null) {
            buffer = existingBuffer;
        } else {
            buffer = new ByteArray();
            buffer.length = capacity;
            try {
                untyped buffer.shareable = true;
            } catch (_:Dynamic) {}
            setStatus(STATUS_IDLE);
            buffer.position = OFFSET_DATA_LEN;
            buffer.writeInt(0);
        }
    }

    public inline function getStatus():Int {
        if (buffer == null || (buffer.length : Int) < 4) return STATUS_IDLE;
        buffer.position = OFFSET_STATUS;
        return buffer.readInt();
    }

    public inline function setStatus(status:Int):Void {
        if (buffer == null || (buffer.length : Int) < 4) return;
        buffer.position = OFFSET_STATUS;
        buffer.writeInt(status);
    }

    public inline function getCommandId():Int {
        if (buffer == null || (buffer.length : Int) < 8) return 0;
        buffer.position = OFFSET_CMD_ID;
        return buffer.readInt();
    }

    public inline function getDataLength():Int {
        if (buffer == null || (buffer.length : Int) < 12) return 0;
        buffer.position = OFFSET_DATA_LEN;
        return buffer.readInt();
    }

    public inline function getResultCode():Int {
        if (buffer == null || (buffer.length : Int) < 16) return 0;
        buffer.position = OFFSET_RESULT_CODE;
        return buffer.readInt();
    }

    public function writePayload(cmdId:Int, payloadBytes:ByteArray, ?resultCode:Int = 0):Bool {
        if (buffer == null || payloadBytes == null) return false;
        var len:Int = (payloadBytes.length : Int);
        if (OFFSET_PAYLOAD + len > (buffer.length : Int)) return false;

        setStatus(STATUS_MAIN_WRITING);
        buffer.position = OFFSET_CMD_ID;
        buffer.writeInt(cmdId);
        buffer.writeInt(len);
        buffer.writeInt(resultCode);
        buffer.writeDouble(flash.Lib.getTimer());

        buffer.position = OFFSET_PAYLOAD;
        payloadBytes.position = 0;
        buffer.writeBytes(payloadBytes, 0, len);

        setStatus(STATUS_WORKER_BUSY);
        return true;
    }

    public function readPayload():ByteArray {
        if (buffer == null) return null;
        var len:Int = getDataLength();
        if (len <= 0 || OFFSET_PAYLOAD + len > (buffer.length : Int)) return null;

        var out:ByteArray = new ByteArray();
        buffer.position = OFFSET_PAYLOAD;
        buffer.readBytes(out, 0, len);
        out.position = 0;
        return out;
    }

    public function writeUTF(cmdId:Int, text:String, ?resultCode:Int = 0):Bool {
        if (buffer == null || text == null) return false;
        var temp:ByteArray = new ByteArray();
        temp.writeUTFBytes(text);
        temp.position = 0;
        return writePayload(cmdId, temp, resultCode);
    }

    public function readUTF():String {
        if (buffer == null) return null;
        var len:Int = getDataLength();
        if (len <= 0 || OFFSET_PAYLOAD + len > (buffer.length : Int)) return "";
        buffer.position = OFFSET_PAYLOAD;
        return buffer.readUTFBytes(len);
    }

    public function reset():Void {
        if (buffer == null) return;
        setStatus(STATUS_IDLE);
        buffer.position = OFFSET_CMD_ID;
        buffer.writeInt(0);
        buffer.writeInt(0);
        buffer.writeInt(0);
    }
}
#else
class WorkerSharedMemory {
    public function new(?existingBuffer:Dynamic, capacity:Int = 0) {}
}
#end
