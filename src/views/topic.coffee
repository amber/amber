{View, $$} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"
{Post} = require "am/views/post"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 outlet: "title"

  initialize: ({@id, @app}) ->
    @app.server.getTopic {@id}, (err, d) =>
      if err
        @app.setView new NotFound {url: location.pathname}
        return
      @title.textContent = d.title
      for p in d.posts
        @add new Post p

  title: -> "The name of topic ##{@id}"

module.exports = {Topic}
