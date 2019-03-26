import haxe.io.BytesBuffer;
import haxe.Int32;
import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.UInt8Array;

class SlpDecoder {
    var bytes: Bytes;
    var position: Int;
    var metadata: Map<String, Any>;
    // var buffer: UInt8Array;

    public function new(bytes: Bytes) {
        this.bytes = bytes;
        position = 0;

        // buffer = UInt8Array.fromBytes(bytes);

        // var string = '';


        // var file = sys.io.File.append('wtf.txt');
        // for (i in 0...bytes.length) {

        //     string = '${bytes.get(i)}: ${String.fromCharCode(bytes.get(i))}\n';
        //     file.writeString(string);
        // }

        // file.close();

    }

    public function getMetadata(): Map<String, Any> {
        read();
        return metadata;
    }

    function isMarker(marker: Markers): Bool {
        return readByte() == marker;
    }

    function isEndObject(): Bool {
        return isMarker(Markers.OBJECT_END);
    }

    function isEndArray(): Bool {
        return isMarker(Markers.ARRAY_END);
    }

    function readByte(): Int {
        return bytes.get(position);
    }

    static function toBigEndian(bytes: Bytes): Bytes {
        var arrayBytes = new Array<Int>();

        for (i in 0...bytes.length) {
            arrayBytes.unshift(bytes.get(i));
        }

        // var uint8array = UInt8Array.fromArray(arrayBytes);
        // uint8array.

        var buffer = new BytesBuffer();

        for (byte in arrayBytes) {
            buffer.addByte(byte);
        }

        return buffer.getBytes();
    }

    function readBytes(size: Int): Bytes {
        var arr = new Array<Int>();
        var buffer = new BytesBuffer();

        size--;

        for (i in 0...size) {
            buffer.addByte(readByte());
        }

        return buffer.getBytes();
    }

    function readInt() {
        var pos = position;
        position++;

        return readByte();
    }

    function readInt8(): Int {
        return readInt();
    }

    function readUInt8(): Int { // UInt type?
        // var pos = position;
        // position++;

        // return bytes.get(pos);
        return readInt();
    }

    function readInt16(): Int {
        return readBytes(3).getUInt16(0);
    }

    function readInt32(): Int32 {
        // var pos = position;
        // position += 4;

        // return bytes.getInt32(pos);
        // return readInt(5);
        // var arr = new Array<Int>();
        // var buffer = new BytesBuffer();
        // for (i in 0...4) {
        //     buffer.addByte(readByte());
        // }

        // return buffer.getBytes().getInt32(0);
        return readBytes(5).getInt32(0);
    }

    function readInt64(): Int64 {
        return readBytes(9).getInt64(0);
    }

    function readFloat32() {
        // var pos = position;
        // position += size - 1;

        // var fbytes = bytes.sub(pos, 5).getData();
        // #if neko
        // trace('nekooo');
        // #end
        // // return bytes.
        return readBytes(5).getFloat(0);
    }

    function readFloat64() {
        return readBytes(9).getFloat(0);
    }

    function readHighPrecisionNumber() {
        trace('HIGH PRECISION NUMBER');
        return readString();
    }

    function readChar() {
        trace('---- CHAR ----');
        return '${readInt()}';
    }

    function readString(): String {
        var maybe_length = read();
        var length;

        // if its not number, throw error
        if (Std.is(maybe_length, Int)) {
            length = cast(maybe_length, Int); // Int32?
        } else {
            var e = 'UBJSON decoder - failed to read string length';
            throw e;
        }

        var pos = position;
        position += length;

        var string = bytes.getString(pos, length);
        trace(string);
        return string;
    }

    function readObject(): Map<String, Any> {
        var object = new Map<String, Any>();

        while (!isEndObject()) {
            var field = readString();
            var value = read();
            object.set(field, value);
            trace(field, value);

            if (field == 'metadata') {
                metadata = object;
            }
        }

        position++;

        return object;
    }

    function readArray(): Array<Any> {
        var array = new Array<Any>();

        // TODO: Can calculate how many bytes it takes by multiplying the length
        // by the amount of bytes its type takes
        // Like:  UInt8 = 1 byte, if 25 items, then 1 * 25items = X. add that to position
        // + the bytes that tell you the length/type ($X#T)
        var type = readType();
        var length = readCount();
        // var type = bytes.get
        // var length = readInt32();

        // for (byte in 0...length) {
        //     array.push(read());
        // }

        while (!isEndArray()) {
            array.push(read());
        }

        position++;

        return array;
    }

    function readType() {
        var type_sign = readByte();

        if (type_sign != Markers.TYPE)
            trace('${String.fromCharCode(type_sign)} ($type_sign) is not ' +
            '${String.fromCharCode(Markers.TYPE)} (${Markers.TYPE}) at position $position');

        position++;
        var type = readByte();
        trace('Type is ${String.fromCharCode(type)} ($type)');
        return type;

    }

