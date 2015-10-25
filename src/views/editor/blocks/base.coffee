{View} = require "scene"

class Base extends View
  initialize: ->
    @x = @y = @w = @h = 0
    @isDirty = no

  moveTo: (@x, @y) ->
    @base.style.transform = "translate(#{@x|0}px, #{@y|0}px)"
    this

  basePosition: ->
    o = @
    x = 0; y = 0
    while o and not o.isScriptEditor
      x += o.x; y += o.y
      o = o.parent
    {x, y}

  dirty: ->
    if @inDocument
      @layout()
    else
      @isDirty = yes
    this
  dirtyUp: ->
    if @inDocument then @layoutUp()
  enter: ->
    if @isDirty
      @layoutDown()

  layoutDown: ->
    v.layoutDown() for v in @subviews
    @isDirty = no
    @layout()
    this
  layoutUp: ->
    @layout()
    @parent.layoutUp?()
    this
  layout: ->

  setSize: (w, h) ->
    return if w is @w and h is @h
    @w = w
    @h = h

    @sizeChanged w, h
    @dirtyUp()

  sizeChanged: ->

  hitTest: -> no
  objectAt: -> null
  click: ->

module.exports = {Base}
