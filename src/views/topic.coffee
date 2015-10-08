{View, $$} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"
{Post} = require "am/views/post"
{Editor} = require "am/views/editor"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 =>
        @span T("Loading…"), outlet: "title"
        @input outlet: "titleInput", class: "topic-title-editor", style: "display: none", keydown: "onKeyDownTitle"
      @section class: "inline-container", outlet: "form", keydown: "onKeyDown", =>
        @subview "editor", new Editor placeholder: "Say something…", disabled: yes
        @button "Post", class: "accent right", click: "submit"

  editTitle: ->
    @titleInput.value = @d.title
    @title.style.display = "none"
    @titleInput.style.display = ""
  cancelEditTitle: ->
    @title.style.display = ""
    @titleInput.style.display = "none"
  saveEditTitle: ->
    title = @titleInput.value.trim()
    return unless title
    @titleInput.disabled = yes
    @app.server.editTopicTitle {
      @id
      title
    }, (err) =>
      @d.title = title
      @titleInput.disabled = no
      if err
        @editor.focus()
        return
      @title.textContent = title
      @cancelEditTitle()

  enter: -> @editor.focus()

  initialize: ({@id, @app}) ->
    @form.style.display = "none" unless app.server.user
    @app.server.watch "topic", @id, @update
    @posts = []
    @app.server.getTopic @id, (err, @d) =>
      if err
        @app.setView new NotFound {url: location.pathname}
        return
      @editor.setDisabled no
      @editor.focus()
      @app.setTitle @d.title
      @title.textContent = @d.title
      @posts = for p, i in @d.posts
        @add (post = new Post {@app, top: i is 0, d: p}), @base, @form
        post

  update: (d) =>
    switch d.type
      when "add post"
        scroll = scrollY is document.body.offsetHeight - innerHeight
        @posts.push post = new Post {
          @app
          d: {
            body: d.body
            author: d.author
            created: new Date
          }
        }
        @add post, @base, @form
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
    @app.server.addPost {@id, body}, (err, id) =>
      @editor.setDisabled no
      @editor.focus()
      if err
        view.remove()
        return
      view.setPending no, id
      @editor.setValue ""

  onKeyDown: (e) ->
    @submit() if e.keyCode is 13 and (e.ctrlKey or e.metaKey)
  onKeyDownTitle: (e) ->
    @posts[0].saveEdit() if e.keyCode is 13 and (e.ctrlKey or e.metaKey)

module.exports = {Topic}
