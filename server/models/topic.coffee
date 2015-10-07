mongoose = require "mongoose"
ObjectId = mongoose.Schema.ObjectId

schema = mongoose.Schema
  title: String
  author: ObjectId
  hidden: type: Boolean, default: no
  created: type: Date, default: Date.now
  updated: type: Date, default: Date.now
  tags: [String]
  stars: [ObjectId]
  viewCount: type: Number, default: 0
  postCount: Number
  posts: [
    author: ObjectId
    body: String
    hidden: type: Boolean, default: no
    created: type: Date, default: Date.now
    updated: type: Date, default: Date.now
    versions: [
      body: String
      created: Date
    ]
  ]

schema.pre "save", (next) ->
  @postCount = @posts.length
  next()

schema.methods.toSearchJSON = -> {
  id: @_id
  starred: !!@stars?.length
  @title
  @author
  @created
  @tags
  @viewCount
  @postCount
}
schema.methods.toJSON = -> {
  id: @_id
  @title
  @author
  @created
  @tags
  posts: {
    id: p._id
    author: p.author
    body: p.body
    created: p.created
    updated: p.updated
  } for p in @posts
}

schema.statics.search = (query, offset, length, user, cb) ->
  Topic.find {}, {title: 1, author: 1, created: 1, tags: 1, viewCount: 1, postCount: 1, stars: {$elemMatch: {$in: [user?._id]}}}
  .sort {updated: -1}
  .skip offset
  .limit length
  .exec cb

module.exports = Topic = mongoose.model "Topic", schema
