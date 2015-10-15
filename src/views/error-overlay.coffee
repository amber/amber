{View} = require "scene"

class ErrorOverlay extends View
  @content: ->
    @pre class: "error-overlay", style: "display: none"

  showError: (error) ->
    @base.textContent = error
    @base.style.display = ""

  hide: ->
    @base.style.display = "none"

module.exports = {ErrorOverlay}
