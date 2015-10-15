socket = require "../socket"
watch = require "../watch"
{Types: {ObjectId}} = require "mongoose"
Topic = require "../models/topic"
{slugify} = require "../../src/util-shared"

socket.on "search topics", {query: String, offset: Number, length: Number}, Function, ({query, offset, length}, cb) ->
  Topic.search query, offset, length, @user, (err, topics) ->
    return cb name: "error" if err
    cb null, (t.toSearchJSON() for t in topics)

socket.on "get topic", String, Function, (id, cb) ->
  Topic.findById id, (err, topic) ->
    return cb name: "error" if err
    return cb name: "not found" unless topic
    cb null, topic
  Topic.update {_id: id}, {$inc: viewCount: 1}
  .exec()

socket.on "get topic by url", String, Function, (url, cb) ->
  Topic.findOne {url}, (err, topic) ->
    return cb name: "error" if err
    return cb name: "not found" unless topic
    cb null, topic
  Topic.update {url}, {$inc: viewCount: 1}
  .exec()

socket.on "add topic", {title: String, body: String, tags: [String]}, Function, ({title, body, tags}, cb) ->
  title = title.trim()
  body = body.trim()
  return cb name: "invalid" unless @user and title and body
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

socket.on "add wiki page", {title: String, url: String, body: String, tags: [String]}, Function, ({title, url, body, tags}, cb) ->
  title = title.trim()
  body = body.trim()
  url = url.trim()
  return cb name: "invalid" unless @user and title and body and (url is "/wiki/#{slugify title}" or @user.isAdmin)
  Topic({
    title
    url
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
  body = body.trim()
  return cb name: "invalid" unless @user and body
  Topic.update {_id: topic}, {
    updated: Date.now()
    $inc: postCount: 1
    $push: posts: {
      _id: id = new ObjectId()
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
    cb null, id

socket.on "edit topic", {id: String, title: String, tags: [String]}, Function, ({id, title, tags}, cb) ->
  title = title.trim()
  return cb name: "invalid" unless @user and title
  Topic.findById id, (err, t) =>
    return cb name: "error" if err
    return cb name: "not found" unless t
    return cb name: "forbidden" unless @user._id.equals t.posts[0].author
    t.title = title
    t.tags = tags
    t.updated = Date.now()
    t.save (err) =>
      return cb name: "error" if err
      cb null, yes

socket.on "edit post", {topic: String, id: String, body: String}, Function, ({topic, id, body}, cb) ->
  return cb name: "invalid" unless @user
  Topic.findById topic, (err, t) =>
    return cb name: "error" if err
    return cb name: "not found" unless t
    for p in t.posts when p._id+"" is id and p.author.equals @user._id
      p.versions.push {
        created: p.updated
        body: p.body
      }
      p.body = body
      p.updated = Date.now()
      t.updated = Date.now()
      return t.save (err) =>
        return cb name: "error" if err
        cb null, yes
    cb name: "not found"

socket.on "hide topic", {id: String}, Function, ({id}, cb) ->
  return cb name: "invalid" unless @user
  Topic.update {_id: id, author: @user._id}, {hidden: yes}, (err) =>
    return cb name: "error" if err
    cb null, yes

socket.on "hide post", {topic: String, id: String}, Function, ({topic, id}, cb) ->
  return cb name: "invalid" unless @user
  Topic.findById topic, (err, t) =>
    return cb name: "error" if err
    return cb name: "not found" unless t
    for p, i in t.posts when p._id+"" is id and p.author.equals @user._id
      return cb name: "invalid" if i is 0
      p.hidden = yes
      p.updated = Date.now()
      return t.save (err) =>
        return cb name: "error" if err
        cb null, yes
    cb name: "not found"

socket.on "star topic", {id: String, flag: Boolean}, Function, ({id, flag}, cb) ->
  return cb name: "invalid" unless @user
  stars = {stars: @user._id}
  update = if flag then {$push: stars} else {$pull: stars}
  Topic.update {_id: id}, update, (err, n) ->
    return cb name: "err" if err
    return cb name: "not found" if err
    cb null, yes
