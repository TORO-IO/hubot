# Author: @pongstr https://github.com/pongstr
#
# Description:
#   Override Spotify PLayer Controls
#
# Dependencies
#   spotify-web-api-node v2.3.0
#
# Configuration:
#   SPOTIFY_CLIENT_ID       - Application Client ID.
#   SPOTIFY_CLIENT_SECRET   - Application Client Secret.
#   SPOTIFY_REDIRECT_URI    - OAuth Callback URI.
#
# Commands:
#   batibot spotify help                                                             - Get Help Commands
#   batibot spotify search track: <song_title - artist | spotify:track:uri>          - Search for a track.
#   batibot spotify playlist set: <spotify:user:name:playlist:uri>                   - Set a playlist where users can queue songs to.
#   batibot spotify playlist add: <spotify:track:uri>                                - Queue a song to playlist
#   batibot spotify play track: <spotify:track:uri | spotify:user:name:playlist:uri> - Play a track or a playlist
#

SpotifyAPI  = require 'spotify-web-api-node'
express     = require 'express'
nunjucks    = require 'nunjucks'
path        = require 'path'
fs          = require 'fs'
sh          = require 'sh'

player   = "#{path.join process.cwd(), 'scripts/spotify.scpt'}"
filepath = "#{path.join process.cwd(), 'app/spotify/views'}"
template = new nunjucks.Environment(new nunjucks.FileSystemLoader(filepath))

template.addFilter 'json', (str) ->
  return JSON.stringify str, null, 2

config =
  # process.env.HUBOT_HIPCHAT_ROOMS
  room: '375587_playlist@conf.hipchat.com'
  spotify:
    # process.env.SPOTIFY_CLIENT_ID
    clientId:     'af83782185e14a2e9195f9aca2e1cd70'
    # process.env.SPOTIFY_CLIENT_SECRET
    clientSecret: '9dc596e6f4e34b1ba5b22ca30c6f3961'
    # process.env.SPOTIFY_REDIRECT_URI
    redirectUri:  "http://127.0.0.1:8080/spotify/callback"
  scopes: [
    'user-follow-read'
    'user-library-read'
    'playlist-modify-public'
    'playlist-read-collaborative'
  ]

