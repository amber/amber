io = require "socket.io-client"

class Server
  constructor: (@app) ->
    app.server = @

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

  signIn: ({username, password}, cb) ->
    @socket.emit "sign in", {username, password}, (err, user) =>
      return cb err if err
      @app.setUser @user = user
      cb null, user

module.exports = {Server}
