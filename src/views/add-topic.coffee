{View} = require "scene"
{T} = require "am/util"
{Editor} = require "am/views/editor"
{TagEditor} = require "am/views/tag-editor"
{Topic} = require "am/views/topic"

class AddTopic extends View
  @content: ->
    @article class: "discuss", =>
      @h1 T("New topic")
      @div class: "inline-container", keydown: "onKeyDown", =>
        @input outlet: "titleInput", placeholder: T("Title"), input: "hideError"
        @subview "body", new Editor placeholder: T("Message")
        @subview "tags", new TagEditor placeholder: T("Add tags…")
        @p outlet: "error", class: "error", style: "display: none", =>
        @section class: "two-buttons", =>
          @button click: "cancel", T("Cancel")
          @button click: "submit", class: "accent", T("Create")

  initialize: ->
    @body.on "input", @hideError

  title: -> T("New topic")
  enter: -> @titleInput.focus()

  cancel: -> history.back()
  submit: ->
    title = @titleInput.value.trim()
    body = @body.getValue().trim()
    unless title
      @titleInput.select()
      return @showError T("Your post needs a title.")
    unless body
      @body.select()
      return @showError T("Your post needs a message.")
    tags = @tags.getTags()
    @parent.server.addTopic {title, body, tags}, (err, data) =>
      return if err # TODO
      history.replaceState null, null, "/topic/#{data.id}"
      @parent.setView new Topic {app: @parent, id: data.id}

  showError: (message) ->
    @error.style.display = "block"
    @error.textContent = message
  hideError: =>
    @error.style.display = "none"

  onKeyDown: (e) ->
    if e.keyCode is 13 and (e.ctrlKey or e.metaKey)
      e.preventDefault()
      @submit()

module.exports = {AddTopic}
