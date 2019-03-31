import haxe.Int32;

class SlpData {
    raw: Array<Dynamic>;
    metadata: SlpMetadata;
}

typedef SlpMetadata = {
    startAt: String;
    lastFrame: Int32;
    players: SlpPlayers;
    playedOn: String;
}

typedef SlpPlayers = {
    ?p1: SlpPlayerData;
    ?p2: SlpPlayerData;
    ?p3: SlpPlayerData;
    ?p4: SlpPlayerData;
}

typedef SlpPlayerData = {
    names: Dynamic; // Should be string? wtf
    characters: SlpCharacterFrames;
}

typedef SlpCharacterFrames = {
    ?MARIO: Int32;
    ?FOX: Int32;
    ?CAPTAIN_FALCON: Int32;
    ?DONKEY_KONG: Int32;
    ?KIRBY: Int32;
    ?BOWSER: Int32;
    ?LINK: Int32;
    ?SHEIK: Int32;
    ?NESS: Int32;
    ?PEACH: Int32;
    ?POPO: Int32;
    ?NANA: Int32;
    ?PIKACHU: Int32;
    ?SAMUS: Int32;
    ?YOSHI: Int32;
    ?JIGGLYPUFF: Int32;
    ?MEWTWO: Int32;
    ?LUIGI: Int32;
    ?MARTH: Int32;
    ?ZELDA: Int32;
    ?YOUNG_LINK: Int32;
    ?DR_MARIO: Int32;
    ?FALCO: Int32;
    ?PICHU: Int32;
    ?GAME_AND_WATCH: Int32;
    ?GANONDORF: Int32;
    ?ROY: Int32;
    ?MASTER_HAND: Int32;
    ?CRAZY_HAND: Int32;
    ?WIREFRAME_MALE: Int32;
    ?WIREFRAME_FEMALE: Int32;
    ?GIGA_BOWSER: Int32;
    ?SANDBAG: Int32;
}