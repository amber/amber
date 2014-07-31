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

  addTopic: ({author, title, body, starred}, fn) ->
    @topics.push topic = {
      id: @topics.length + 1
      unread: yes
      starred: !!starred
      views: 0
      title
      author
      posts: [{author, body}]
      tags: []
      created: new Date
    }
    @return fn, {id: topic.id}

  return: (fn, value) -> setTimeout (fn.bind null, value), LATENCY

module.exports = {Server}
