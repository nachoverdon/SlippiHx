import sys.io.File;
import haxe.Utf8;

class Main {
	static function main() {
		trace('----');
		trace('@${String.fromCharCode(7)}@');
		trace('----');
		var file = File.read('test/fox.slp', true);
		file.bigEndian = true;
		var bytes = file.readAll();
		// var file = File.getBytes('test/fox.slp');
		var metadata = new SlpDecoder(bytes).getMetadata();

		trace(metadata.get('lastFrame'));

		// for (key in metadata.keys()) {
		// 	trace(key);
		// 	// trace(metadata.get(key));
		// }

		// File.write('utf8.txt').writeString(Utf8.encode(file));
		// File.write('test.txt', true).writeString(txt.getString(0, txt.length));
	}
}
