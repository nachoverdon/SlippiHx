package slippihx;

import haxe.io.Bytes;
import haxe.Json;
import slippihx.SlpTypes;

@:expose
@:keep
@:enum
abstract Commands(Int) from Int to Int
{
    var EVENT_PAYLOADS = 0x35;
    var GAME_START = 0x36;
    var PRE_FRAME_UPDATE = 0x37;
    var POST_FRAME_UPDATE = 0x38;
    var GAME_END = 0x39;
}

@:expose
@:keep
@:enum
abstract Versions(String) from String to String
{
    // var v0_1_0_0 = '0.1.0.0';
    var v0_2_0_0 = '0.2.0.0';
    var v1_0_0_0 = '1.0.0.0';
    var v1_2_0_0 = '1.2.0.0';
    var v1_3_0_0 = '1.3.0.0';
    var v1_5_0_0 = '1.5.0.0';
}

@:expose
@:keep
class SlpRawParser {

    /**
     * Returns the JSON's stringified parsed data.
     * @param raw An array of UInt, containing game data.
     * @return String JSON with the data
     */
    public static function toJson(raw: Array<UInt>): String {
        function isCompatible(version: SlpVersion, requires: Versions): Bool {
            function toSlpVersion(ver: Versions): SlpVersion {
                var arr = '$ver'.split('.');
                return {
                    major: Std.parseInt(arr[0]),
                    minor: Std.parseInt(arr[1]),
                    build: Std.parseInt(arr[2]),
                    revision: Std.parseInt(arr[3])
                };
            }
            var v = version;
            var r = toSlpVersion(requires);
            var va = [v.major, v.minor, v.build, v.revision];
            var ra = [r.major, r.minor, r.build, r.revision];

            for (i in 0...4) {
                trace('i $i');
                var nv = va[i];
                var nr = ra[i];
                if (nv > nr) return true;
                if (nr > nv) return false;
            }

            return true;
        }

        function toBytes(from: Int, to: Int): Bytes {
            var bytes = Bytes.alloc(to - from);

            for (i in from...to) bytes.set(i - from, raw[i]);

            return bytes;
        }

        function reverse(bytes: Bytes) {
            var b = Bytes.alloc(bytes.length);

            for (i in 0...b.length) b.set(b.length - 1 - i, bytes.get(i));

            return b;
        }

        function readEventPayloads(): SlpEventsPayloads {
            if (raw[0] != EVENT_PAYLOADS)
                throw '${StringTools.hex(raw[0])} is not EVENT_PAYLOADS';

            var b = toBytes(0, raw[1] + 1);

            return {
                eventPayloads: raw[1],
                gameStart: b.getUInt16(3),
                preFrameUpdate: b.getUInt16(6),
                postFrameUpdate: b.getUInt16(9),
                gameEnd: b.getUInt16(12)
            };
        }

        function readGameStarts(pos: Int): Dynamic { // :SlpGameStart
            if (raw[pos] != GAME_START)
                throw '${StringTools.hex(raw[pos])} is not GAME_START';

            var version = {
                major: raw[pos + 1],
                minor: raw[pos + 2],
                build: raw[pos + 3],
                revision: raw[pos + 4]
            };

            // End is 5 + 312
            var gameInfoBlock = raw.slice(pos + 0x5, pos + 0x5 + 312);
            var b = reverse(toBytes(pos + 0x13, pos + 0x15));
            var stage = b.getUInt16(0);
            // var stage = haxe.io.UInt16Array.fromBytes(b, 0).get(0);
            b = toBytes(pos + 0x13D, pos + 0x13D + 4);
            var randomSeed = b.getInt32(0); // Has to be UInt32

            return {
                version: version,
                gameInfoBlock: gameInfoBlock,
                isTeams: raw[pos + 0xD] == 1 ? true : false,
                stage: stage,
                // externalCharacterId: ,
                // playerTypes: ,
                // stockStartCounts: ,
                // characterColors: ,
                // teamIds: ,
                randomSeed: randomSeed,
                // dashbackFixes: ,
                // nametags: ,
                // pal:
            };
        }

        var eventPayloads = readEventPayloads();
        for (i in eventPayloads.eventPayloads-5...eventPayloads.eventPayloads+0x1A1+1) {
            trace('[${raw[i]}] @${i - 14} ${StringTools.hex(i - 14)}');
        }
        var gameStarts = readGameStarts(eventPayloads.eventPayloads + 1);
        var position = eventPayloads.eventPayloads - 1; // 0x36 GAME_STARTS

        var json = { // :SlpRaw
            eventPayloads:  eventPayloads,
            gameStart: gameStarts,
            frames: [{
                preFrameUpdate: {},
                postFrameUpdate: {},
            }],
            gameEnd: {}
        }


        return Json.stringify(json);
    }

}