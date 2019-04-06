package slippihx;

import haxe.ds.Vector;

@:expose
@:keep
typedef SlpData = {
    var raw: Vector<UInt>;
    var metadata: SlpMetadata;
}

@:expose
@:keep
typedef SlpMetadata = {
    var startAt: String;
    var lastFrame: Int;
    var players: SlpPlayers;
    var playedOn: String;
    var duration: Int;
    var consoleNick: Null<String>;
}

@:expose
@:keep
typedef SlpPlayers = Map<Int, SlpPlayer>;

@:expose
@:keep
typedef SlpPlayer = {
    @optional var names: Map<String, String>; // Should be string? wtf
    var characters: Map<Int, Int>;
}

@:expose
@:keep
typedef SlpRaw = {
    var eventPayloads: SlpEventsPayloads;
    var frames: Array<SlpFrames>;
    var gameStart: SlpGameStart;
    var gameEnd: SlpGameEnd;
}

@:expose
@:keep
typedef SlpEventsPayloads = {
    var eventPayloads: UInt;
    var gameStart: Int;
    var preFrameUpdate: Int;
    var postFrameUpdate: Int;
    var gameEnd: Int;
}

@:expose
@:keep
typedef SlpFrames = {
    var preFrameUpdate: SlpPreFrameUpdate;
    var postFrameUpdate: SlpPostFrameUpdate;
}

@:expose
@:keep
typedef SlpGameStart = {
    var version: SlpVersion;
    var gameInfoBlock: Vector<UInt>; // Size 312
    var isTeams: Bool;
    var stage: UInt;
    var externalCharacterId: SlpPlayersInfo;
    var playerTypes: SlpPlayersInfo;
    var stockStartCounts: SlpPlayersInfo;
    var characterColors: SlpPlayersInfo;
    var teamIds: SlpPlayersInfo;
    var randomSeed: UInt;
    var dashbackFixes: Null<SlpPlayersInfo>;
    var shieldDropFixes: Null<SlpPlayersInfo>;
    var nametags: Null<SlpNametags>;
    // Since these are just bools, if not compat set to false instead of null?
    var pal: Null<Bool>;
    var frozenPS: Null<Bool>;
}

@:expose
@:keep
typedef SlpPlayersInfo = {
    var p1: Int;
    var p2: Int;
    var p3: Int;
    var p4: Int;
}

@:expose
@:keep
typedef SlpNametags = {
    var p1: String;
    var p2: String;
    var p3: String;
    var p4: String;
}

@:expose
@:keep
typedef SlpPreFrameUpdate = {
    //
}

@:expose
@:keep
typedef SlpPostFrameUpdate = {
    //
}

@:expose
@:keep
typedef SlpGameEnd = {
    //
}

@:expose
@:keep
typedef SlpVersion = {
    var major: UInt;
    var minor: UInt;
    var build: UInt;
    var revision: UInt;
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