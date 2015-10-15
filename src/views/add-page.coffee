{View} = require "scene"
{T, slugify} = require "am/util"
{Editor} = require "am/views/editor"
{TagEditor} = require "am/views/tag-editor"

class AddPage extends View
  @content: ->
    @article class: "wiki", =>
      @h1 T("New wiki page")
      @div class: "inline-container", keydown: "onKeyDown", =>
        @input outlet: "titleInput", placeholder: T("Title"), input: "updateURL"
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

  title: -> T("New wiki page")
  enter: -> @titleInput.focus()

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
