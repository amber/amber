{View, $} = require "space-pen"
{T} = require "am/util"
{Header} = require "am/views/header"
{Footer} = require "am/views/footer"

class App extends View
  @content: ->
    @div class: "app", =>
      @subview "header", new Header
      @subview "view", $("<div></div>")
      @subview "footer", new Footer

  initialize: ->
    $("body").keydown @onKeyDown

  updateLanguage: ->
    @header.updateLanguage()
    @footer.updateLanguage()
    @router.route()

  dt: ->
    if DEBUG_TRANSLATIONS?
      delete window.DEBUG_TRANSLATIONS
    else
      window.DEBUG_TRANSLATIONS = yes
    @updateLanguage()

  setView: (view) ->
    @view.replaceWith view
    @view.parentView = null
    @view = view
    @view.parentView = @
    am = T("Amber")
    title = view.title?()
    document.title = (if title then "#{title} · #{am}" else am)

  onKeyDown: (e) =>
    return if $(e.target).closest("input").length
    switch e.keyCode
      when 191
        e.preventDefault()
        @header.focusSearch ""

module.exports = {App}
