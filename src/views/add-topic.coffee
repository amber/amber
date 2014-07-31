{View} = require "scene"
{T} = require "am/util"
{Editor} = require "am/views/editor"
{Topic} = require "am/views/topic"

class AddTopic extends View
  @content: ->
    @article =>
      @h1 T("New topic")
      @div class: "inline-container", keydown: "onKeyDown", =>
        @input outlet: "titleInput", placeholder: T("Title")
        @subview "body", new Editor placeholder: T("Message")
        @section class: "two-buttons", =>
          @button click: "cancel", T("Cancel")
          @button click: "submit", class: "accent", T("Create")

  title: -> T("New topic")
  enter: -> @titleInput.focus()

  cancel: -> history.back()
  submit: ->
    @parent.server.addTopic {
      title: @titleInput.value
      body: @body.getValue()
    }, (err, data) =>
      return if err # TODO
      history.replaceState null, null, "/topic/#{data.id}"
      @parent.setView new Topic {app: @parent, id: data.id}

  onKeyDown: (e) ->
    if e.keyCode is 13 and (e.ctrlKey or e.metaKey)
      e.preventDefault()
      @submit()

module.exports = {AddTopic}
