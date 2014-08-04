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
        @button T("report"), class: "menu"
      @div outlet: "content", =>
        @html parse(body).result
      @div outlet: "editForm", class: "post-editor", style: "display: none", =>
        @subview "editor", new Editor {value: body}
        @section class: "two-buttons", =>
          @button click: "cancel", T("Cancel")
          @button click: "save", class: "accent", T("Save")

  initialize: ({@app, @d, pending}) ->
    app.server.getUser @d.author, (err, user) =>
      @author.textContent = user.name if user
    @setPending pending

  setPending: (pending) -> @base.classList.toggle "pending", pending

  edit: ->
    @content.style.display = "none"
    @editForm.style.display = "block"
    @editor.focus()

  cancel: ->
    @content.style.display = "block"
    @editForm.style.display = "none"

module.exports = {Post}
