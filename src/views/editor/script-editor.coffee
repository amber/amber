{View} = require "scene"

class ScriptEditor extends View
  isScriptEditor: yes

  @content: ->
    @div class: "scripts", mousedown: "onMouseDown", scroll: "onScroll", =>
      @div outlet: "fill", class: "fill"
      @subview new Script([
        Block.for "c", "#06c", "go to x: %n y: %n"
        Block.for "c", "#06c", "point in direction %n"
        Block.for "c", "#d95", "forever %t"
      ].concat (Block.for "c", "#06c", "move %n steps", [Math.random() * 1000 | 0] for i in [1..50])).moveTo 8, 8

  initialize: ->
    @overlay = (@build -> @div class: "scripts-overlay").firstChild
    @feedbackPool = []

    @scrollX = @scrollY = 0
    @mouseTouch = null
    @touches = new Map

  enter: ->
    @onResize()
    addEventListener "resize", @onResize
    document.body.appendChild @overlay
  afterEnter: ->
    @updateBounds()
  exit: ->
    removeEventListener "resize", @onResize
    document.body.removeChild @overlay

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
      d.script.embed @overlay
      d.script.addShadow 3, 3, 12, "rgba(0,0,0,.35)"
      d.cx = @feedback()
    if d.dragging
      d.script.moveTo d.ox + d.x + @bb.left, d.oy + d.y + @bb.top
      d.feedback = @getFeedback d.script, d.ox + d.x + @scrollX, d.oy + d.y + @scrollY
      @renderFeedback d.feedback, d.cx
    else

  onGestureEnd: (d) ->
    if d.dragging
      d.script.removeShadow()
      @releaseFeedback d.cx
      @applyFeedback d.feedback, d
    else if d.target
      d.target.click()

  getFeedback: (script, x, y) ->
    if script.subviews[0].isCommand
      @getCommandFeedback script, x, y
    else
      null

  commandThreshold: -> x: 20, y: 10

  getCommandFeedback: (script, sx, sy) ->
    th = @commandThreshold()
    result = null

    @enumerateScripts (s, x, y) ->
      return unless sx >= x - th.x && sx < x + th.x
      for b, i in s.subviews
        if sy >= y - th.y && sy < y + th.y || i == 0 && s.parent.isScriptEditor && sy + script.h >= y - th.y && sy + script.h < y + th.y
          result = {kind: "insert", target: b}
        y += b.h
      if sy >= y - th.y && sy < y + th.y
        result = {kind: "append", target: s}

    result

  applyFeedback: (f, d) ->
    unless f
      @add d.script.moveTo d.ox + d.x + @scrollX, d.oy + d.y + @scrollY
      return
    switch f.kind
      when "insert"
        f.target.insert d.script
      when "append"
        f.target.append d.script

  renderFeedback: (f, cx) ->
    cv = cx.canvas
    unless f
      cv.style.display = "none"
      return
    cv.style.display = "block"

    switch f.kind
      when "insert"
        {x,y} = f.target.basePosition()
        @renderCommandFeedback cx, x, y, f.target.w
      when "append"
        {x,y} = f.target.basePosition()
        @renderCommandFeedback cx, x, y + f.target.h, f.target.subviews[f.target.subviews.length-1]?.w ? f.target.parent.parent.w

  renderCommandFeedback: (cx, x, y, w) ->
    ps = d: 4, blur: 8, ox: 2, oy: 2, color: "rgba(0,0,0,.4)"
    {px, pw} = CommandBlock::params()
    b = CommandBlock::outset().bottom
    r = ps.d / 2 + ps.blur
    x += @bb.left - @scrollX
    y += @bb.top - @scrollY
    pr = devicePixelRatio ? 1

    cx.canvas.width = pr * (w + r*2 + ps.ox)
    cx.canvas.height = pr * (r*2 + b + ps.oy)
    cx.canvas.style.transform = "translate(#{x-r}px, #{y-r}px) scale(#{1/pr})"
    cx.scale pr, pr

    cx.strokeStyle = "#fff"
    cx.lineWidth = ps.d
    cx.lineCap = "round"
    cx.shadowOffsetX = ps.ox
    cx.shadowOffsetY = ps.oy
    cx.shadowBlur = ps.blur
    cx.shadowColor = ps.color
    cx.moveTo r + b, r
    cx.lineTo r + px - b, r
    cx.lineTo r + px, r + b
    cx.lineTo r + px + pw, r + b
    cx.lineTo r + px + pw + b, r
    cx.lineTo r + w - b, r
    cx.stroke()

  feedback: ->
    if @feedbackPool.length
      cx = @feedbackPool.pop()
      cx.canvas.style.display = "block"
    else
      cv = (@build -> @canvas class: "abs").firstChild
      @overlay.insertBefore cv, @overlay.firstChild
      cx = cv.getContext "2d"
      @feedbackPool.push cx
    cx
  releaseFeedback: (cx) ->
    @feedbackPool.push cx
    cx.canvas.style.display = "none"

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

  layoutUp: -> @updateBounds()

  objectAt: (x, y) ->
    return o for s in @subviews by -1 when o = s.objectAt x - s.x, y - s.y

  enumerateScripts: (fn) ->
    s.enumerateScripts fn, 0, 0 for s in @subviews

module.exports = {ScriptEditor}
{Script, Block, CommandBlock} = require "./blocks"
