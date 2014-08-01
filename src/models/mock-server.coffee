@LATENCY = 200
@REQUESTS_FAIL = no

class Server
  constructor: (@app) ->
    app.server = @
    @topics = for i in [1..1000]
      date = new Date 2014, 6, 32 - i, i * 2749 % 24, i * 467 % 60
      id: i
      unread: no
      starred: no
      views: i * 4563 % 300
      posts: [
        author: "nathan"
        body: "This is an **announcement**. :D"
        created: date
      ]
      title: "Test topic"
      author: "nathan"
      tags: ["announcement"]
      created: date

  signIn: ({username, password}, fn) ->
    return @throw fn, {name: "invalid"} if @user
    return @throw fn, {name: "incorrect"} if username is "nobody" or password is "wrong"
    @user = {name: username, id: username.charCodeAt 0}
    @app.setUser @user
    @return fn, @user

  signOut: (fn) ->
    return @throw fn, {name: "invalid"} unless @user
    @user = null
    @app.setUser null
    @return fn

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
    return @throw fn, {name: "unauthorized"} unless @user
    t = @topics[id - 1]
    return @throw fn, {name: "notFound"} unless t
    return @throw fn, {name: "invalid"} unless body.trim().length
    p = {author: "nathan", body, created: new Date}
    t.posts.push p
    @return fn, p

  starTopic: ({id, starred}, fn) ->
    return @throw fn, {name: "unauthorized"} unless @user
    t = @topics[id - 1]
    return @throw fn, {name: "notFound"} unless t
    t.starred = starred
    @return fn

  watchTopics: (fn) ->

  addTopic: ({title, body, starred}, fn) ->
    return @throw fn, {name: "unauthorized"} unless @user
    @topics.push topic = {
      id: @topics.length + 1
      unread: yes
      starred: !!starred
      views: 0
      title
      author: @user.id
      posts: [{author: @user.id, body, created: new Date}]
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
