package slippihx;

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
    var v1_4_0_0 = '1.4.0.0';
    var v1_5_0_0 = '1.5.0.0';
    var v2_0_0_0 = '2.0.0.0';
}

@:expose
@:keep
class SlpRawParser {

    /**
     * Checks if a feature is compatible with the required version.
     * @param version The version of the replay.
     * @param requires The required version to check against.
     * @return Bool Returns true if the replay is compatible with the required
     * version.
     */
    public static function isCompatible(version: SlpVersion, requires: Versions): Bool {
        var req = '$requires'.split('.');
        var r: SlpVersion = {
            major: Std.parseInt(req[0]),
            minor: Std.parseInt(req[1]),
            build: Std.parseInt(req[2]),
            revision: Std.parseInt(req[3])
        };
        var va = [version.major, version.minor, version.build, version.revision];
        var ra = [r.major, r.minor, r.build, r.revision];

        for (i in 0...4) {
            var nv = va[i];
            var nr = ra[i];
            if (nv > nr) return true;
            if (nr > nv) return false;
        }

        return true;
    }

    private static function readUInt32(a: Array<UInt>, pos: Int): UInt {
        return a[pos] << 24 | a[pos + 1] << 16 | a[pos + 2] << 8 | a[pos + 3];
    }

    private static function readInt16(a: Array<UInt>, pos: Int): Int {
        return a[pos] << 8 | a[pos + 1];
    }

    /**
     * Reads events payload's length in bytes.
     * @param raw The raw element from a replay file as Array<UInt>.
     * @return SlpEventsPayloads
     */
    public static function readEventPayloads(raw: Array<UInt>): SlpEventsPayloads {
        if (raw[0] != EVENT_PAYLOADS)
            throw '${StringTools.hex(raw[0])} is not EVENT_PAYLOADS';

        return {
            eventPayloads: raw[1],
            gameStart: readInt16(raw, 3),
            preFrameUpdate: readInt16(raw, 6),
            postFrameUpdate: readInt16(raw, 9),
            gameEnd: readInt16(raw, 12)
        };
    }

    /**
     * Fetch the players information at the given point of the raw data.
     * @param raw The raw element from a replay file as Array<UInt>.
     * @param start Index of the first element in the raw data.
     * @param offset The amount of elements to skip to read the next player's
     * data.
     * @return SlpPlayersInfo
     */
    public static function getInfoPlayersAt(raw: Array<UInt>, start: Int, offset: Int): SlpPlayersInfo {
        return {
            p1: raw[start],
            p2: raw[start + offset],
            p3: raw[start + (offset * 2)],
            p4: raw[start + (offset * 3)]
        };
    }

    private static function getVersion(raw: Array<UInt>, pos: Int): SlpVersion {
        return {
            major: raw[pos],
            minor: raw[pos + 1],
            build: raw[pos + 2],
            revision: raw[pos + 3]
        };
    }

    /**
     * Reads the data from the Game Start event
     * @param raw The raw element from a replay file as Array<UInt>.
     * @param pos Index of the GAME_START command byte.
     * @return SlpGameStart
     */
    public static function readGameStart(raw: Array<UInt>, pos: Int): SlpGameStart {
        if (raw[pos] != GAME_START)
            throw '${StringTools.hex(raw[pos])} is not GAME_START';

        var version = getVersion(raw, pos + 1);

        // End is 5 + 312
        // TODO: This should be a Vector, so make it a Vector once there's a
        // solution for the JSON not allowing Vectors problem.
        // var gameInfoBlock = new Vector<UInt>(312);
        // Vector.blit(raw, pos + 0x5, gameInfoBlock, 0, 312);
        var gameInfoBlock = new Array<UInt>();
        for (i in 0...312) gameInfoBlock[i] = raw[pos + 0x5 + i];
        var isTeams = raw[pos + 0xD] == 1;
        var stage = readInt16(raw, pos + 0x13);
        var randomSeed = readUInt32(raw, pos + 0x13D);
        // TODO: p3 and p4 seem to be erroneous.
        var externalCharacterIds =  getInfoPlayersAt(raw, pos + 0x65, 0x24);
        var playerTypes =  getInfoPlayersAt(raw, pos + 0x66, 0x24);
        var stockStartCounts =  getInfoPlayersAt(raw, pos + 0x67, 0x24);
        var characterColors =  getInfoPlayersAt(raw, pos + 0x68, 0x24);
        var teamIds =  getInfoPlayersAt(raw, pos + 0x6E, 0x24);

        // 1.0.0.0
        // These are supposed to be UInt32, but the only possible values are
        // 0, 1 and 2 for None, UCF, Dween respectively, so this is faster.
        var dashbackFixes = isCompatible(version, v1_0_0_0) ? getInfoPlayersAt(raw, pos + 0x144, 0x8) : null;
        var shieldDropFixes = isCompatible(version, v1_0_0_0) ? getInfoPlayersAt(raw, pos + 0x145, 0x8) : null;
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

    /**
     * Returns the JSON's stringified parsed data.
     * @param raw An Array of UInt, containing game data.
     * @return String JSON with the data
     */
    public static function toJson(raw: Array<UInt>): String {
        var eventPayloads = readEventPayloads(raw);
        // TODO: Delete this
        for (i in eventPayloads.eventPayloads-5...eventPayloads.eventPayloads+0x1A1+1) {
            trace('[${raw[i]}] @${i - 14} ${StringTools.hex(i - 14)}');
        }
        var gameStart = readGameStart(raw, eventPayloads.eventPayloads + 1);
        var position = eventPayloads.eventPayloads - 1; // 0x36 GAME_STARTS

        // TODO: Implement all, type.
        var json = { // :SlpRaw
            eventPayloads:  eventPayloads,
            gameStart: gameStart,
            frames: [{
                preFrameUpdate: {},
                postFrameUpdate: {},
            }],
            gameEnd: {}
        }
        // TODO: JSON encodes UInts as Ints (32Bits, 16 still work as intended).
        // tink_json seems to work correctly out of the box. use that instead?
        // Still not working on python? https://github.com/haxetink/tink_json/issues/58
        // Now the problem are Vectors, they are not supported. Use Array in the
        // mean time.
        // trace(tink.Json.stringify({test: gameStart.randomSeed}));
        return tink.Json.stringify(json);
        // return Json.stringify(json, null, '\t');
    }

}