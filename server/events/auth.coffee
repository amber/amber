socket = require "../socket"
bcrypt = require "bcrypt-nodejs"
User = require "../models/user"

socket.on "sign in", {username: String, password: String}, Function, ({username, password}, cb) ->
  return cb name: "invalid" if @user
  User.findByName username, (err, user) =>
    return cb name: "incorrect" if err
    bcrypt.compare password, user.hash, (err, res) =>
      return cb name: "error" if err
      return cb name: "incorrect" unless res
      @user = user
      cb user.toJSON()

socket.on "sign up", {username: String, password: String}, Function, ({username, password}, cb) ->
  bcrypt.hash password, null, null, (err, hash) ->
    return cb name: "error" if err
    new User({name: username, hash}).save (err, user) ->
      cb user.toJSON()

socket.on "sign out", Function, (cb) ->
  return cb name: "invalid" unless @user
  @user = null
  cb()
