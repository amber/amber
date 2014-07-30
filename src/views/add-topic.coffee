{View, $} = require "space-pen"
{T} = require "am/util"
{Editor} = require "am/views/editor"

class AddTopic extends View
  @content: ->
    @article =>
      @h1 T("New topic")
      @div class: "inline-container", =>
        @input outlet: "title", placeholder: T("Title")
        @subview "body", new Editor placeholder: T("Message")
        @button class: "accent", T("Create")
        @a click: "cancel", class: "button", T("Cancel")

  afterAttach: ->
    @title.focus()

  cancel: ->
    history.back()

module.exports = {AddTopic}
