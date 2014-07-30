{View, $} = require "space-pen"
{Header} = require "am/views/header"
{Footer} = require "am/views/footer"
{Splash} = require "am/views/splash"

class App extends View
  @content: ->
    @div class: "app", =>
      @subview "header", new Header
      @subview "view", $("<div></div>")
      @subview "footer", new Footer

  initialize: ->
    $("body").keydown @onKeyDown

  setView: (view) ->
    @view.replaceWith view
    @view.parentView = null
    @view = view
    @view.parentView = @

  onKeyDown: (e) =>
    return if $(e.target).closest("input").length
    switch e.keyCode
      when 191
        @header.focusSearch ""

module.exports = {App}
