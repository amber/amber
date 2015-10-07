{View, $$} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"
{Post} = require "am/views/post"
{Editor} = require "am/views/editor"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 T("Loading…"), outlet: "title"
      @section class: "inline-container", outlet: "form", keydown: "onKeyDown", =>
        @subview "editor", new Editor placeholder: "Say something…", disabled: yes
        @button "Post", class: "accent right", click: "submit"

  enter: -> @editor.focus()

  initialize: ({@id, @app}) ->
    @form.style.display = "none" unless app.server.user
    @app.server.watch "topic", @id, @update
    @app.server.getTopic @id, (err, d) =>
      if err
        @app.setView new NotFound {url: location.pathname}
        return
      @editor.setDisabled no
      @editor.focus()
      @app.setTitle d.title
      @title.textContent = d.title
      for p in d.posts
        @add (new Post {@app, d: p}), @base, @form

  update: (d) =>
    switch d.type
      when "add post"
        scroll = scrollY is document.body.offsetHeight - innerHeight
        @add (new Post {
          @app
          d: {
            body: d.body
            author: d.author
            created: new Date
          }
        }), @base, @form
        if scroll
          scrollTo 0, document.body.offsetHeight

  submit: ->
    body = @editor.getValue().trim()
    unless body.length
      @editor.setValue ""
      @editor.focus()
      return
    view = new Post {
      @app
      d: {
        body
        author: @app.server.user.id
        created: new Date
      }
      pending: yes
    }
    @editor.setDisabled yes
    @add view, @base, @form
    scrollTo 0, document.body.offsetHeight
    @app.server.addPost {@id, body}, (err, d) =>
      @editor.setDisabled no
      @editor.focus()
      if err
        view.remove()
        return
      view.setPending no
      @editor.setValue ""

  onKeyDown: (e) ->
    @submit() if e.keyCode is 13 and (e.ctrlKey or e.metaKey)

module.exports = {Topic}
