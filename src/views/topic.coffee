{View, $$} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"
{Post} = require "am/views/post"
{Editor} = require "am/views/editor"
{TagEditor} = require "am/views/tag-editor"

class Topic extends View
  @content: ({id}) ->
    @article class: "discuss", =>
      @div keydown: "onKeyDownTitle", =>
        @h1 =>
          @span T("Loading…"), outlet: "title"
          @input outlet: "titleInput", class: "topic-title-editor", style: "display: none"
        @p outlet: "tags"
        @p outlet: "tagEditorWrap", style: "display: none", =>
          @subview "tagEditor", new TagEditor
      @section class: "inline-container", outlet: "form", keydown: "onKeyDown", =>
        @subview "editor", new Editor placeholder: "Say something…", disabled: yes
        @button "Post", class: "accent right", click: "submit"

  edit: ->
    @titleInput.value = @d.title
    @title.style.display = "none"
    @titleInput.style.display = ""

    @tags.style.display = "none"
    @tagEditorWrap.style.display = ""
    @tagEditor.setTags @d.tags

  cancelEdit: ->
    @title.style.display = ""
    @titleInput.style.display = "none"
    @tags.style.display = ""
    @tagEditorWrap.style.display = "none"

  saveEdit: ->
    title = @titleInput.value.trim()
    tags = @tagEditor.getTags()
    return unless title
    @titleInput.disabled = yes
    @app.server.editTopic {
      @id
      title
      tags
    }, (err) =>
      @d.title = title
      @d.tags = tags
      @titleInput.disabled = no
      if err
        @editor.focus()
        return
      @title.textContent = title
      @updateTags tags
      @cancelEdit()

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
      @updateTags @d.tags
      @posts = for p, i in @d.posts
        @add (post = new Post {@app, top: i is 0, d: p}), @base, @form
        post

  updateTags: (tags) ->
    @tags.removeChild @tags.lastChild while @tags.firstChild
    @tags.appendChild $$ ->
      for t in tags
        @a T(t), class: "tag tag-#{t}", href: "/discuss/t/#{encodeURIComponent t}"

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
    @posts[0].saveEdit() if e.keyCode is 13

module.exports = {Topic}
