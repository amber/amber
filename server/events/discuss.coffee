socket = require "../socket"
Topic = require "../models/topic"

socket.on "search topics", {query: String, offset: Number, length: Number}, Function, ({query, offset, length}, cb) ->
  Topic.search "", offset, length, (err, topics) ->
    cb null, (t.toSearchJSON() for t in topics)

socket.on "get topic", String, Function, (id, cb) ->
  Topic.findById id, (err, topic) ->
    cb name: "error" if err
    cb name: "not found" unless topic
    cb null, topic

socket.on "add topic", {title: String, body: String, tags: [String]}, Function, ({title, body, tags}, cb) ->
  return cb name: "invalid" unless @user
  now = new Date
  Topic({
    title
    author: @user._id
    tags
    posts: [{
      author: @user._id
      body
      versions: []
    }]
  }).save (err, topic) =>
    return cb name: "error" if err
    cb null, topic

socket.on "add post", {topic: String, body: String}, Function, ({topic, body}, cb) ->
  return cb name: "invalid" unless @user
  Topic.update {_id: topic}, {$push: posts: {
    author: @user._id
    body
    versions: []
  }}, (err, n) ->
    return cb name: "error" if err
    return cb name: "not found" unless n
    cb null, yes

