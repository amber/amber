{View} = require "scene"
{parse} = require "markup"
{T} = require "am/util"
{RelativeDate} = require "am/views/relative-date"
{Editor} = require "am/views/editor"

class Post extends View
  @content: ({app, d: {author, created, body}}) ->
    @section class: "post", =>
      @img src: "http://lorempixel.com/100/100/abstract/1"
      @div class: "author", =>
        @a outlet: "author", href: "/user/#{author}"
        @text " posted "
        @subview new RelativeDate created
        @button T("edit"), click: "edit", class: "menu" if author is app.server.user?.id
        @button T("delete"), outlet: "deleteButton", mouseleave: "unconfirmDelete", click: "delete", class: "menu" if author is app.server.user?.id
        @button T("report"), class: "menu"
      @div outlet: "content", =>
        @html parse(body).result
      @div outlet: "editForm", keydown: "onKeyDown", class: "post-editor", style: "display: none", =>
        @subview "editor", new Editor
        @section class: "two-buttons", =>
          @button click: "cancel", T("Cancel")
          @button click: "save", class: "accent", T("Save")

  initialize: ({@app, @d, pending}) ->
    app.server.getUser @d.author, (err, user) =>
      @author.textContent = user.name if user
    @setPending pending

  setPending: (pending) -> @base.classList.toggle "pending", pending

  edit: ->
    @showEditor yes
    @editor.setValue @d.body
    @editor.focusEnd()

  delete: ->
    unless @deleteButton.classList.contains "confirm"
      return @confirmDelete()
    @app.server.hidePost {
      id: @d.id
      topic: @parent.id
    }, (err) =>
      @base.style.display = "none"
  confirmDelete: ->
    @deleteButton.classList.add "confirm"
  unconfirmDelete: ->
    @deleteButton.classList.remove "confirm"

  save: ->
    @editor.setDisabled yes
    @app.server.editPost {
      id: @d.id
      topic: @parent.id
      body: body = @editor.getValue()
    }, (err) =>
      @d.body = body
      @editor.setDisabled no
      @content.innerHTML = parse(body).result
      if err
        @editor.focus()
        return
      @showEditor no

  cancel: -> @showEditor no

  showEditor: (flag) ->
    @content.style.display = (if flag then "none" else "block")
    @editForm.style.display = (if flag then "block" else "none")

  onKeyDown: (e) ->
    if e.keyCode is 13 and (e.metaKey or e.ctrlKey)
      @save()

module.exports = {Post}
