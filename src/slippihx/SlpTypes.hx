package slippihx;

typedef SlpData = {
    var raw: Array<UInt>;
    var metadata: SlpMetadata;
}

typedef SlpMetadata = {
    var startAt: String;
    var lastFrame: Int;
    var players: SlpPlayers;
    var playedOn: String;
    var duration: Int;
}

typedef SlpPlayers = Map<Int, SlpPlayer>;

typedef SlpPlayer = {
    var names: Dynamic; // Should be string? wtf
    var characters: Map<Int, Int>;
}

// typedef SlpCharacterFrames = {
//     @:optional var MARIO: Int;
//     @:optional var FOX: Int;
//     @:optional var CAPTAIN_FALCON: Int;
//     @:optional var DONKEY_KONG: Int;
//     @:optional var KIRBY: Int;
//     @:optional var BOWSER: Int;
//     @:optional var LINK: Int;
//     @:optional var SHEIK: Int;
//     @:optional var NESS: Int;
//     @:optional var PEACH: Int;
//     @:optional var POPO: Int;
//     @:optional var NANA: Int;
//     @:optional var PIKACHU: Int;
//     @:optional var SAMUS: Int;
//     @:optional var YOSHI: Int;
//     @:optional var JIGGLYPUFF: Int;
//     @:optional var MEWTWO: Int;
//     @:optional var LUIGI: Int;
//     @:optional var MARTH: Int;
//     @:optional var ZELDA: Int;
//     @:optional var YOUNG_LINK: Int;
//     @:optional var DR_MARIO: Int;
//     @:optional var FALCO: Int;
//     @:optional var PICHU: Int;
//     @:optional var GAME_AND_WATCH: Int;
//     @:optional var GANONDORF: Int;
//     @:optional var ROY: Int;
//     @:optional var MASTER_HAND: Int;
//     @:optional var CRAZY_HAND: Int;
//     @:optional var WIREFRAME_MALE: Int;
//     @:optional var WIREFRAME_FEMALE: Int;
//     @:optional var GIGA_BOWSER: Int;
//     @:optional var SANDBAG: Int;
// }