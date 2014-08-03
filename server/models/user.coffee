mongoose = require "mongoose"

schema = mongoose.Schema
  name: String
  lowerName: type: String, index: true
  email: String
  hash: String

schema.pre "save", (next) ->
  @lowerName = @name.toLowerCase()
  next()

schema.statics.findByName = (name, cb) -> User.findOne {lowerName: name.toLowerCase()}, cb
schema.methods.toJSON = -> {id: @_id, @name}

module.exports = User = mongoose.model "User", schema
