import sys.io.File;

class Main {
	static function main() {
		// var file = File.read('test/fox.slp', true);
		var file = File.read('test/icsz.slp', true);
		file.bigEndian = true;
		var bytes = file.readAll();
		// var file = File.getBytes('test/fox.slp');
		var slp = SlippiDecoder.fromFile('test/icsz.slp');
		// decoder.parse();
		var slpData = slp.data;
		var metadata = slp.metadata;
		// trace(metadata);
		trace(metadata.get('lastFrame'));
		// trace(slpData);
		// trace(metadata.get('players'));

		// for (key in metadata.keys()) {
		// 	trace(key);
		// 	// trace(metadata.get(key));
		// }

		// File.write('utf8.txt').writeString(Utf8.encode(file));
		// File.write('test.txt', true).writeString(txt.getString(0, txt.length));
	}
}
