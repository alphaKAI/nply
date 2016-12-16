#nply - NowPlaying4D
NowPlaying tweet tool in D with OS X's iTunes(using Scripting Bridge).  

##Requirements

- OS X(macOS)
- Latest DMD
- Xcode(for sdef)
  
  
##Setup

###1. Clone this repository
`$ git clone https://github.com/alphaKAI/nply`

###2. Replace with your keys in nply.d
`$ (your favorite editor) nply.d`

###3. Generate header of iTunes.h with sdef command
`$ sdef /Applications/iTunes.app | sdp -fh --basename iTunes`

###4. Build

```zsh
$ gcc -c iTunes.mm
$ dmd nply.d twitter4d.d iTunes.o -L-framework -LFoundation -L-framework -LiTunesLibrary -L-framework -LScriptingBridge
```

Complete!  
Now you can post #NowPlaying with `./nply` if iTunes is playing.  

##LICENSE
This software is released under the MIT license.  
Please see `LICENSE` file for details.  
Copyright (C) 2016 Akihiro Shoji
