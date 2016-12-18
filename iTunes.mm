#include <stdlib.h>
#include <stdbool.h>
#import "iTunes.h"

extern "C" {
  struct Artwork {
    unsigned char* data;
    size_t         length;
  };

  struct Music {
    const char* name;
    const char* album;
    const char* artist;
    Artwork*    artwork;
  };

  bool checkiTunesIsRunning() { return [[SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"] isRunning]; }

  struct Music* getCurrentiTunesPlay() {
    iTunesApplication* iTunes  = NULL;
    iTunesTrack*       current = NULL;
    struct Music*      music   = NULL;

    if (!checkiTunesIsRunning()) {
      return music;
    }

    music   = (Music*)malloc(sizeof(Music));
    iTunes  = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    current = [iTunes currentTrack];

    music->name   = [[current name]   UTF8String];
    music->album  = [[current album]  UTF8String];
    music->artist = [[current artist] UTF8String];

    SBElementArray<iTunesArtwork*>* artworks = [current artworks];
    Artwork*                        artwork  = NULL;

    {
      bool flag = true;

      for (iTunesArtwork* _artwork in artworks) {
        artwork         = (Artwork*)malloc(sizeof(Artwork));
        artwork->length = [[_artwork rawData] length];
        artwork->data   = (unsigned char*)malloc(artwork->length);

        memcpy(artwork->data, [[_artwork rawData] bytes], artwork->length);

        flag = false;
      }

      if (flag) {
        artwork->data = NULL;
      }
    }

    music->artwork = artwork;

    return music;
  }

  void freeMusic(Music* music) {
    free(music->artwork->data);
    free(music->artwork);
    free(music);
  }
}

