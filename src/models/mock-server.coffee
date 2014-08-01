@LATENCY = 200
@REQUESTS_FAIL = no

class Server
  constructor: (@app) ->
    app.server = @
    @topics = for i in [1..1000]
      id: i
      unread: no
      starred: no
      views: i * 4563 % 300
      posts: [
        author: "nathan"
        body: "This is an **announcement**. :D"
        created: new Date
      ]
      title: "Test topic"
      author: "nathan"
      tags: ["announcement"]
      created: new Date 2014, 6, 32 - i, i * 2749 % 24, i * 467 % 60

  getTopics: ({offset, length}, fn) -> @return fn, ({
    id: t.id
    unread: t.unread
    starred: t.starred
    views: t.views
    posts: t.posts.length
    title: t.title
    author: t.author
    tags: t.tags
    created: t.created
  } for t in @topics.slice offset, offset + length)

  readTopic: ({id}, fn) ->
    @topics[id - 1].unread = no
    @return fn

  getTopic: ({id}, fn) ->
    t = @topics[id - 1]
    return @throw fn, {name: "notFound"} unless t
    t.unread = no
    t.views++
    @return fn, t

  addPost: ({id, body}, fn) ->
    t = @topics[id - 1]
    return @throw fn, {name: "notFound"} unless t
    return @throw fn, {name: "invalid"} unless body.trim().length
    p = {author: "nathan", body, created: new Date}
    t.posts.push p
    @return fn, p

  starTopic: ({id, starred}, fn) ->
    @topics[id - 1].starred = starred
    @return fn

  watchTopics: (fn) ->

  addTopic: ({title, body, starred}, fn) ->
    @topics.push topic = {
      id: @topics.length + 1
      unread: yes
      starred: !!starred
      views: 0
      title
      author: "nathan"
      posts: [{author: "nathan", body, created: new Date}]
      tags: []
      created: new Date
    }
    @return fn, {id: topic.id}

  throw: (fn, err) -> @fire fn, err
  return: (fn, value) ->
    if REQUESTS_FAIL
      @throw fn, {name: "fail"}
    else
      @fire fn, null, value
  fire: (fn, err, value) -> setTimeout (fn.bind null, err, value), LATENCY if fn

module.exports = {Server}
