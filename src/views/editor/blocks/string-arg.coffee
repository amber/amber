{Arg} = require "./arg"
{metrics} = require "./metrics"

measure = metrics "string-arg"

class StringArg extends Arg
  @types "n", "d", "s"

  @content: ->
    @input class: "abs string-arg", input: "updateSize"

  initialize: (@type, @menu, value) ->
    super
    @isNumeric = @type in ["n", "d"]
    @value = ""
    @setValue value ? if @isNumeric then 10 else ""

  setValue: (value) ->
    return if @value is value
    @value = value
    @base.value = "#{value}"
    @updateSize()

  updateSize: ->
    {w,h} = measure @base.value

    @setSize w, h

  hitTest: (x, y) -> 0 <= x < @w and 0 <= y < @h

  click: ->
    @base.focus()
    [@base.selectionStart, @base.selectionEnd] = [0, @base.value.length]

  sizeChanged: (w) ->
    @base.style.width = "#{w}px"

module.exports = {StringArg}
