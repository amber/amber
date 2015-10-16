{T} = require "am/util"
{parse} = require "am/markup"
{Post} = require "am/views/discuss/post"
{Editor} = require "am/views/components/editor"
{RelativeDate} = require "am/views/components/relative-date"

class ArticlePost extends Post
  @content: ({app, d: {body, modified, author}}) ->
    @section class: "post article", =>
      @img src: "http://lorempixel.com/100/100/abstract/1", style: "display: none"
      @div outlet: "content", class: "content", =>
        @html parse(body).result
      @div outlet: "editForm", keydown: "onKeyDown", class: "post-editor", =>
        @subview "editor", new Editor placeholder: T("Message")
        @section class: "two-buttons", =>
          @button click: "cancelEdit", T("Cancel")
          @button click: "saveEdit", class: "accent", T("Save")
      @div class: "author", =>
        @text "Last edited by "
        @a outlet: "author", href: "/user/#{author}"
        @text " "
        @subview new RelativeDate modified
        @button T("edit"), click: "edit", class: "menu" if app.server.user
        @button T("delete"), outlet: "deleteButton", mouseleave: "unconfirmDelete", click: "delete", class: "menu" if app.server.user
        @button T("report"), class: "menu"

module.exports = {ArticlePost}
