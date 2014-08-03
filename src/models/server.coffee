io = require "socket.io-client"

class Server
  constructor: (@app) ->
    app.server = @

    @socket = io "#{location.protocol}//#{location.host}/"
    @socket.on "connect", =>
      console.log "connected"

module.exports = {Server}
