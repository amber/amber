{View} = require "scene"

class ScriptEditor extends View
  isScriptEditor: yes

  @content: ->
    @div class: "scripts", mousedown: "onMouseDown", scroll: "onScroll", =>
      @subview new Script([
        Block.for "c", "#06c", "go to x: %n y: %n"
        Block.for "c", "#06c", "point in direction %n"
      ].concat (Block.for "c", "#06c", "move %n steps" for i in [1..50])).moveTo 8, 8

  initialize: ->
    @scrollX = @scrollY = 0
    @mouseTouch = null
    @touches = new Map

  enter: ->
    @bb = @base.getBoundingClientRect()

  onScroll: (e) ->
    @scrollX = @base.scrollLeft
    @scrollY = @base.scrollTop
    @onGestureMove @mouseTouch if @mouseTouch

  onMouseDown: (e) ->
    document.addEventListener "mousemove", @onMouseMove
    document.addEventListener "mouseup", @onMouseUp
    @onGestureStart @mouseTouch = x: e.clientX, y: e.clientY

  onMouseMove: (e) =>
    @mouseTouch.x = e.clientX
    @mouseTouch.y = e.clientY
    @onGestureMove @mouseTouch

  onMouseUp: (e) =>
    return if e.metaKey and e.ctrlKey
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

  onGestureMove: (d) ->
    return unless d.target
    if not d.dragging and (d.x - d.sx)**2 + (d.y - d.sy)**2 >= 4**2
      d.dragging = yes
      if d.target.isArg
        d.target = d.target.parent
      p = d.target.basePosition()
      d.script = d.target.detach()
      d.ox = p.x - d.sx
      d.oy = p.y - d.sy
      d.script.embed document.body
      d.script.addShadow 3, 3, 12, "rgba(0,0,0,.35)"
    if d.dragging
      d.script.moveTo d.ox + d.x + @bb.left - @scrollX, d.oy + d.y + @bb.top - @scrollY
    else

  onGestureEnd: (d) ->
    if d.dragging
      d.script.removeShadow()
      @add d.script.moveTo d.ox + d.x, d.oy + d.y
    else if d.target
      d.target.click()

  objectAt: (x, y) ->
    return o for s in @subviews by -1 when o = s.objectAt x - s.x, y - s.y

module.exports = {ScriptEditor}
{Script, Block} = require "./blocks"
