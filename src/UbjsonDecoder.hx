import haxe.io.UInt8Array;
// import js.html.Uint8Array;
import js.html.DataView;

class UbjsonDecoder {
    public static var valueMarkers = {
        object: '{'.charCodeAt(0),
        string: 'S'.charCodeAt(0),
        uint8: 'U'.charCodeAt(0),
        int32: 'l'.charCodeAt(0)
    };

    public static var terminationMarkers = {
        object: '}'.charCodeAt(0)
    };

    var buffer: UInt8Array;
    // var buffer: Uint8Array;
    var position: Int;
    var dataView: DataView;


    public function new(buffer: UInt8Array) {
    // public function new(buffer: Uint8Array) {
        this.buffer = buffer;
        position = 0;

        dataView = new DataView(buffer.buffer);
    }

    function readObject() {
        var object = new Map<String, Any>();

        while (buffer[position] != terminationMarkers.object) {
            var field = readString();
            object.set(field, readValueAtPosition());
        }

        position++;

        return object;
    }

    function readString(): String {
        var length = readValueAtPosition();

        // if its not number, throw error
        if (!Std.is(length, Int)) {
            trace('UBJSON decoder - failed to read string length');
        }
        var pos = position;
        position += cast(length, Int);

        var stringBuffer = buffer.slice(pos, pos + length);
        return stringBuffer.fromCharCode();
    }

    function readUint8() {
        var pos = position;
        position++;

        return dataView.getUint8(pos);
    }

    function readInt32() {
        var pos = position;
        position += 4;

        return dataView.getInt32(pos);
    }

    function readValueAtPosition() {
        var valueMarker = buffer[position]

        position++;

        if (valueMarker == valueMarkers.object) {
            return readObject();
        } else if (valueMarker == valueMarkers.string) {
            return readString();
        } else if (valueMarker == valueMarkers.uint8) {
            return readUint8();
        } else if (valueMarker == valueMarkers.int32) {
            return readInt32();
        } else {
            trace('UBJSON decoder - value type with marker ${valueMarker} is not supported yet. ' +
            'Position: ${this.position - 1}.')
            // throw exception
        }
    }

    function _decode() {
        return readValueAtPosition();
    }

    public static function decode(buffer: Uint8Array) {
        var decoder = new UbjsonDecoder(buffer);
        return decoder._decode();
    }

}