module.exports = (robot) ->

  # Initialize Robot Static Directory
  robot.router.use express.static "#{path.join process.cwd(), 'app/spotify/assets'}"

  # Initialize Spotify API
  spotify = new SpotifyAPI(config.spotify)

  # Create Utility Object to store utility shits
  util = {}

  # Filter Ban Artists
  util.filter = (str) ->
    idx = 0
    ban = util.context('ban')
    ban.forEach (e, i, a) ->
      str.toLowerCase().match(e) and idx++
    return idx

  # Print human-readable query results
  util.print = (arr) ->
    str = "\n"
    for key, track of arr
      str += "\n#{key}. #{track.name} by #{track.artists[0].name}\n"
      str += "    add: #{robot.name} spotify playlist add #{track.uri}\n"
      str += "-----\n"
    return str

  # Greetings
  util.context = (type) ->
    ctx  = "#{path.join process.cwd(), 'hubot-context.json'}"
    file = JSON.parse fs.readFileSync ctx, 'utf8'
    if type == 'greet'
      return file.greeting
    if type == 'ban'
      return file.ban
    if type = 'bieber'
      return file.bieber

  util.boot = (callback) ->
    spotify.setAccessToken  robot.brain.get('spotify') and robot.brain.get('spotify').access_token
    spotify.setRefreshToken robot.brain.get('spotify') and robot.brain.get('spotify').refresh_token

    callback and callback
    return

  # Global Functions, they go here
  # ------------------------------

  ###
  # @name Spotify Search
  # @desc Function that searches spotify for your favorite tracks
  # @param {String}   query
  # @param {Function} callback
  ###
  search = (query, callback) ->
    if util.filter(query) <= 0
      spotify.searchTracks(query).then ((res) ->
        # Format results to human-readable output
        results = res.body and util.print(res.body.tracks.items)
        # Let batibot handle serving the results back to the user
        callback and callback null, {results: results}
        return
      ), (err) ->
        # When error occured, let's let batibot handle it
        callback and callback err, null
        return
    else
      callback and callback {bieberAlert: true}, {results: util.context('bieber')}
  ###
  # @name PLayList
  # @desc Function to perform CRUD operations to Playlist
  # @param {String}   query
  # @param {Function} callback
  ###
  playlist = (query, callback) ->
    return



  setplaylist = (query, callback) ->
    playlist = query.match /(user:(\d+|\w+)|playlist:[A-Za-z0-9_.]+)/g
    spotifyUsername = playlist[0].replace /(user\:)/g, ''
    spotifyPlaylist = playlist[1].replace /(playlist\:)/g, ''

    util.boot()

    spotify.getPlaylist(spotifyUsername, spotifyPlaylist, {market: 'PH'}).then ((data) ->
      result =
        name: data.body.name
        desc: if data.body.description then data.body.description else "The playlist doesn't have a description."
        link: data.body.external_urls.spotify

      if data.body.collaborative != true
        result.collaborative = false
        result.message = "\nThe playlist #{data.body.name} is not a collaborative one queueing tracks is not allowed.\n"
      else
        result.collaborative = data.body.collaborative
        result.message = "#{result.name}\n#{result.desc}\n#{result.link}"

      robot.brain.set 'playlist', result
      callback and callback null, result
      return
    ), (err) ->
      if err and err.statusCode == 401
        robot.emit 'reload', (error, auth) ->
          if err
            callback and callback error, null
          else
            setplaylist query, callback and callback null, result
      else
        callback and callback err, null
      return


  ###
  # @name Help
  # @desc Shows Command Context
  # @param {Function} callback
  ###
  help = (callback) ->
    filepath = "#{path.join process.cwd(), 'README.md'}"
    try
      contents = fs.readFileSync(filepath, 'utf8')
      callback and callback null, {result: contents}
    catch error
      callback and callback error, null
    return

  ###
  # @name RefreshToken
  # @desc function that refreshes access token whenever it expires
  # @param {Function} callback
  ###
  reload = (callback) ->
    spotify.refreshAccessToken().then ((data) ->
      # Re-attach the newly refreshed Spotify Access and
      # Refresh Tokens to the constructor.
      spotify.setAccessToken(data.body.access_token)
      spotify.setRefreshToken(data.body.refresh_token)

      # Re-save it to Batibot's brain just in case he crashes and
      # burns and fall into the sultry abyss again.
      robot.brain.set 'spotify', data.body

      # Callback for optimum awesome, returns auth object
      callback and callback(null, data.body)
      return
    ), (err) ->
      # Callback for Bot to handle error shits
      callback and callback(err, null)
      return

  # Event Listeners they go here
  # -----------------------------

  # boot()

  # Listening for Help Events
  robot.on 'help', help

  # Listening for Search Events
  robot.on 'search', search

  # Listening for Playlist Events
  robot.on 'playlist', playlist

  # Listening for Setting a Playlist
  robot.on 'playlist:set', setplaylist

  # Listening for Refresh Token Request
  robot.on 'reload', reload

  robot.on 'boot', util.boot

  # Router Middleware, they go here
  # -------------------------------

  ###
  # @name authenticate
  # @desc is an auth middleware to authenticate. Usable with `robot.router`
  ###
  authenticate = (req, res, next) ->
    spotify.authorizationCodeGrant(req.query.code)
      .then ((data) ->
        console.log data
        # Attach Spotify Access and Refresh Tokens to the constructor
        spotify.setAccessToken data.body.access_token
        spotify.setRefreshToken data.body.refresh_token

        # Save it to Batibot's brain just in case he crashes and
        # burns and fall into the sultry abyss again.
        robot.brain.set 'spotify', data.body

        # Then let's proceed, we'll return
        # auth object just in case you want to do something to it.
        next()
        return
      ), (err) ->
        req.error = err
        res.redirect '/spotify/login'
        res.end()
        return

  ###
  # @name userContext
  # @desc
  ###
  getUserContext = (req, res, next) ->
    spotify.getMe().then ((data) ->
      robot.brain.set 'profile', data.body
      next()
    ), (err) ->
      req.error = err
      res.redirect 'spotify/login'
      res.end()
      return

  ###
  # @name getPlayLists
  # @desc
  ###
  getUserPlayLists = (req, res, next) ->
    profile = robot.brain.get('profile') or {}

    if robot.brain.get 'playlists' == null
      robot.brain.set 'playlists', []

    req.playlists = list: []

    if Object.keys(profile).length > 0
      spotify.getUserPlaylists(profile.id).then ((data) ->
        req.playlists.next      = data.body.tracks.next
        req.playlists.limit     = data.body.tracks.limit
        req.playlists.offset    = data.body.tracks.offset
        req.playlists.previous  = data.body.tracks.previous

        for idx, playlist of data.body.items
          if playlist.collaborative == true and playlist.public == true
            req.playlists.push.list playlist
        robot.brain.set 'playlists', req.playlists
        next()
      ), (err) ->
        req.error = err
        res.redirect '/spotify/login'
    else
    return




  # Routes, they go here
  # --------------------

  ###
  # @name spotify login
  # @desc a login route where playlist admin get started with all the shiz.
  ###
  robot.router.get '/spotify/login', (req, res) ->
    authorize = spotify.createAuthorizeURL config.scopes, require('node-uuid').v4()
    res.send template.render '_pages/login.nunjucks', {authorize: authorize}
    res.end()

  ###
  # @name spotify callback
  # @desc is a callback route where spotify returns oauth code and all that
  #       shiz for batibot to post back to spotify in order for us to acquire
  #       authentication tokens and stuff... yazz.
  ###
  robot.router.get '/spotify/callback', [
    authenticate,
    getUserContext,
    (req, res) ->
      res.redirect '/spotify'
      res.end()
  ]

  ###
  # @name spotify playlist admin
  # @desc a single page app the displays playlist admin options.
  ###
  robot.router.get '/spotify', getUserPlayLists, (req, res, next) ->
    console.log 'Hello, here'
    res.send template.render 'private.html', {playlists: req.playlists}
    return



  robot.router.get '/spotify/api/playlists', getUserPlayLists, (req, res) ->
    res.json(req.playlists)
    res.end()



  # Commands, they go here
  # ----------------------

  # Bot Respawned!
  robot.enter (res) ->
    robot.messageRoom config.room, res.random util.context('greet').enter

  # Bot Fragged!
  robot.leave (res) ->
    robot.messageRoom config.room, res.random util.context('greet').leave


  ###
  # @name robot commands
  # @desc these are the commands robot will answer to
  ###

  robot.respond /spotify\s(search|playlist|play|help)?(\strack:\s|\sadd:\s|\sset:\s)?(\"?.*?\"?\s?(--add|-a|--remove|-rm)?)?$/i, (res) ->
    action = res.match[1] and res.match[1].trim()
    subcom = res.match[2] and res.match[2].trim()
    query  = res.match[3] and res.match[3].trim()

    switch action
      when 'help'
        robot.emit 'help', (err, data) ->
          if !err
            res.reply "Here, you'll need this\n\n"
            res.send  "/code #{data.result}"
      when 'search'
        robot.emit 'search', query, (err, data) ->
          if !err
            res.reply "Okay, here are the results..."
            res.send data.results
          if err and err.bieberAlert
            res.reply "Woops! I think I shit my pants.. please try again."
            res.send res.random data.results
      when 'playlist'
        # robot.emit 'playlist', query, (err, data) ->
        #   res.send "F"
        if subcom == 'set:'
          robot.emit 'playlist:set', query, (err, data) ->
            if err and err.statusCode == 401
            else if err and err.statusCode == 200
              res.reply "I don't think that playlist exists, it might, ..outerspace"
            else
              if !res.message.room
                res.reply "Okay, I've set the playlist you requested. Here are the details:"
                res.send "/quote #{data.message}"
              else
                robot.messageRoom config.room, "Hello @all a new playlist has been set, check it out:"
                robot.messageRoom config.room, "/quote #{data.message}"
              sh('osascript -e \'tell application "Spotify" to play track "'+query+'"\'')
      when 'play'
        query = res.match[3] and res.match[3].trim()
        track = query
        sh('osascript -e \'tell application "Spotify" to play track "'+track+'"\'')
