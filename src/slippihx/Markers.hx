package slippihx;

@:enum
abstract Markers(Int) from Int to Int
{
    // Values
    var NULL = 'Z'.code;
    var NOOP = 'N'.code;
    var TRUE = 'T'.code;
    var FALSE = 'F'.code;
    var INT8 = 'i'.code;
    var UINT8 = 'U'.code;
    var INT16 = 'I'.code;
    var INT32 = 'l'.code;
    var INT64 = 'L'.code;
    var FLOAT32 = 'd'.code;
    var FLOAT64 = 'D'.code;
    var HIGH_PRECISION_NUMBER = 'H'.code;
    var CHAR = 'C'.code;
    var STRING = 'S'.code;
    // Container
    var ARRAY_START = '['.code;
    var ARRAY_END = ']'.code;
    var OBJECT_START = '{'.code;
    var OBJECT_END = '}'.code;
    // Optimized format optional parameters
    var TYPE = '$'.code;
    var COUNT = '#'.code;
}