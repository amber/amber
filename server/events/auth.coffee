socket = require "../socket"
bcrypt = require "bcrypt-nodejs"
User = require "../models/user"
UserToken = require "../models/user-token"

socket.on "use auth token", {username: String, token: String}, Function, ({username, token}, cb) ->
  return cb name: "invalid" if @user
  User.findByName username, (err, user) =>
    return cb name: "incorrect" unless user
    UserToken.findOne {username: user.name, token}, (err, token) =>
      return cb name: "error" if err
      return cb name: "invalid" unless token
      bcrypt.genSalt null, (err, salt) =>
        return cb name: "error" if err
        token.token = salt
        token.save (err, token) =>
          return cb name: "error" if err
          @user = user
          cb null, {token: salt, user}

socket.on "sign in", {username: String, password: String}, Function, ({username, password}, cb) ->
  return cb name: "invalid" if @user
  username = username.trim()
  User.findByName username, (err, user) =>
    return cb name: "incorrect" unless user
    bcrypt.compare password, user.hash, (err, res) =>
      return cb name: "error" if err
      return cb name: "incorrect" unless res
      @createToken user, cb

socket.on "sign up", {username: String, email: String, password: String}, Function, ({username, email, password}, cb) ->
  username = username.trim()
  email = email.trim()
  return cb name: "invalid" unless username and password and email and /.@./.test email
  User.findByName username, (err, user) =>
    return cb name: "in use" if user
    bcrypt.hash password, null, null, (err, hash) =>
      return cb name: "error" if err
      User({name: username, email, hash}).save (err, user) =>
        @createToken user, cb

socket.method "createToken", (user, cb) ->
  bcrypt.genSalt null, (err, salt) =>
    return cb name: "error" if err
    UserToken({token: salt, username: user.name}).save (err) =>
      return cb name: "error" if err
      @user = user
      cb null, {token: salt, user}

socket.on "name in use?", String, Function, (username, cb) ->
  User.findByName username, (err, user) =>
    cb null, user?

socket.on "sign out", Function, (cb) ->
  return cb name: "invalid" unless @user
  UserToken.remove {username: @user.name}
  .exec()
  @user = null
  cb null, yes
