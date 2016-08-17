io = require "socket.io-client"
TopicSummary = require "am/models/topic-summary"
Topic = require "am/models/topic"
Post = require "am/models/post"
User = require "am/models/user"
storage = require "am/models/storage"

class Server
  constructor: (@app) ->
    app.server = @

    @userCache = Object.create null

    @socket = io "#{location.protocol}//#{location.host}/"
    @socket.on "connect", =>
      console.log "connected"
      @resignIn no
    @socket.on "disconnect", => console.log "disconnected"

    @socket.on "reload css", =>
      return unless link = document.querySelector "link[href*='/static/app.css']"
      newLink = document.createElement "link"
      newLink.rel = "stylesheet"
      newLink.href = link.href.split("?")[0] + "?" + Math.random()
      document.head.replaceChild newLink, link
      app.errors.hide()

    @socket.on "reload js", =>
      location.reload()

    @socket.on "css error", (err) =>
      app.errors.showError err

    @socket.on "js error", (err) =>
      app.errors.showError err

    @socket.on "update", (d) =>
      @watcher d if @watcher

    @resignIn yes

  resignIn: (thenRoute) ->
    storage.get "amberToken"
    .then (t) =>
      return unless t
      [username, token] = JSON.parse t
      @socket.emit "use auth token", {username, token}, (err, d) =>
        return if err
        @signedIn d
        @app.router.route() if thenRoute

  watch: (name, id, cb) ->
    @watcher = cb
    @socket.emit "watch", {name, id}

  unwatch: ->
    @socket.emit "unwatch"

  signedIn: (d) ->
    @app.setUser @user = new User d.user
    storage.set "amberToken", JSON.stringify [d.user.name, d.token]

  getUser: (id, cb) ->
    cb null, user if user = @userCache[id]
    @socket.emit "get user", id, (err, d) =>
      return cb err if err
      @userCache[id] = user = new User d
      cb null, user

  signUp: ({username, email, password}, cb) ->
    @socket.emit "sign up", {username, email, password}, (err, d) =>
      return cb err if err
      @signedIn d
      cb null, @user

  signIn: ({username, password}, cb) ->
    @socket.emit "sign in", {username, password}, (err, d) =>
      return cb err if err
      @signedIn d
      cb null, @user

  signOut: (cb) ->
    @socket.emit "sign out", (err) =>
      return cb err if err
      @app.setUser @user = null
      storage.remove "amberToken"
      cb null

  addTopic: ({title, body, tags}, cb) ->
    tags ?= []
    @socket.emit "add topic", {title, body, tags}, cb

  addWikiPage: ({title, url, body, tags}, cb) ->
    tags ?= []
    @socket.emit "add wiki page", {title, url, body, tags}, cb

  searchTopics: ({query, offset, length}, cb) ->
    @socket.emit "search topics", {query, offset, length}, (err, topics) =>
      return cb err if err
      cb null, (new TopicSummary t for t in topics)

  getTopic: (id, cb) ->
    @socket.emit "get topic", id, (err, topic) =>
      return cb err if err
      cb null, new Topic topic

  getTopicByURL: (url, cb) ->
    @socket.emit "get topic by url", url, (err, topic) =>
      return cb err if err
      cb null, new Topic topic

  addPost: ({id, body}, cb) ->
    @socket.emit "add post", {topic: id, body}, (err, id) =>
      return cb err if err
      cb null, id

  editTopic: ({id, title, tags}, cb) ->
    @socket.emit "edit topic", {id, title, tags}, cb

  editPost: ({topic, id, body}, cb) ->
    @socket.emit "edit post", {topic, id, body}, cb

  hideTopic: ({id}, cb) ->
    @socket.emit "hide topic", {id}, cb

  hidePost: ({topic, id}, cb) ->
    @socket.emit "hide post", {topic, id}, cb

  starTopic: ({id, flag}, cb) ->
    @socket.emit "star topic", {id, flag}, cb

module.exports = {Server}
