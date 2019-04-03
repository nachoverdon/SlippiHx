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
class SlpRawParser {

    /**
     * Returns the JSON's stringified parsed data.
     * @param raw An array of UInt, containing game data.
     * @return String JSON with the data
     */
    public static function toJson(raw: Array<UInt>): String {
        function readEventPayloads(): SlpEventsPayloads {
            if (raw[0] != EVENT_PAYLOADS)
                throw '${StringTools.hex(raw[0])} is not $EVENT_PAYLOADS';

            var len = raw[1] + 1;
            var b = Bytes.alloc(len);


            for (i in 0...len) b.set(i, raw[i]);

            return {
                eventPayloads: raw[1],
                gameStart: b.getUInt16(3),
                preFrameUpdate: b.getUInt16(6),
                postFrameUpdate: b.getUInt16(9),
                gameEnd: b.getUInt16(12)
            };
        }

        var eventPayloads = readEventPayloads();
        var position = eventPayloads.eventPayloads;

        var json = { // :SlpRaw
            eventPayloads:  eventPayloads,
            gameStart: {},
            frames: [{
                preFrameUpdate: {},
                postFrameUpdate: {},
            }],
            gameEnd: {}
        }


        return Json.stringify(json);
    }

}