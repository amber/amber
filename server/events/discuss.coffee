socket = require "../socket"
Topic = require "../models/topic"

socket.on "search topics", {query: String, offset: Number, length: Number}, Function, ({query, offset, length}, cb) ->
  Topic.search "", offset, length, (err, topics) ->
    cb null, (t.toSearchJSON() for t in topics)

socket.on "add topic", {title: String, body: String, tags: [String]}, Function, ({title, body, tags}, cb) ->
  return cb name: "invalid" unless @user
  now = new Date
  Topic({
    title
    author: @user._id
    created: now
    tags
    posts: [{
      author: @user._id
      body
      created: now
      updated: now
      versions: []
    }]
  }).save (err, topic) =>
    return cb name: "error" if err
    cb null, topic