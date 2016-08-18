{View} = require "scene"
{parse} = require "am/markup"
{T, relativeDate} = require "am/util"
{RelativeDate} = require "am/views/components/relative-date"
{Editor} = require "am/views/components/editor"

class Post extends View
  @content: ({app, d}) ->
    {author, created, updated, body} = d
    @section class: "post", =>
      @img src: "http://lorempixel.com/100/100/abstract/1"
      @div class: "author", =>
        @a outlet: "author", href: "/user/#{author}"
        @text " posted "
        @subview new RelativeDate created
        @time class: "edited", outlet: "edited", mouseenter: "updateEdited"
        if app.server.user?.canEditPost d
          @button T("edit"), click: "edit", class: "menu edit"
          @button T("delete"), outlet: "deleteButton", mouseleave: "unconfirmDelete", click: "delete", class: "menu delete"
        @button T("report"), class: "menu"
      @div outlet: "content", class: "content", =>
        @html parse(body).result
      @div outlet: "editForm", keydown: "onKeyDown", class: "post-editor", =>
        @subview "editor", new Editor placeholder: T("Message")
        @section class: "two-buttons", =>
          @button click: "cancelEdit", T("Cancel")
          @button click: "saveEdit", class: "accent", T("Save")

  initialize: ({@app, @top, @d, pending}) ->
    app.server.getUser @d.author, (err, user) =>
      @author.textContent = user.name if user
    @setEdited @d.updated > @d.created
    @setPending pending

  setPending: (pending, id) ->
    @d.id = id if id?
    @base.classList.toggle "pending", !!pending

  edit: ->
    @parent.edit() if @top
    @showEditor yes
    @editor.setValue @d.body
    @editor.focusEnd()

  delete: ->
    unless @deleteButton.classList.contains "confirm"
      return @confirmDelete()
    if @top
      return @app.server.hideTopic {
        id: @parent.id
      }, (err) =>
        return if err # TODO
        @parent.app.router.go "/discuss"
    @app.server.hidePost {
      id: @d.id
      topic: @parent.id
    }, (err) =>
      return if err # TODO
      @base.style.display = "none"
  confirmDelete: ->
    @deleteButton.classList.add "confirm"
  unconfirmDelete: ->
    @deleteButton.classList.remove "confirm"

  saveEdit: ->
    body = @editor.getValue().trim()
    return unless body
    @parent.saveEdit() if @top
    @editor.setDisabled yes
    @app.server.editPost {
      id: @d.id
      topic: @parent.id
      body
    }, (err) =>
      @editor.setDisabled no
      if err
        @editor.focus()
        return
      @setBody body
      @showEditor no

  setEdited: (e) ->
    return unless @edited
    @edited.style.display = if e then "" else "none"
    @edited.setAttribute "datetime", @d.updated.toISOString()
  updateEdited: ->
    @edited.title = T("Last edited {when}", when: relativeDate @d.updated)

  setBody: (body) ->
    @d.body = body
    @d.updated = new Date
    @setEdited yes
    @content.innerHTML = parse(body).result

  markDeleted: ->
    @content.textContent = T("[Deleted]")
    @base.classList.add "deleted"

  cancelEdit: ->
    @showEditor no
    @parent.cancelEdit() if @top

  showEditor: (flag) ->
    @base.classList.toggle "editing", flag

  onKeyDown: (e) ->
    if e.keyCode is 13 and (e.metaKey or e.ctrlKey)
      @saveEdit()

module.exports = {Post}
