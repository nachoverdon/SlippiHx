package slippihx;

import haxe.io.Bytes;
// import haxe.Int32;
import slippihx.SlpTypes;

@:expose
@:keep
class SlpDecoder {
	var bytes: Bytes;
    var position: Int;
    // public var data(default, null): Map<String, Dynamic>;
    public var data(default, null): SlpData;
	public var raw(default, null): Array<UInt>;
	// public var metadata(default, null): Map<String, Dynamic>;
	public var metadata(default, null): SlpMetadata;

    public function new(bytes: Bytes, ?shouldParse: Bool = true) {
        this.bytes = bytes;
        position = 0;

		if (shouldParse) {
			parse();
		}
    }

	#if sys
	public static function fromFile(path: String, ?parse: Bool): SlpDecoder {
		return new SlpDecoder(
			sys.io.File.read(haxe.io.Path.normalize(path), true).readAll(), parse
		);
	}
	#end

	static function showMarker(marker: Int): String {
		return '>${String.fromCharCode(marker)}< ($marker)';
	}

	public function parse() {
		// parse data
		_setData(readObject());
	}

	function _setData(obj: Map<String, Dynamic>) {
		_setMetadata(obj.get('metadata'));
		data = {
			raw: obj.get('raw'),
			metadata: metadata
		}
		raw = data.raw;
	}

	function _setMetadata(obj: Map<String, Dynamic>) {

		var lastFrame = cast(obj.get('lastFrame'), Int);
		var consoleNick = obj.exists('consoleNick')
			? cast(obj.get('consoleNick'), String)
			: null;
		var players: SlpPlayers = _setPlayers(obj.get('players'));

		metadata = {
			startAt: cast(obj.get('startAt'), String),
			lastFrame: lastFrame,
			players: players,
			playedOn: cast(obj.get('playedOn'), String),
			duration: lastFrame + 124,
			consoleNick: consoleNick
		}
	}

	function _setPlayers(obj: Map<String, Dynamic>): SlpPlayers {
		var players: SlpPlayers = new SlpPlayers();

		for (key in obj.keys()) {

			var tempPlayer = cast(obj.get(key), Map<String, Dynamic>);
			var player: SlpPlayer = _setPlayer(tempPlayer);
			players.set(Std.parseInt(key), player);
		}

		return players;
	}

	function _setPlayer(obj: Map<String, Dynamic>): SlpPlayer {
		var names: Map<String, String> =  new Map<String, String>();

		if (obj.exists('names')) {
			var tempNames = cast(obj.get('names'), Map<String, Dynamic>);

			for (key in tempNames.keys()) {
				names.set(key, cast(tempNames.get(key), String));
			}
		}

		var tempChar: Map<String, Dynamic> = obj.get('characters');
		var characters: Map<Int, Int> = new Map<Int, Int>();

		for (key in tempChar.keys()) {
			characters.set(Std.parseInt(key), tempChar.get(key));
		}

		var player: SlpPlayer = {
			names: names,
			characters: characters
		}

		return player;
	}

	// Reads a byte at the current or given position
	function readByte(?pos = null): Int {
        if (pos == null) pos = position;

		return bytes.get(pos);
    }

	// Advances the position by 1 or by the given amount
	// Returns false if end of file
	function next(?amount: Int = 1): Bool {
        if (position + amount >= bytes.length) return false;

		position += amount;

		return true;
    }

	function isObjectEnd(pos: Int = null): Bool {
		if (pos == null) pos = position;

		return readByte(pos) == Markers.OBJECT_END;
	}

	function isArrayEnd(pos: Int = null): Bool {
		if (pos == null) pos = position;

		return readByte(pos) == Markers.ARRAY_END;
	}

	function readBytes(size: Int): Bytes {
		var bytes = Bytes.alloc(size);

		for (i in 0...size) {
			bytes.set(size - i - 1, readByte());
			next();
		}

		return bytes;
	}

	function readUInt8(): UInt {
		var number: UInt = cast(readByte(), UInt);
		next();
		return number;
	}

	// TODO: Fix this, it doesn't work. Possibily even remove it, since it's not
	// used atm, unless a new metadata field of type Int16 is added.
	function readInt16(): Int {
		return readBytes(2).getInt32(0);
	}

	function readInt32(): Int {
		return readBytes(4).getInt32(0);
	}

	function readFloat32(): Float {
		var number: Float = bytes.getFloat(position);
		next(4);
		return number;
	}

