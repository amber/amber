Server = require "socket.io"
socket = require "./socket"
watch = require "./watch"

require "./events/auth"
require "./events/user"
require "./events/discuss"

module.exports = (app) ->
  require "./db"
  io = new Server app
  io.on "connection", (s) ->
    socket.listen s
  io
