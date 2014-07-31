{View} = require "scene"
{T} = require "am/util"
{Editor} = require "am/views/editor"

class AddTopic extends View
  @content: ->
    @article =>
      @h1 T("New topic")
      @div class: "inline-container", =>
        @input outlet: "titleInput", placeholder: T("Title")
        @subview "body", new Editor placeholder: T("Message")
        @section class: "two-buttons", =>
          @button class: "accent", T("Create")
          @button click: "cancel", T("Cancel")

  title: -> T("New topic")
  enter: -> @titleInput.focus()

  cancel: -> history.back()

module.exports = {AddTopic}