	function readInt(): Null<Int> {
		var marker: Int = readByte();
		next();

		switch marker {
			// INT8 and INT64 are not implemented in Slippi
            case Markers.UINT8:
                return readUInt8();
            case Markers.INT16:
                return readInt16();
            case Markers.INT32:
                return readInt32();
            default:
                return null;
				// next(-2);
				// return readInt();
				// if (position == bytes.length-1) trace('EOF.');
				// trace('bytesLength: ${bytes.length}');
				// trace('pos', position, showMarker(marker));
				// for (i in 0...position+10) {
				// 	var b = bytes.get(i);
				// 	if (i >= position-25 || b == Markers.ARRAY_END
				// 	|| b == Markers.OBJECT_END || b == Markers.ARRAY_START
				// 	|| b == Markers.OBJECT_START ) {
				// 		trace(i, showMarker(b));
				// 	}
				// }
				// trace('pos', position, showMarker(marker));
                // return null;
		}

	}

	function readString(): String {
		var length: Int = readInt(); // readInt should next(X) depending on type
		var string: String = bytes.getString(position, length);

		next(length);

		return string;
	}

	function readType(): Null<Int> {
		if (readByte() != Markers.TYPE) return null;

		next();

		return readByte();
	}

	function readCount(): Null<Int> {
		if (readByte() != Markers.COUNT) return null;

		next();

		return readInt();
	}

	// TODO: Raw is guaranteed to be a 'Vector' and have a type and a size if the
	// replay file is 'complete' and not being read in real-time.
	// Metadata might incorporate some array in the future.
	// Do some kind of readList function that first determines whether the
	// list has a predefined size (Vector) or not (Array) and go from there.
	// readList() -> readVector || readArray
	function readArray(): Array<Dynamic> {
		var array: Array<Dynamic>;
		var type = readType();
		var readFunction = readValue;

		if (type != null) next();

		var count = readCount();

		if (count == null) {
			array = new Array<Dynamic>();
			// I'm leaving this commented for the time being.
			// while (!isArrayEnd()) {
			// 	var value: Dynamic = readValue();
			// 	array.push(value);
			// }

		} else {

			switch type {
				case Markers.TRUE:
					array = new Array<Bool>();
					readFunction = function() {return true;};

				case Markers.FALSE:
					array = new Array<Bool>();
					readFunction = function() {return false;};

				case Markers.UINT8:
					array = new Array<UInt>();
					readFunction = readUInt8;

				case Markers.INT16:
					array = new Array<Int>();
					readFunction = readInt16;

				case Markers.INT32:
					array = new Array<Int>();
					readFunction = readInt32;

				case Markers.FLOAT32:
					array = new Array<Float>();
					readFunction = readFloat32;

				case Markers.STRING:
					array = new Array<String>();
					readFunction = readString;

				case Markers.OBJECT_START:
					array = new Array<Map<String, Dynamic>>();
					readFunction = readObject;

				case Markers.ARRAY_START:
					array = new Array<Array<Dynamic>>();
					readFunction = readArray;

				default:
					array = new Array<Dynamic>();
			}

			for (i in 0...count) {
				var value: Dynamic = readFunction();
				array[i] = value;
			}
		}

		return array;
	}

	function readObject(): Map<String, Dynamic> {
		// NOT YET IMPLEMENTED IN SLIPPI, BUT SHOULD GET TYPE [$] AND COUNT [#]
		var object = new Map<String, Dynamic>();
		next();

		while (!isObjectEnd()) {
			var field: String = readString();
			var value: Dynamic = readValue();
			object.set(field, value);

			if (field == 'raw') raw = value;
			if (field == 'metadata') cast(value, Map<String, Dynamic>);
		}


		next();

		return object;
	}

	function readValue(): Dynamic {
		var marker: Int = readByte();

		next();

		switch marker {
            // case Markers.TRUE:
			// 	next();
            //     return true;
            // case Markers.FALSE:
			// 	next();
            //     return false;
            case Markers.UINT8:
                return readUInt8();
            // case Markers.INT16:
            //     return readInt16();
            case Markers.INT32:
                return readInt32();
            // case Markers.FLOAT32:
            //     return readFloat32();
            case Markers.STRING:
                return readString();
			case Markers.ARRAY_START:
                return readArray();
            case Markers.OBJECT_START:
				// This next fixes every case?
				next(-1);
                return readObject();
			default:
				throw 'Value not supported by Slippi: ${showMarker(marker)}';
		}
	}
}