{View, $} = require "space-pen"

class Editor extends View
  @content: ({placeholder}) ->
    @div =>
      @textarea outlet: "input", placeholder: placeholder ? "", input: "onInput"
      @div outlet: "metrics", class: "editor-metrics"

  onInput: ->
    @metrics.text "#{@input.val()}X"
    console.log @metrics.height()
    @input.css "height", "#{@metrics.height() + 10}px"

module.exports = {Editor}
