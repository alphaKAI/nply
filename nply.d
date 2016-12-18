import kqueuez,
       core.sys.posix.sys.time,
       core.sys.posix.unistd;
import core.thread;
import core.stdc.stdlib,
       core.stdc.string;
import std.algorithm,
       std.base64,
       std.string,
       std.range,
       std.ascii,
       std.stdio,
       std.json,
       std.conv;
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

struct Env {
  Twitter4D t4d;
  Music*    music;
  string currentMusic,
         previousMusic;
}

static Env E;

private static string getJsonData(JSONValue parsedJson, string key) {
  return parsedJson.object[key].str;
}

private static string readFile(string filePath) {
  auto file = File(filePath, "r");
  string buf;

  foreach(line; file.byLine) {
    buf = buf ~ cast(string)line;
  }

  return buf;
}

private static string[string] buildAuthHash(JSONValue parsed) {
  return [
            "consumerKey"       : getJsonData(parsed, "consumerKey"),
            "consumerSecret"    : getJsonData(parsed, "consumerSecret"),
            "accessToken"       : getJsonData(parsed, "accessToken"),
            "accessTokenSecret" : getJsonData(parsed, "accessTokenSecret")
  ];
}

private static void init() {
  auto keys = parseJSON(readFile("settings.json")).buildAuthHash;

  E.t4d = new Twitter4D(keys);
}

private static Music* checkTrackChange() {
  with (E) {
    music = getCurrentiTunesPlay;

    if (music is null) {
      writeln("iTunes is playing music.");

      return null;
    }

    currentMusic = cast(string)fromStringz(music.name).idup;

    if (currentMusic != previousMusic) {
      return music;
    } else {
      return null;
    }
  }
}

private static void tweet() {
  with (E) {
    music = checkTrackChange;
    if (music is null) {
      return;
    }

    string name   = cast(string)fromStringz(music.name),
           album  = cast(string)fromStringz(music.album),
           artist = cast(string)fromStringz(music.artist);
    string nowPlayingString = "Now Playing: " ~ name ~ " from " ~ album ~ " (" ~ artist ~ ") #NowPlaying";

    currentMusic  = name.idup;
    previousMusic = name.idup;

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
}

void diep(string msg) {
  stderr.writeln("[ERROR] ", msg);
  exit(EXIT_FAILURE);
}

void main() {
  init;

  kevent_t change,
           event;
  int kq, nev;

  if ((kq = kqueue()) == -1) {
    diep("kqueue()");
  }

  EV_SET(&change, 1, EVFILT_TIMER, EV_ADD | EV_ENABLE, 0, 5000, null);

  for (;;) {
    nev = kevent(kq, &change, 1, &event, 1, null);

    if (nev < 0) {
      diep("kevent()");
    } else if (nev > 0) {
      if (event.flags & EV_ERROR) {
        stderr.writefln("EV_ERROR: %s", strerror(cast(int)event.data).fromStringz);
        exit(EXIT_FAILURE);
      }

      tweet;
    }
  }

  close(kq);
  exit(EXIT_SUCCESS);
}