    function readCount() {
        position++;
        var count_sign = readByte();

        if (count_sign != Markers.COUNT)
            trace('${String.fromCharCode(count_sign)} ($count_sign) is not ' +
            '${String.fromCharCode(Markers.COUNT)} (${Markers.COUNT}) at position $position');

        position++;
        var count = readValue(readByte());
        // trace('Count is ${String.fromCharCode(count)} ($count)');
        return count;
    }

    function read(): Any {
        var marker = readByte();
        trace('$marker: ${String.fromCharCode(marker)}');

        position++;

        var value = readValue(marker);
        if (value != null) return value;

        var other = readContainerAndParameters(marker);
        if (other != null) return other;

        trace('"${String.fromCharCode(marker)}" ($marker) at ${position - 1}');
        var e = 'UBJSON decoder - value type with marker ${marker} is ' +
        'not supported yet. Position: ${position - 1}.';
        throw e;

        return null;
    }

    function readValue(marker: Markers): Any {
        switch (marker) {
            case Markers.NULL:
                trace('Byte is ${String.fromCharCode(Markers.NULL)} (${Markers.NULL})');
                trace('Known marker: ${Markers.TYPE}');
            case Markers.NOOP:
                trace('Byte is ${String.fromCharCode(Markers.NOOP)} (${Markers.NOOP})');
                trace('Known marker: ${Markers.NOOP}');
            case Markers.TRUE:
                trace('Byte is ${String.fromCharCode(Markers.TRUE)} (${Markers.TRUE})');
                trace('Known marker: ${Markers.TRUE}');
            case Markers.FALSE:
                trace('Byte is ${String.fromCharCode(Markers.FALSE)} (${Markers.FALSE})');
                trace('Known marker: ${Markers.FALSE}');
            case Markers.INT8:
                trace('Byte is ${String.fromCharCode(Markers.INT8)} (${Markers.INT8})');
                trace('Known marker: ${Markers.INT8}');
                return readUInt8();
            case Markers.UINT8:
                trace('Byte is ${String.fromCharCode(Markers.UINT8)} (${Markers.UINT8})');
                return readUInt8();
            case Markers.INT16:
                trace('Byte is ${String.fromCharCode(Markers.INT16)} (${Markers.INT16})');
                trace('Known marker: ${Markers.INT16}');
                return readInt(3);
            case Markers.INT32:
                trace('Byte is ${String.fromCharCode(Markers.INT32)} (${Markers.INT32})');
                return readInt32();
            case Markers.INT64:
                trace('Byte is ${String.fromCharCode(Markers.INT64)} (${Markers.INT64})');
                trace('Known marker: ${Markers.INT64}');
                return readInt(9);
            case Markers.FLOAT32:
                trace('Byte is ${String.fromCharCode(Markers.FLOAT32)} (${Markers.FLOAT32})');
                trace('Known marker: ${Markers.FLOAT32}');
            case Markers.FLOAT64:
                trace('Byte is ${String.fromCharCode(Markers.FLOAT64)} (${Markers.FLOAT64})');
                trace('Known marker: ${Markers.FLOAT64}');
            case Markers.HIGH_PRECISION_NUMBER:
                trace('Byte is ${String.fromCharCode(Markers.HIGH_PRECISION_NUMBER)} (${Markers.HIGH_PRECISION_NUMBER})');
                trace('Known marker: ${Markers.HIGH_PRECISION_NUMBER}');
            case Markers.CHAR:
                trace('Byte is ${String.fromCharCode(Markers.CHAR)} (${Markers.CHAR})');
                trace('Known marker: ${Markers.CHAR}');
            case Markers.STRING:
                trace('Byte is ${String.fromCharCode(Markers.STRING)} (${Markers.STRING})');
                return readString();
            default:
                return null;
        }

        return null;
    }

    function readContainerAndParameters(marker: Markers): Any {
        switch (marker) {
            // Containers
            case Markers.ARRAY_START:
                trace('Byte is ${String.fromCharCode(Markers.ARRAY_START)} (${Markers.ARRAY_START})');
                return readArray();
            case Markers.OBJECT_START:
                trace('Byte is ${String.fromCharCode(Markers.OBJECT_START)} (${Markers.OBJECT_START})');
                return readObject();
            // Optimized format optional parameters
            case Markers.TYPE:
                trace('Byte is ${String.fromCharCode(Markers.TYPE)} (${Markers.TYPE})');
                trace('Known marker: ${Markers.TYPE}');
            case Markers.COUNT:
                trace('Byte is ${String.fromCharCode(Markers.COUNT)} (${Markers.COUNT})');
                trace('Known marker: ${Markers.COUNT}');
                // return readArray();
            default:
                return null;
        }

        return null;
    }

    public static function decode(bytes: Bytes): Map<String, Any> {
        var decoder = new SlpDecoder(bytes);
        decoder.read();
        return decoder.metadata;
    }

}