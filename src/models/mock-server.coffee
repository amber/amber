@LATENCY = 100

class Server
  constructor: (@app) ->
    app.server = @
    @topics = []

  getTopics: (fn) -> @return fn, ({
    id: t.id
    unread: t.unread
    starred: t.starred
    views: t.views
    posts: t.posts.length
    title: t.title
    author: t.author
    tags: t.tags
    created: t.created
  } for t in @topics)

  readTopic: ({id}, fn) ->
    @topics[id - 1].unread = no
    @return fn

  getTopic: ({id}, fn) ->
    t = @topics[id - 1]
    return @throw fn, {name: "notFound"} unless t
    t.unread = no
    t.views++
    @return fn, t

  starTopic: ({id, starred}, fn) ->
    @topics[id - 1].starred = starred
    @return fn

  watchTopics: (fn) ->

  addTopic: ({author, title, body, starred}, fn) ->
    @topics.push topic = {
      id: @topics.length + 1
      unread: yes
      starred: !!starred
      views: 0
      title
      author
      posts: [{author, body, created: new Date}]
      tags: []
      created: new Date
    }
    @return fn, {id: topic.id}

  throw: (fn, err) -> @fire fn, err
  return: (fn, value) -> @fire fn, null, value
  fire: (fn, err, value) -> setTimeout (fn.bind null, err, value), LATENCY if fn

module.exports = {Server}
