import std.algorithm,
       std.base64,
       std.string,
       std.range,
       std.ascii,
       std.stdio,
       std.json,
       std.conv;
import core.stdc.string;
import twitter4d;

extern(C) {
  struct Artwork {
    ubyte* data;
    size_t length;
  };
  
  struct Music {
    const char* name;
    const char* album;
    const char* artist;
    Artwork*    artwork;
  }

  Music* getCurrentiTunesPlay();
  void freeMusic(Music* music);
}


void main() {
  Twitter4D t4d;
  Music* music;

  // Please replace with your keys before use this software
  string[string] keys = [
    "consumerKey"       : "",
    "consumerSecret"    : "",
    "accessToken"       : "",
    "accessTokenSecret" : ""
  ];

  music = getCurrentiTunesPlay();

  if (music == null) {
    throw new Error("[Fatal Error] - iTunes is not running.");
  }

  t4d = new Twitter4D(keys);
  string name   = cast(string)fromStringz(music.name),
         album  = cast(string)fromStringz(music.album),
         artist = cast(string)fromStringz(music.artist);
  string nowPlayingString = "Now Playing: " ~ name ~ " from " ~ album ~ " (" ~ artist ~ ") #NowPlaying";

  writeln("NowPlaying:");
  writefln("name   : %s", name);
  writefln("album  : %s", album);
  writefln("artist : %s", artist);
  writeln;

  writeln("[Tweet] - ", nowPlayingString);

  Artwork* artwork = music.artwork;

  if (artwork !is null) {
    ubyte[] buf;
    buf.length = artwork.length;
    memcpy(buf.ptr, artwork.data, buf.length);

    string encoded = Base64.encode(buf);

    auto parsed = parseJSON((t4d.customUrlRequest("https://upload.twitter.com/1.1/", "POST", "media/upload.json", ["media_data": encoded])));

    if ("media_id_string" in parsed.object) {
      string media_id = parsed.object["media_id_string"].str;
      t4d.request("POST", "statuses/update.json", ["status" : nowPlayingString, "media_ids" : media_id]);
    } else {
      t4d.request("POST", "statuses/update.json", ["status" : nowPlayingString]);
    }
  } else {
    t4d.request("POST", "statuses/update.json", ["status" : nowPlayingString]);
  }

  freeMusic(music);
}
