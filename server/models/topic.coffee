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

schema.index {title: "text", "posts.body": "text"}

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
  q = parseQuery query
  # console.log require('util').inspect q, null, depth: -1
  Topic.find q, {title: 1, author: 1, created: 1, tags: 1, viewCount: 1, postCount: 1, stars: {$elemMatch: {$in: [user?._id]}}}
  .sort {updated: -1}
  .skip offset
  .limit length
  .exec cb

RE_WORD = /[\w'_]+/g

parseQuery = (query) ->
  i = 0

  skipSpace = ->
    i++ while query[i] in [" ", "\t", "\n", "\r"]
    null

  invert = (exp) ->
    if exp.$or
      $nor: exp.$or
    if exp.$nor
      $or: exp.$nor
    else if exp.$and
      $or: exp.$and.map invert
    else if exp.tags
      tags: exp.tags.$nin?[0] ? $nin: [exp.tags]
    else $nor: [exp]

  parseExp = (prec) ->
    if /^NOT\b/.test query.substr i, 4
      i += 3
      skipSpace()
      result = invert parseExp 10
    else
      switch query[i]
        when "("
          i++
          skipSpace()
          result = parseExp 0
          skipSpace()
          if query[i] is ")" then i++
        when "-"
          i++
          result = invert parseExp 10
        when "["
          start = ++i
          i++ while query[i] not in [undefined, "]"]
          tag = query.slice start, i
          result = tags: tag
          i++ if query[i] is "]"
        else
          RE_WORD.lastIndex = i
          if (x = RE_WORD.exec query) and x.index is i
            i += x[0].length
            result = $text: $search: x[0], $language: "en"
          else
            i++
    skipSpace()
    loop
      word = query.substr i, 4
      if prec < 8 and /^AND\s/.test word
        i += 3
        skipSpace()
        result = $and: [result, parseExp 8]
        continue
      if prec < 6 and /^OR\s/.test word
        i += 2
        skipSpace()
        result = $or: [result, parseExp 6]
        continue
      break
    result

  criteria = []
  skipSpace()
  while i < query.length
    if result = parseExp 0
      criteria.push result
    skipSpace()

  criteria.push {hidden: {$not: {$eq: yes}}}
  $and: criteria

module.exports = Topic = mongoose.model "Topic", schema
