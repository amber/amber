{View} = require "scene"
{emitter} = require "am/util"

class Editor extends View
  emitter @::

  @content: ({placeholder} = {}) ->
    @div class: "text-editor", =>
      @textarea outlet: "input", placeholder: placeholder ? "", input: "onInput"
      @div outlet: "metrics", class: "editor-metrics"

  initialize: ({disabled, value} = {}) ->
    @setDisabled disabled
    @setValue value if value?

  focus: -> @input.focus()
  select: -> @input.select()
  focusEnd: ->
    @input.focus()
    @input.selectionStart = @input.selectionEnd = @input.value.length
  setDisabled: (d) -> @input.disabled = d
  getValue: -> @input.value
  setValue: (v) ->
    @input.value = v
    @onInput()

  onInput: ->
    text = @input.value
    @metrics.textContent = text + (if text[text.length-1] in ["\n", "\x0b", "\x0c", "\r", "\x85", "\u2028", "\u2029"] then "X" else "")
    @input.style.height = "#{@metrics.offsetHeight}px"
    @emit "input"

module.exports = {Editor}
