{Base} = require "./base"
{$$} = require "scene"
{metrics} = require "./metrics"

measure = metrics "label"

class Label extends Base
  @measure: measure

  @content: (text) ->
    @div class: "abs label", "#{text}"

  initialize: (@text) ->
    super
    box = measure @text
    @w = box.w
    @h = box.h

module.exports = {Label}
