{View} = require "scene"
{T} = require "am/util"
{Header} = require "am/views/base/header"
{Footer} = require "am/views/base/footer"
{ErrorOverlay} = require "am/views/base/error-overlay"

class App extends View
  @content: ->
    @div class: "app", =>
      @subview "errors", new ErrorOverlay {app: @view}
      @subview "header", new Header {app: @view}
      @subview "view", new View
      @subview "footer", new Footer {app: @view}

  initialize: ->
    document.body.addEventListener "keydown", @onKeyDown

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
    @view.replaceWith @view = view
    @setTitle view.title?()

  setTitle: (title) ->
    am = T("Amber")
    document.title = (if title then "#{title} · #{am}" else am)

  setUser: (user) -> @header.setUser user

  onKeyDown: (e) =>
    t = e.target
    while t
      return if t.tagName in ["INPUT", "TEXTAREA"]
      t = t.parentNode
    switch e.keyCode
      when 191
        e.preventDefault()
        @header.focusSearch ""

module.exports = {App}
