io = require "socket.io-client"
TopicSummary = require "am/models/topic-summary"
Topic = require "am/models/topic"
Post = require "am/models/post"

class Server
  constructor: (@app) ->
    app.server = @

    @userCache = Object.create null

    @socket = io "#{location.protocol}//#{location.host}/"
    @socket.on "connect", => console.log "connected"
    @socket.on "disconnect", => console.log "disconnected"

    @socket.on "reload css", =>
      return unless link = document.querySelector "link[href='/static/app.css']"
      newLink = document.createElement "link"
      newLink.rel = "stylesheet"
      newLink.href = link.href.split("?")[0] + "?" + Math.random()
      document.head.replaceChild newLink, link

    @socket.on "reload js", =>
      location.reload()

    @socket.on "update", (d) =>
      @watcher d if @watcher

    if t = localStorage.getItem "amberToken"
      [username, token] = JSON.parse t
      @socket.emit "use auth token", {username, token}, (err, d) =>
        return if err
        @signedIn d
        @app.router.route()

  watch: (name, id, cb) ->
    @watcher = cb
    @socket.emit "watch", {name, id}

  unwatch: ->
    @socket.emit "unwatch"

  signedIn: (d) ->
    @app.setUser @user = d.user
    localStorage.setItem "amberToken", JSON.stringify [d.user.name, d.token]

  getUser: (id, cb) ->
    cb null, user if user = @userCache[id]
    @socket.emit "get user", id, (err, user) =>
      return cb err if err
      @userCache[id] = user
      cb null, user

  signUp: ({username, email, password}, cb) ->
    @socket.emit "sign up", {username, email, password}, (err, user) =>
      return cb err if err
      @app.setUser @user = user
      cb null, user

  signIn: ({username, password}, cb) ->
    @socket.emit "sign in", {username, password}, (err, d) =>
      return cb err if err
      @signedIn d
      cb null, d.user

  signOut: (cb) ->
    @socket.emit "sign out", (err) =>
      return cb err if err
      @app.setUser @user = null
      localStorage.removeItem "amberToken"
      cb null

  addTopic: ({title, body, tags}, cb) ->
    tags ?= []
    @socket.emit "add topic", {title, body, tags}, cb

  getTopics: ({offset, length}, cb) ->
    @socket.emit "search topics", {query: "", offset, length}, (err, topics) =>
      return cb err if err
      cb null, (new TopicSummary t for t in topics)

  getTopic: (id, cb) ->
    @socket.emit "get topic", id, (err, topic) =>
      return cb err if err
      cb null, new Topic topic

  addPost: ({id, body}, cb) ->
    @socket.emit "add post", {topic: id, body}, (err, post) =>
      return cb err if err
      cb null, new Post post

module.exports = {Server}
