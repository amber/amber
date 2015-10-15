{View} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"
{parse} = require "am/markup"

class Wiki extends View
  @content: ->
    @article class: "wiki", =>
      @h1 =>
        @span T("Loading…"), outlet: "title"
      @span outlet: "content"

  initialize: ({@app}) ->
    url = location.pathname

    app.server.getTopicByURL url, (err, topic) =>
      if err
        app.setView new NotFound {url}
        return
      @title.textContent = topic.title
      @content.innerHTML = parse(topic.posts[0].body).result


module.exports = {Wiki}
