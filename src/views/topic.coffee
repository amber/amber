{View, $$} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"
{Post} = require "am/views/post"
{Editor} = require "am/views/editor"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 outlet: "title"
      @section class: "inline-container", outlet: "form", keydown: "onKeyDown", =>
        @subview "editor", new Editor placeholder: "Say something…"
        @button "Post", class: "accent right", click: "submit"

  enter: -> @editor.focus()

  initialize: ({@id, @app}) ->
    @app.server.getTopic {@id}, (err, d) =>
      if err
        @app.setView new NotFound {url: location.pathname}
        return
      @app.setTitle d.title
      @title.textContent = d.title
      for p in d.posts
        @add (new Post p), @base, @form

  submit: ->
    @add (new Post
      body: @editor.getValue()
      author: "nathan"
      created: new Date
    ), @base, @form
    @editor.setValue ""

  onKeyDown: (e) ->
    @submit() if e.keyCode is 13 and (e.ctrlKey or e.metaKey)

module.exports = {Topic}
