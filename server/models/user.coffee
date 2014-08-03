mongoose = require "mongoose"

schema = mongoose.Schema
  name: String
  hash: String

schema.methods.findByName = (name, cb) -> User.findOne {name}, cb
schema.methods.toJSON = -> {id: @_id, @name}

module.exports = User = mongoose.model "User", schema
