{View} = require "scene"
{T, slugify, deslugify} = require "am/util"
{Topic} = require "am/views/discuss/topic"
{Editor} = require "am/views/components/editor"
{TagEditor} = require "am/views/components/tag-editor"

class AddPage extends View
  @content: ({page}) ->
    @article class: "wiki", =>
      @h1 T("New wiki page")
      @div class: "inline-container", keydown: "onKeyDown", =>
        @input outlet: "titleInput", placeholder: T("Title"), input: "updateURL", value: if page then deslugify page else ""
        @input outlet: "urlInput", placeholder: T("URL"), input: "hideError", class: "url-input"
        @subview "body", new Editor placeholder: T("Page")
        @subview "tags", new TagEditor placeholder: T("Add tags…"), permanent: ["wiki"]
        @p outlet: "error", class: "error", style: "display: none", =>
        @section class: "two-buttons", =>
          @button click: "cancel", T("Cancel")
          @button click: "submit", class: "accent", T("Create")

  initialize: ({@app}) ->
    @body.on "input", @hideError
    @urlInput.disabled = not @app.server.user?.isAdmin
    @updateURL()

  title: -> T("New wiki page")
  enter: -> (if @titleInput.value then @body else @titleInput).focus()

  cancel: -> history.back()
  submit: ->
    title = @titleInput.value.trim()
    url = @urlInput.value.trim()
    body = @body.getValue().trim()
    unless title
      @titleInput.select()
      return @showError T("Your page needs a title.")
    unless url
      @urlInput.select()
      return @showError T("Your page needs a URL.")
    unless body
      @body.select()
      return @showError T("Your page needs some content.")
    tags = @tags.getTags()
    @parent.server.addWikiPage {title, url, body, tags}, (err, data) =>
      return if err # TODO
      history.replaceState null, null, url
      @parent.setView new Topic {app: @parent, url}

  updateURL: ->
    title = @titleInput.value
    @urlInput.value = if title then "/wiki/#{slugify title}" else ""
    @hideError()

  showError: (message) ->
    @error.style.display = "block"
    @error.textContent = message
  hideError: =>
    @error.style.display = "none"

  onKeyDown: (e) ->
    if e.keyCode is 13 and (e.ctrlKey or e.metaKey)
      e.preventDefault()
      @submit()

module.exports = {AddPage}
