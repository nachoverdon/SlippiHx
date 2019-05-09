package slippihx;

import unifill.Utf8;
import haxe.Resource;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.ds.Vector;
using StringTools;

class SJISConverter {
    private static var sjisData: BytesData;

    private static function twoBytesToUtf8(array: Array<UInt>): String {
        // https://stackoverflow.com/questions/33165171/c-shiftjis-to-utf8-conversion
        if (sjisData == null) sjisData = Resource.getBytes('sjisData').getData();

        final output = new Vector<Null<UInt>>(array.length * 3);
        var index = 0;

        while (index < array.length) {

            final section = array[index] >> 4;

            var offset: UInt;

            // This whole block apparently determines how many bytes the SJIS
            // has. For melee, these are always 2 bytes. Right?
            // https://github.com/project-slippi/project-slippi/wiki/Replay-File-Spec#game-start
            // 8 characters per name, 2 bytes per char = 16 bytes.
            if (section == 0x8) offset = 0x100;
            else if (section == 0x9) offset = 0x1100;
            else if (section == 0xE) offset = 0x2100;
            else offset = 0;

            if (offset != 0) {

                offset += (array[index] & 0xF) << 8;
                index++;

                if (index >= array.length) break;

            }

            offset += array[index++];
            offset = offset << 1;

            inline function getByte(pos: Int = 0): Int {
                return Bytes.fastGet(sjisData, offset + pos);
            }

            final unicode = (getByte() << 8 | getByte(1));

            if (unicode < 0x80) {

                output[index++] = unicode;

            } else if (unicode < 0x800) {

                output[index++] = 0xC0 | (unicode >> 6);
                output[index++] = 0x80 | (unicode & 0x3F);

            } else {

                output[index++] = 0xE0 | (unicode >> 12);
                output[index++] = 0x80 | ((unicode & 0xFFF) >> 6);
                output[index++] = 0x80 | (unicode & 0x3F);

            }

        }


        final resized = Bytes.alloc(index);

        for (i in 0...index) {

            resized.set(i, output[i] == null ? ' '.code : output[i]);

        }

        var str = Utf8.fromBytes(resized);

        return str.toString();
    }

    private static function convertChar(charCode: UInt): UInt {
        if (0xFF00 < charCode && charCode < 0xFF5F)
            return 0x0020 + (charCode - 0xFF00);

        if (0x3000 == charCode) return 0x0020;

        return charCode;
    }

    private static function toHalfWidth(string: String): String {
        var utf8 = new haxe.Utf8();

        for (char in string.split('')) {

            utf8.addChar(convertChar(char.charCodeAt(0)));

        }

        return utf8.toString();
    }

    public static function toUtf8(array: Array<UInt>): String {
        var i = 0;
        var string = '';

        while (i < array.length) {

            var char = twoBytesToUtf8([array[i], array[i + 1]]);
            string += char.trim();
            i += 2;

        }

        return toHalfWidth(string).trim();
    }
}