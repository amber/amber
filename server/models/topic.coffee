mongoose = require "mongoose"
ObjectId = mongoose.Schema.ObjectId

schema = mongoose.Schema
  title: String
  author: ObjectId
  created: Date
  tags: [String]
  posts: [
    author: ObjectId
    body: String
    created: Date
    updated: Date
    versions: [
      body: String
      created: Date
    ]
  ]

schema.methods.toSearchJSON = -> {id: @_id, title: @title, @author, @created, @tags}
schema.statics.search = (query, offset, length, cb) ->
  Topic.find {}, {title: 1, author: 1, created: 1, tags: 1}
  .skip offset
  .limit length
  .exec cb

module.exports = Topic = mongoose.model "Topic", schema
