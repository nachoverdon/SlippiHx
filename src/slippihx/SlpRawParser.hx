package slippihx;

import haxe.Json;
import haxe.ds.Vector;
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
    var v1_4_0_0 = '1.4.0.0';
    var v1_5_0_0 = '1.5.0.0';
    var v2_0_0_0 = '2.0.0.0';
}

@:expose
@:keep
class SlpRawParser {

    /**
     * Returns the JSON's stringified parsed data.
     * @param raw A vector of UInt, containing game data.
     * @return String JSON with the data
     */
    public static function toJson(raw: Vector<UInt>): String {
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
                var nv = va[i];
                var nr = ra[i];
                if (nv > nr) return true;
                if (nr > nv) return false;
            }

            return true;
        }

        function readUInt32(pos: Int): UInt {
            return raw[pos] << 24 | raw[pos + 1] << 16 | raw[pos + 2] << 8 | raw[pos + 3];
        }

        function readInt16(pos: Int): Int {
            return raw[pos] << 8 | raw[pos + 1];
        }

        function readEventPayloads(): SlpEventsPayloads {
            if (raw[0] != EVENT_PAYLOADS)
                throw '${StringTools.hex(raw[0])} is not EVENT_PAYLOADS';

            return {
                eventPayloads: raw[1],
                gameStart: readInt16(3),
                preFrameUpdate: readInt16(6),
                postFrameUpdate: readInt16(9),
                gameEnd: readInt16(12)
            };
        }

        function readGameStarts(pos: Int): SlpGameStart {
            inline function getInfoPlayersAt(start: Int, offsetPerPlayer: Int) {
                return {
                    p1: raw[start],
                    p2: raw[start + offsetPerPlayer],
                    p3: raw[start + (offsetPerPlayer * 2)],
                    p4: raw[start + (offsetPerPlayer * 3)]
                };
            }

            if (raw[pos] != GAME_START)
                throw '${StringTools.hex(raw[pos])} is not GAME_START';

            var version = {
                major: raw[pos + 1],
                minor: raw[pos + 2],
                build: raw[pos + 3],
                revision: raw[pos + 4]
            };

            // End is 5 + 312
            var gameInfoBlock = new Vector<UInt>(312);
            Vector.blit(raw, pos + 0x5, gameInfoBlock, 0, 312);
            var isTeams = raw[pos + 0xD] == 1;
            var stage = readInt16(pos + 0x13);
            var randomSeed = readUInt32(pos + 0x13D);
            // TODO: p3 and p4 seem to be erroneous.
            var externalCharacterIds =  getInfoPlayersAt(pos + 0x65, 0x24);
            var playerTypes =  getInfoPlayersAt(pos + 0x66, 0x24);
            var stockStartCounts =  getInfoPlayersAt(pos + 0x67, 0x24);
            var characterColors =  getInfoPlayersAt(pos + 0x68, 0x24);
            var teamIds =  getInfoPlayersAt(pos + 0x6E, 0x24);

            // 1.0.0.0
            // These are supposed to be UInt32, but the only possible values are
            // 0, 1 and 2 for None, UCF, Dween respectively, so this is faster.
            var dashbackFixes = isCompatible(version, v1_0_0_0) ? getInfoPlayersAt(pos + 0x144, 0x8) : null;
            var shieldDropFixes = isCompatible(version, v1_0_0_0) ? getInfoPlayersAt(pos + 0x145, 0x8) : null;
            // 1.3.0.0
            // TODO: Implements this.
            var nametags = isCompatible(version, v1_3_0_0) ? null : null;
            // 1.5.0.0
            var pal = isCompatible(version, v1_5_0_0) ? raw[pos + 0x1A1] == 1 : null;
            var frozenPS = isCompatible(version, v2_0_0_0) ? raw[pos + 0x1A2] == 1 : null;

            return {
                version: version,
                gameInfoBlock: gameInfoBlock,
                isTeams: isTeams,
                stage: stage,
                externalCharacterIds: externalCharacterIds,
                playerTypes: playerTypes,
                stockStartCounts: stockStartCounts,
                characterColors: characterColors,
                teamIds: teamIds,
                randomSeed: randomSeed,
                dashbackFixes: dashbackFixes,
                shieldDropFixes: shieldDropFixes,
                nametags: nametags,
                pal: pal,
                frozenPS: frozenPS
            };
        }

        var eventPayloads = readEventPayloads();
        // TODO: Delete this
        for (i in eventPayloads.eventPayloads-5...eventPayloads.eventPayloads+0x1A1+1) {
            trace('[${raw[i]}] @${i - 14} ${StringTools.hex(i - 14)}');
        }
        var gameStarts = readGameStarts(eventPayloads.eventPayloads + 1);
        var position = eventPayloads.eventPayloads - 1; // 0x36 GAME_STARTS

        // TODO: Implement all, type.
        var json = { // :SlpRaw
            eventPayloads:  eventPayloads,
            gameStart: gameStarts,
            frames: [{
                preFrameUpdate: {},
                postFrameUpdate: {},
            }],
            gameEnd: {}
        }

        // TODO: JSON encodes UInts as Ints (32Bits, 16 still work as intended).
        return Json.stringify(json, null, '\t');
    }

}