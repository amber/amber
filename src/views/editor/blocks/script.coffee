{Base} = require "./base"
{$$} = require "scene"

class Script extends Base
  isScript: yes

  @content: ->
    @div class: "abs", =>

  initialize: (blocks) ->
    super
    @add b for b in blocks
    @dirty()

  layout: ->
    y = 0
    w = 0
    for b in @subviews
      y += 1 if y
      b.moveTo 0, y
      w = Math.max w, b.w
      y += b.h
    @w = w
    @h = y

  objectAt: (x, y) ->
    return o for b in @subviews when o = b.objectAt x-b.x, y-b.y

  splitFrom: (b) ->
    i = @subviews.indexOf b
    switch i
      when 0 then @
      when -1 then new Script[b]
      else
        script = new Script @subviews.slice i
        @dirty()
        script

  addShadow: (ox, oy, blur, color) ->
    return if @shadow
    @base.insertBefore (@shadow = ($$ -> @canvas class: "abs").firstChild), @base.firstChild

    pr = devicePixelRatio ? 1
    w = @w + blur * 2
    h = Math.min screen.height + @subviews[0].h, @h + blur * 2
    @shadow.style.transform = "translate(#{ox - blur}px, #{oy - blur}px)"
    @shadow.style.width = "#{w}px"
    @shadow.style.height = "#{h}px"
    @shadow.width = pr * w
    @shadow.height = pr * h

    cx = @shadow.getContext "2d"
    cx.scale pr, pr
    cx.shadowBlur = blur * pr
    cx.shadowOffsetX = ox * pr
    cx.shadowOffsetY = oy * pr
    cx.shadowColor = color

    cx.translate -ox + blur, -oy + blur
    cx.beginPath()
    for b in @subviews
      b.pathOn cx, b.x, b.y, b.w, b.h

    cx.fillStyle = "#000"
    cx.fill()

  removeShadow: ->
    return unless @shadow
    @base.removeChild @shadow
    @shadow = null

module.exports = {Script}
