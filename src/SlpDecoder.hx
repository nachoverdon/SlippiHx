import haxe.io.BytesBuffer;
import haxe.Int32;
import haxe.Int64;
import haxe.io.Bytes;
import haxe.io.BytesData;
// import haxe.io.UInt8Array;

using byteConvert.ByteConvert;

class SlpDecoder {
    var bytes: Bytes;
    var position: Int;
    var data: Map<String, Any>;
    var metadata: Map<String, Any>;
    // var buffer: UInt8Array;

    public function new(bytes: Bytes) {
        this.bytes = bytes;
        position = 0;
    }

    public function parse(): Void {
        read();
    }

    public function getMetadata(): Map<String, Any> {
        return metadata;
    }

    public function getData(): Map<String, Any> {
        return data;
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
        // var test = bytes.getData();
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
        if (maybe_length != null && Std.is(maybe_length, Int)) {
            length = cast(maybe_length, Int); // Int32?
        } else {
            if (position >= bytes.length) return null;
            var e = 'UBJSON decoder - failed to read string length';
            throw e;
        }

        var pos = position;
        next(length);

        var string = bytes.getString(pos, length);
        // trace('String "$string" with length $length');
        return string;
    }

    function readObject(): Map<String, Any> {
        var object = new Map<String, Any>();

        if (position == 1) {
            data = object;
        }

        while (!isEndObject()) {
            var field = readString();
            var value = read();
            if (field == null) break; // eof
            object.set(field, value);
            // trace('field, value');
            // trace(field, value);

            if (field == 'metadata') {
                metadata = object;
            }

            if (value != null && Std.is(value, Map)) {
                trace('value is map');
                for (key in cast(value, Map<String, Dynamic>).keys()) {
                    trace('Key: [$key]');
                }
            }
        }

        next();

        return object;
    }

    function readArray(): Array<Any> {
        var array = new Array<Any>();

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
        // trace('Type is ${String.fromCharCode(type)} ($type)');

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
        // trace('[${String.fromCharCode(marker)}]: $marker');

        next();

        if (position >= bytes.length) {
            // trace('End of file.');
            return null;
        }

        var value = readValue(marker);
        if (value != null) return value;

        var other = readContainerAndParameters(marker);
        if (other != null) return other;

        if (position >= bytes.length) {
            // trace('End of file.');
        } else {
            trace('[${String.fromCharCode(marker)}] ($marker) at ${position - 1}');
            var e = 'UBJSON decoder - value type with marker [${String.fromCharCode(marker)}] (${marker}) is ' +
            'not supported yet. Position: ${position - 1}.';
            throw e;
        }

        return null;
    }

    function readValue(marker: Markers): Any {
        // trace('Byte is ${char(marker)} ($marker)');

        switch (marker) {
            // Types
            case Markers.NULL:
                return readNull();
            case Markers.NOOP:
                return readNoop();
            case Markers.TRUE:
                return readTrue();
            case Markers.FALSE:
                return readFalse();
            case Markers.INT8:
                return readInt8();
            case Markers.UINT8:
                return readUInt8();
            case Markers.INT16:
                return readInt16();
            case Markers.INT32:
                return readInt32();
            case Markers.INT64:
                return readInt64();
            case Markers.FLOAT32:
                return readFloat32();
            case Markers.FLOAT64:
                return readFloat64();
            case Markers.HIGH_PRECISION_NUMBER:
                return readHighPrecisionNumber();
            case Markers.CHAR:
                return readChar();
            case Markers.STRING:
                return readString();
            default:
                return null;
        }
    }

    function char(int) {
        if (int == null) {
            trace('Marker is null');
            return null;
        }
        return String.fromCharCode(int);
    }

    function readContainerAndParameters(marker: Markers): Any {
        // trace('Byte is ${char(marker)} ($marker)');
        switch (marker) {
            // this 7 is actually the length of the string 'players'
            // It seems that we are skipping 1 bye and its not reading
            // the preceding type byte [U]
            // case 7:
            //     return 7;
            // Containers
            case Markers.ARRAY_START:
                return readArray();
            case Markers.OBJECT_START:
                return readObject();
            // Optimized format optional parameters
            case Markers.TYPE:
                trace(' ------- TYPE ------ ');
            case Markers.COUNT:
                trace(' ------- COUNT ------ ');
                // return readArray();
            default:
                // debug();
                return marker;
        }

        return null;
    }

    function debug(before: UInt, after: UInt) {
        for (i in position-before...position+after) {
            if (i >= bytes.length) break;
            trace(char(bytes.get(i)));
        }
    }

    static function binaryToDecimal(n: Int) {
        var num = n;
        var decimal = 0;

        // Initializing base
        // value to 1, i.e 2^0
        var base = 1;

        var temp = num;
        while (temp > 0) {
            var last_digit = temp % 10;
            temp = Std.int(temp / 10);

            decimal += last_digit * base;

            base = base * 2;
        }

        return decimal;
    }

    static function toBinary(num: Int) {
        var binaryNum = new Array<Int>();

        var i = 0;
        while (num > 0)
        {
            binaryNum[i] = Std.int(num % 2);
            num = Std.int(num / 2);
            i++;
        }

        binaryNum.reverse();
        return binaryNum.join('');
    }

    static function flip(str: String) {
        trace('str: $str');
        var arr = str.split('');
        arr.reverse();
        trace(arr);
        return arr.join('');
    }

    public static function decode(bytes: Bytes): Map<String, Any> {
        var decoder = new SlpDecoder(bytes);
        decoder.read();
        return decoder.data;
    }

}