BatiBot
===

by [@pongstr](http://github.com/pongstr)

BatiBot is a friendly bot that let's you do stuff to him. :D

Commands
---

> TODO: Document available commands

```bash
# Spotify Player Commands
# Here you can override that annoying host who\'s playing to loud or too soft
# and also get the info of the tracks they are playing.
batibot toggle                - Toggle Play/Pause Controls
batibot play                  - Toggle Play/Pause Controls
batibot pause/stop            - Toggle Play/Pause Controls
batibot next                  - Play the next track
batibot prev|previous         - Play the previous track
batibot volue <up|down|0-10>  - Volume Controls yo
batibot mute                  - Mute the Music. Boooooo!
batibot current song          - Shows the current track info

# Spotify Help
# Returns Hubot README.md file as code for faster copy+pasta mode
batibot spotify help

# Search Track
# Search for a track using keywords or spotify's uri
batibot spotify search track: [Song_Title - Artist | spotify:track:uri]

# Add Track to Playlist
# Adds a track to the playlist queue
batibot spotify playlist add: [spotify:track:uri]

# Set a Playlist
# You may set a playlist where users can queue songs, if a playlist isn't a
# collaborative one, song requests will not be queued.
batibot spotify playlist set: [ spotify:user:name:playlist:uri ]

# Play a track or Playlist
# Typically you can get a track uri or playlist uri from copying and pasting
# from spotify app. You may use BatiBot to search for a playlist or a track
batibot spotify play track: [ spotify:track:uri | spotify:user:name:playlist:uri ]
```




Server Info
---

> TODO: Add server info here
