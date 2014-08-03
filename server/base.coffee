Server = require "socket.io"
socket = require "./socket"

require "./events/auth"

module.exports = (app) ->
  require "./db"
  # db = require("mongoose").connection
  # db.on "error", console.error.bind console, "connection error:"
  # db.once "open", ->
  io = new Server app
  io.on "connection", (s) ->
    socket.listen s
  io
