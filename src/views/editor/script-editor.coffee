{View} = require "scene"

class ScriptEditor extends View
  isScriptEditor: yes

  @content: ->
    @div class: "scripts", mousedown: "onMouseDown", scroll: "onScroll", =>
      @div outlet: "fill", class: "fill"
      @subview new Script([
        Block.for "c", "#06c", "go to x: %n y: %n"
        Block.for "c", "#06c", "point in direction %n"
      ].concat (Block.for "c", "#06c", "move %n steps" for i in [1..50])).moveTo 8, 8

  initialize: ->
    @scrollX = @scrollY = 0
    @mouseTouch = null
    @touches = new Map

  enter: ->
    @onResize()
    addEventListener "resize", @onResize
  afterEnter: ->
    @updateBounds()
  exit: ->
    removeEventListener "resize", @onResize

  onResize: (e) =>
    @bb = @base.getBoundingClientRect()
    if e
      s.updatePixelRatio() for s in @subviews

  onScroll: (e) ->
    @scrollX = @base.scrollLeft
    @scrollY = @base.scrollTop
    @updateFill()
    @onGestureMove @mouseTouch if @mouseTouch

  onMouseDown: (e) ->
    return if e.target.tagName in ["INPUT"]
    e.preventDefault()
    document.addEventListener "mousemove", @onMouseMove
    document.addEventListener "mouseup", @onMouseUp
    @onGestureStart @mouseTouch = x: e.clientX, y: e.clientY

  onMouseMove: (e) =>
    e.preventDefault()
    @mouseTouch.x = e.clientX
    @mouseTouch.y = e.clientY
    @onGestureMove @mouseTouch

  onMouseUp: (e) =>
    return if e.metaKey and e.ctrlKey
    e.preventDefault()
    @mouseTouch.x = e.clientX
    @mouseTouch.y = e.clientY
    @onGestureEnd @mouseTouch
    @mouseTouch = null
    document.removeEventListener "mousemove", @onMouseMove
    document.removeEventListener "mouseup", @onMouseUp

  onGestureStart: (d) ->
    d.sx = d.x
    d.sy = d.y
    d.target = @objectAt d.x - @bb.left + @scrollX, d.y - @bb.top + @scrollY
    document.activeElement.blur()

  onGestureMove: (d) ->
    return unless d.target
    if not d.dragging and (d.x - d.sx)**2 + (d.y - d.sy)**2 >= 4**2
      d.dragging = yes
      if d.target.isArg
        d.target = d.target.parent
      p = d.target.basePosition()
      d.script = d.target.detach()
      d.ox = p.x - d.sx - @scrollX
      d.oy = p.y - d.sy - @scrollY
      d.script.embed document.body
      d.script.addShadow 3, 3, 12, "rgba(0,0,0,.35)"
    if d.dragging
      d.script.moveTo d.ox + d.x + @bb.left, d.oy + d.y + @bb.top
    else

  onGestureEnd: (d) ->
    if d.dragging
      d.script.removeShadow()
      @add d.script.moveTo d.ox + d.x + @scrollX, d.oy + d.y + @scrollY
    else if d.target
      d.target.click()

  add: (script) ->
    super script
    @updateBounds()

  padding: -> 8
  extraSpace: -> 200

  updateBounds: ->
    minX = minY = pad = @padding()
    maxX = maxY = 0
    for s in @subviews
      minX = l if minX > l = s.x
      minY = l if minY > l = s.y
      maxX = l if maxX < l = s.x + s.w
      maxY = l if maxY < l = s.y + s.h

    if minX < pad || minY < pad
      deltaX = Math.max 0, pad - minX
      deltaY = Math.max 0, pad - minY
      for s in @subviews
        s.moveTo s.x + deltaX, s.y + deltaY
      minX += deltaX
      minY += deltaY
      maxX += deltaX
      maxY += deltaY

    [@minX, @minY, @maxX, @maxY] = [minX, minY, maxX, maxY]
    @updateFill()
  updateFill: ->
    es = @extraSpace()
    maxX = es + Math.max @scrollX + @bb.width, @maxX
    maxY = es + Math.max @scrollY + @bb.height, @maxY
    @fill.style.transform = "translate(#{maxX}px, #{maxY}px)"

  objectAt: (x, y) ->
    return o for s in @subviews by -1 when o = s.objectAt x - s.x, y - s.y

module.exports = {ScriptEditor}
{Script, Block} = require "./blocks"
