Server = require "socket.io"
socket = require "./socket"

require "./events/auth"
require "./events/discuss"

module.exports = (app) ->
  require "./db"
  io = new Server app
  io.on "connection", (s) ->
    socket.listen s
  io
