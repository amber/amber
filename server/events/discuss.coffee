socket = require "../socket"
watch = require "../watch"
Topic = require "../models/topic"

socket.on "search topics", {query: String, offset: Number, length: Number}, Function, ({query, offset, length}, cb) ->
  Topic.search "", offset, length, (err, topics) ->
    cb null, (t.toSearchJSON() for t in topics)

socket.on "get topic", String, Function, (id, cb) ->
  Topic.findById id, (err, topic) ->
    cb name: "error" if err
    cb name: "not found" unless topic
    cb null, topic
  Topic.update {_id: id}, {$inc: viewCount: 1}
  .exec()

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
  Topic.update {_id: topic}, {
    $set: updated: Date.now(),
    $inc: postCount: 1
    $push: posts: {
      author: @user._id
      body
      versions: []
    }
  }, (err, n) =>
    return cb name: "error" if err
    return cb name: "not found" unless n
    watch.emit "topic", topic, {
      type: "add post"
      author: @user._id
      body
    }, @
    cb null, yes

socket.on "edit post", {topic: String, id: String, body: String}, Function, ({topic, id, body}, cb) ->
  return cb name: "invalid" unless @user
  Topic.findById topic, (err, t) =>
    return cb name: "error" if err
    return cb name: "not found" unless t
    for p, i in t.posts when p._id+"" is id
      p.versions.push {
        created: p.updated
        body: p.body
      }
      p.body = body
      p.updated = Date.now()
    t.updated = Date.now()
    t.save (err) =>
      return cb name: "error" if err
      cb null, yes
