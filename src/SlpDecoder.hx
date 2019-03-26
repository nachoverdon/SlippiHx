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

    function next(?step: Int = 1) {
        // trace('Position: $position, byte: ${String.fromCharCode(bytes.get(position))} (${bytes.get(position)})');
        position += step;
        // trace('New position: $position');
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

    function readByte(?pos = null): Int {
        if (pos != null)
            return bytes.get(pos);
        else
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
        next();
        size--;
        var bytes = Bytes.alloc(size);
        for (i in 0...size) {
            arr.unshift(readByte());
            next();
        }

        for (i in 0...arr.length) {
            bytes.set(i, arr[i]);
        }

        return bytes;
    }

    function readNull() {
        return null;
    }

    function readNoop() {
        return null;
    }

    function readTrue() {
        return true;
    }

    function readFalse() {
        return false;
    }

    function readInt() {
        var pos = position;
        next();

        return readByte(pos);
    }

    function readInt8(): Int {
        return readInt();
    }

    function readUInt8(): Int { // UInt type?
        // var pos = position;
        // next();

        // return bytes.get(pos);
        return readInt();
    }

    function readInt16(): Int {
        // return bytes.getUInt16(position);
        return readBytes(3).getUInt16(0);
    }

    function readInt32(): Int32 {
        // var pos = position;
        // next(4);

        // return bytes.getInt32(pos);
        // return readInt(5);
        // var arr = new Array<Int>();
        // var buffer = new BytesBuffer();
        // for (i in 0...4) {
        //     buffer.addByte(readByte());
        // }

        // return buffer.getBytes().getInt32(0);
        var value = readBytes(5).getInt32(0);
        return value;
    }

    function readInt64(): Int64 {
        return readBytes(9).getInt64(0);
    }

    function readFloat32() {
        // var pos = position;
        // next(size - 1);

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
        next(length);

        var string = bytes.getString(pos, length);
        trace('String "$string" with length $length');
        return string;
    }

    function readObject(): Map<String, Any> {
        var object = new Map<String, Any>();

        while (!isEndObject()) {
            var field = readString();
            var value = read();
            object.set(field, value);
            trace('field, value');
            trace(field, value);

            // if (field == 'metadata') {
            //     metadata = object;
            // }
        }

        next();

        return object;
    }

    function readArray(): Array<Any> {
        var array = new Array<Any>();

        // TODO: Can calculate how many bytes it takes by multiplying the length
        // by the amount of bytes its type takes
        // Like:  UInt8 = 1 byte, if 25 items, then 1 * 25items = X. add that to position
        // + the bytes that tell you the length/type ($X#T)
        var type = readType();
        next();
        var length = readCount();

        // while (!isEndArray()) {
        //     array.push(read());
        // }

        // next();
        next(length);

        return array;
    }

    function readType(): Null<Int> {
        var type_sign = readByte();

        if (type_sign != Markers.TYPE) {
            trace('${String.fromCharCode(type_sign)} ($type_sign) is not ' +
            '${String.fromCharCode(Markers.TYPE)} (${Markers.TYPE}) at position $position');
            return null;
        }

        next();
        var type = readByte();
        trace('Type is ${String.fromCharCode(type)} ($type)');

        return type;
    }

    function readCount(): Int {
        var count_sign = readByte();

        if (count_sign != Markers.COUNT) {
            trace('${String.fromCharCode(count_sign)} ($count_sign) is not ' +
            '${String.fromCharCode(Markers.COUNT)} (${Markers.COUNT}) at position $position');
            return null;
        }

        next();
        var count = readValue(readByte());
        // trace('Count is ${String.fromCharCode(count)} ($count)');

        return count;
    }

    function read(): Any {
        var marker = readByte();
        trace('[${String.fromCharCode(marker)}]: $marker');

        next();

        var value = readValue(marker);
        if (value != null) return value;

        var other = readContainerAndParameters(marker);
        if (other != null) return other;

        if (position >= bytes.length) {
            trace('End of file.');
        } else {
            trace('[${String.fromCharCode(marker)}] ($marker) at ${position - 1}');
            var e = 'UBJSON decoder - value type with marker [${String.fromCharCode(marker)}] (${marker}) is ' +
            'not supported yet. Position: ${position - 1}.';
            throw e;
        }

        return null;
    }

    function readValue(marker: Markers): Any {
        switch (marker) {
            case Markers.NULL:
                trace('Byte is ${String.fromCharCode(Markers.NULL)} (${Markers.NULL})');
                return readNull();
            case Markers.NOOP:
                trace('Byte is ${String.fromCharCode(Markers.NOOP)} (${Markers.NOOP})');
                return readNoop();
            case Markers.TRUE:
                trace('Byte is ${String.fromCharCode(Markers.TRUE)} (${Markers.TRUE})');
                return readTrue();
            case Markers.FALSE:
                trace('Byte is ${String.fromCharCode(Markers.FALSE)} (${Markers.FALSE})');
                return readFalse();
            case Markers.INT8:
                trace('Byte is ${String.fromCharCode(Markers.INT8)} (${Markers.INT8})');
                trace('Known marker: ${Markers.INT8}');
                return readInt8();
            case Markers.UINT8:
                trace('Byte is ${String.fromCharCode(Markers.UINT8)} (${Markers.UINT8})');
                return readUInt8();
            case Markers.INT16:
                trace('Byte is ${String.fromCharCode(Markers.INT16)} (${Markers.INT16})');
                trace('Known marker: ${Markers.INT16}');
                return readInt16();
            case Markers.INT32:
                trace('Byte is ${String.fromCharCode(Markers.INT32)} (${Markers.INT32})');
                return readInt32();
            case Markers.INT64:
                trace('Byte is ${String.fromCharCode(Markers.INT64)} (${Markers.INT64})');
                trace('Known marker: ${Markers.INT64}');
                return readInt64();
            case Markers.FLOAT32:
                trace('Byte is ${String.fromCharCode(Markers.FLOAT32)} (${Markers.FLOAT32})');
                trace('Known marker: ${Markers.FLOAT32}');
                return readFloat32();
            case Markers.FLOAT64:
                trace('Byte is ${String.fromCharCode(Markers.FLOAT64)} (${Markers.FLOAT64})');
                trace('Known marker: ${Markers.FLOAT64}');
                return readFloat64();
            case Markers.HIGH_PRECISION_NUMBER:
                trace('Byte is ${String.fromCharCode(Markers.HIGH_PRECISION_NUMBER)} (${Markers.HIGH_PRECISION_NUMBER})');
                trace('Known marker: ${Markers.HIGH_PRECISION_NUMBER}');
                return readHighPrecisionNumber();
            case Markers.CHAR:
                trace('Byte is ${String.fromCharCode(Markers.CHAR)} (${Markers.CHAR})');
                trace('Known marker: ${Markers.CHAR}');
                return readChar();
            case Markers.STRING:
                trace('Byte is ${String.fromCharCode(Markers.STRING)} (${Markers.STRING})');
                return readString();
            default:
                return null;
        }
    }

    function char(int) {
        return String.fromCharCode(int);
    }

    function readContainerAndParameters(marker: Markers): Any {
        switch (marker) {
            // this 7 is actually the length of the string 'players'
            // It seems that we are skipping 1 bye and its not reading
            // the preceding type byte [U]
            // case 7:
            //     return 7;
            // Containers
            case Markers.ARRAY_START:
                trace('Byte is ${String.fromCharCode(Markers.ARRAY_START)} (${Markers.ARRAY_START})');
                return readArray();
            case Markers.OBJECT_START:
                trace('Byte is ${String.fromCharCode(Markers.OBJECT_START)} (${Markers.OBJECT_START})');
                return readObject();
            // Optimized format optional parameters
            case Markers.TYPE:
                trace(' ------- TYPE ------ ');
                trace('Byte is ${String.fromCharCode(Markers.TYPE)} (${Markers.TYPE})');
                trace('Known marker: ${Markers.TYPE}');
            case Markers.COUNT:
                trace(' ------- COUNT ------ ');
                trace('Byte is ${String.fromCharCode(Markers.COUNT)} (${Markers.COUNT})');
                trace('Known marker: ${Markers.COUNT}');
                // return readArray();
            default:
                return marker;
        }

        return null;
    }

    public static function decode(bytes: Bytes): Map<String, Any> {
        var decoder = new SlpDecoder(bytes);
        decoder.read();
        return decoder.metadata;
    }

}