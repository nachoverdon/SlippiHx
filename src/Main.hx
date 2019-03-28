import sys.io.File;
import haxe.Utf8;

class Main {
	static function main() {
		// var file = File.read('test/fox.slp', true);
		var file = File.read('test/falco.slp', true);
		file.bigEndian = true;
		var bytes = file.readAll();
		// var file = File.getBytes('test/fox.slp');
		var decoder = new SlpDecoder(bytes);
		decoder.parse();
		var slpData = cast(decoder.getData(), Map<String, Dynamic>);
		var metadata = cast(decoder.getMetadata().get('metadata'), Map<String, Dynamic>);
		trace(metadata);
		trace(metadata.get('lastFrame'));
		trace(slpData);

		// for (key in metadata.keys()) {
		// 	trace(key);
		// 	// trace(metadata.get(key));
		// }

		// File.write('utf8.txt').writeString(Utf8.encode(file));
		// File.write('test.txt', true).writeString(txt.getString(0, txt.length));
	}
}
