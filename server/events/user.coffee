socket = require "../socket"
User = require "../models/user"

socket.on "get user", String, Function, (id, cb) ->
  User.findById id, (err, user) ->
    return cb name: "error" if err
    return cb name: "not found" unless user
    cb null, user
