mongoose = require "mongoose"
ObjectId = mongoose.Schema.ObjectId

schema = mongoose.Schema
  title: String
  author: ObjectId
  created: Date
  tags: [String]
  viewCount: type: Number, default: 0
  postCount: Number
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

schema.pre "save", (next) ->
  @postCount = @posts.length
  next()

schema.methods.toSearchJSON = -> {id: @_id, @title, @author, @created, @tags, @viewCount, @postCount}
schema.methods.toJSON = -> {
  id: @_id
  @title
  @author
  @created
  @tags
  posts: {
    author: p.author
    body: p.body
    created: p.created
    updated: p.updated
  } for p in @posts
}

schema.statics.search = (query, offset, length, cb) ->
  Topic.find {}, {title: 1, author: 1, created: 1, tags: 1, viewCount: 1, postCount: 1}
  .skip offset
  .limit length
  .exec cb

module.exports = Topic = mongoose.model "Topic", schema
