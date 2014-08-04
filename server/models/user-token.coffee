mongoose = require "mongoose"

schema =
  username: String
  token: String
  created: type: Date, expires: '10d', default: Date.now

module.exports = UserToken = mongoose.model "UserToken", schema
