io = require "socket.io-client"
TopicSummary = require "am/models/topic-summary"
Topic = require "am/models/topic"

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
    @socket.emit "sign in", {username, password}, (err, user) =>
      return cb err if err
      @app.setUser @user = user
      cb null, user

  signOut: (cb) ->
    @socket.emit "sign out", (err) =>
      return cb err if err
      @app.setUser @user = null
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

module.exports = {Server}
