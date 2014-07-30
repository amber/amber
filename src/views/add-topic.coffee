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
        @button T("Create")

  afterAttach: ->
    @title.focus()

module.exports = {AddTopic}
