# SlippiHx

```haxe
    import SlpDecoder;

    class Main {
        var slp = SlpDecoder.fromFile('replay.slp');
        var metadata: SlpMetadata = slp.metadata;
        trace(metadata.startAt);
        // >>   2019-03-29T19:52:11Z
        var rawData: Array<UInt> = slp.raw;
        trace(rawData);
        // Array bigger than Leffen winning EVO.
    }
```
