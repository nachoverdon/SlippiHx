package slippihx;

import haxe.Json;
import slippihx.SlpTypes;
using StringTools;

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

    private static function readUInt16(a: Array<UInt>, pos: Int): UInt {
        return a[pos] << 8 | a[pos + 1];
    }

    private inline static function hex(element: UInt): String {
        return StringTools.hex(element);
    }

    /**
     * Reads events payload's length in bytes.
     * @param raw The raw element from a replay file as Array<UInt>.
     * @return SlpEventsPayloads
     */
    public static function readEventPayloads(raw: Array<UInt>): SlpEventsPayloads {
        if (raw[0] != EVENT_PAYLOADS) throw '${hex(raw[0])} is not EVENT_PAYLOADS';

        return {
            eventPayloads: raw[1],
            gameStart: readUInt16(raw, 3),
            preFrameUpdate: readUInt16(raw, 6),
            postFrameUpdate: readUInt16(raw, 9),
            gameEnd: readUInt16(raw, 12)
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
    private static function getPlayersInfoAt(raw: Array<UInt>, start: Int, offset: Int): SlpPlayersInfo {
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

    private static function getNametags(raw: Array<UInt>, pos: Int, offset: Int): SlpNametags {

        inline function getNametagBytes(pos: Int): Array<UInt> {
            return [for (i in 0...16) raw[pos + i]];
        }

        inline function getNametag(pos: Int): String {
            var bytes = getNametagBytes(pos);
            // TODO: Figure out how to get a string of length 8, without all
            // that noisy characters that appear.
            // return SJISConverter.toUtf8(bytes).substr(0, 4).trim();
            var str = '';

            for (char in SJISConverter.toUtf8(bytes).substr(0, 4).split('')) {
                if (char.fastCodeAt(0) != 0) str += char;
            }

            return str.trim();
        }

        // offset: 0x10
        return {
            p1: getNametag(pos),
            p2: getNametag(pos + offset),
            p3: getNametag(pos + (offset * 2)),
            p4: getNametag(pos + (offset * 3))
        };
    }

    /**
     * Reads the data from the Game Start event
     * @param raw The raw element from a replay file as Array<UInt>.
     * @param pos Index of the GAME_START command byte.
     * @return SlpGameStart
     */
    public static function readGameStart(raw: Array<UInt>, pos: Int): SlpGameStart {
        if (raw[pos] != GAME_START) throw '${hex(raw[pos])} is not GAME_START';

        var version = getVersion(raw, pos + 1);

        // End is 5 + 312
        // TODO: This should be a Vector, so make it a Vector once there's a
        // solution for the JSON not allowing Vectors problem.
        // var gameInfoBlock = new Vector<UInt>(312);
        // Vector.blit(raw, pos + 0x5, gameInfoBlock, 0, 312);
        var gameInfoBlock = [for (i in 0...312) raw[pos + 0x5 + i]];
        var isTeams = raw[pos + 0xD] == 1;
        var stage = readUInt16(raw, pos + 0x13);
        var randomSeed = readUInt32(raw, pos + 0x13D);
        // TODO: p3 and p4 seem to be erroneous.
        var externalCharacterIds =  getPlayersInfoAt(raw, pos + 0x65, 0x24);
        var playerTypes =  getPlayersInfoAt(raw, pos + 0x66, 0x24);
        var stockStartCounts =  getPlayersInfoAt(raw, pos + 0x67, 0x24);
        var characterColors =  getPlayersInfoAt(raw, pos + 0x68, 0x24);
        var teamIds =  getPlayersInfoAt(raw, pos + 0x6E, 0x24);

        // 1.0.0.0
        // These are supposed to be UInt32, but the only possible values are
        // 0, 1 and 2 for None, UCF, Dween respectively, so this is faster.
        var dashbackFixes = isCompatible(version, v1_0_0_0) ? getPlayersInfoAt(raw, pos + 0x144, 0x8) : null; // 0x141
        var shieldDropFixes = isCompatible(version, v1_0_0_0) ? getPlayersInfoAt(raw, pos + 0x148, 0x8) : null; // 0x145

        // 1.3.0.0
        // TODO: This doesn't work as intended, as it is not returning the
        // expected string. Fix decoding of ShiftJIS, etc...
        var nametags = isCompatible(version, v1_3_0_0) ? getNametags(raw, pos + 0x161, 0x10) : null;
        // TODO: Delete trace
        trace('nametags', nametags.p1, nametags.p2, nametags.p3, nametags.p4);

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
        // for (i in eventPayloads.eventPayloads-5...eventPayloads.eventPayloads+0x1A1+1) {
        //     trace('[${raw[i]}] @${i - 14} ${hex(i - 14)}');
        // }
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