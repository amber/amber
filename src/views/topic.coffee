{View, $$} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"
{Post} = require "am/views/post"
{Editor} = require "am/views/editor"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 outlet: "title"
      @section class: "inline-container", outlet: "form", =>
        @subview "editor", new Editor placeholder: "Say something…"
        @button "Post", class: "accent right", click: "submit"

  initialize: ({@id, @app}) ->
    @app.server.getTopic {@id}, (err, d) =>
      if err
        @app.setView new NotFound {url: location.pathname}
        return
      @app.setTitle d.title
      @title.textContent = d.title
      for p in d.posts
        @add (new Post p), @base, @form


module.exports = {Topic}
