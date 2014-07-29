{$} = require "space-pen"
{Header} = require "am/views/header"
{Footer} = require "am/views/footer"
{Splash} = require "am/views/splash"

class App
  constructor: (@base) ->
    @base
      .append(@header = new Header)
      .append(@view = $('<div></div>'))
      .append(@footer = new Footer)

  setView: (view) ->
    @view.replaceWith @view = view

module.exports = {App}
