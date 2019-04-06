# SlippiHx

```haxe
import SlpDecoder;

class Main {
    var slp = SlpDecoder.fromFile('replay.slp');
    var metadata: SlpMetadata = slp.metadata;
    trace(metadata.startAt);
    // >>   2019-03-29T19:52:11Z
    var rawData: Vector<UInt> = slp.raw;
    trace(rawData);
    // Vector bigger than Leffen winning EVO.
}
```

On ActionScript3, Flash and JavaScript `SlpDecoder.fromFile()` is not available because it uses the the filesystem to read a file, and those targets don't have support for that out of the box.
For AS3 and Flash, you can use [OpenFL](https://www.openfl.org/).
For JavaScript, you can use [hxnodejs](https://lib.haxe.org/p/hxnodejs/) to read files and then:

```haxe
// Must include '-lib hxnodejs'
import SlpDecoder;

class Main {
    var bytes = sys.io.File.read('replay.slp', true).readAll();
    var slp = new SlpDecoder(bytes);
    // Use SlpDecoder normally...
}
```
