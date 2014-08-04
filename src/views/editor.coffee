{View} = require "scene"

class Editor extends View
  @content: ({placeholder} = {}) ->
    @div =>
      @textarea outlet: "input", placeholder: placeholder ? "", input: "onInput"
      @div outlet: "metrics", class: "editor-metrics"

  initialize: ({disabled, value}) ->
    @setDisabled disabled
    @setValue value if value?

  focus: -> @input.focus()
  focusEnd: ->
    @input.focus()
    @input.selectionStart = @input.selectionEnd = @input.value.length
  setDisabled: (d) -> @input.disabled = d
  getValue: -> @input.value
  setValue: (v) -> @input.value = v

  onInput: ->
    @metrics.textContent = "#{@input.value}X"
    @input.style.height = "#{@metrics.offsetHeight + 10}px"

module.exports = {Editor}
