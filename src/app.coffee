{$} = require "space-pen"
{Header} = require "am/views/header"
{Footer} = require "am/views/footer"
{Splash} = require "am/views/splash"

class App
  constructor: (@base) ->
    @base
      .append(@header = new Header)
      .append(@view = $("<div></div>"))
      .append(@footer = new Footer)
      .on "keydown", @onKeyDown

  setView: (view) ->
    @view.replaceWith @view = view

  onKeyDown: (e) =>
    return if $(e.target).closest("input").length
    switch e.keyCode
      when 191
        @header.focusSearch ""

module.exports = {App}
