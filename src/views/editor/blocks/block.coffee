{Base} = require "./base"

registry = new Map

class Block extends Base
  isBlock: yes

  @for: (type, color, spec, args) ->
    Cons = registry.get type
    new Cons type, color, spec, args

  @type: (type) -> registry.set type, this
  @types: (types...) -> @type t for t in types

  @content: ->
    @div class: "abs", =>
      @canvas outlet: "cv", class: "abs"

  initialize: (@type, @color, spec, args = []) ->
    super
    @cx = @cv.getContext "2d"
    out = @outset()

    @setSpec spec, args

  setSpec: (@spec, args) ->
    if @args then for a in @args
      a.remove()
    @args = []
    @defaultArgs = []
    j = 0
    for p, i in @spec.split /(%\w+(?:\.\w+)?)/
      if i % 2 is 0
        @add new Label word for word in p.trim().split /\s+/ when word
      else
        [type, menu] = p.slice(1).split "."
        given = args[j]
        @add arg = if given?.isBlock then given else @defaultArgs[j] = Arg.for type, menu, given
        j++
        @args.push arg
    @dirty()

  wrapWidth: -> 400

  layout: ->
    pad = @padding()
    sp = @spacing()
    ww = @wrapWidth()

    x = pad.left
    w = 0
    y = pad.top
    h = 0
    i = 0
    li = false
    line = 0

    wrap = (last) =>
      for k in [line...i]
        view = @subviews[k]
        view.moveTo view.x, y + (h - view.h) / 2
      unless last
        y += sp.y + h
        w = Math.max w, x
        h = 0
        x = pad.left
        li = false
        line = i

    while i < @subviews.length
      view = @subviews[i]
      x += sp.x if li
      li = true
      wrap() if view.wrapBefore || x + view.w > ww
      i++
      view.moveTo x, 0
      x += view.w
      h = Math.max h, view.h
      wrap() if view.wrapAfter
    wrap true

    @setSize Math.max(w, x) + pad.right, y + (Math.max 3, h) + pad.bottom

  pixelRatioChanged: -> @sizeChanged @w, @h

  sizeChanged: (w, h) ->
    out = @outset()
    pr = devicePixelRatio ? 1

    @cv.width = (w + out.left + out.right) * pr
    @cv.height = (h + out.top + out.bottom) * pr
    @cv.style.transform = "translate(#{-out.left}px,#{-out.right}px) scale(#{1/pr}"

    @cx.scale pr, pr
    @draw()

  outset: -> left: 0, right: 0, top: 0, bottom: 0
  padding: -> left: 3, right: 3, top: 3, bottom: 3
  spacing: -> x: 4, y: 4

  draw: ->
    out = @outset()

    @cx.fillStyle = @color
    @cx.beginPath()
    @pathFullOn @cx, out.left, out.top, @w, @h
    @cx.fill()

    @cx.strokeStyle = "rgba(0,0,0,.35)"
    @cx.beginPath()
    @pathFullOutlineOn @cx, out.left, out.top, @w, @h
    @cx.stroke()

  pathFullOn: (cx, x, y, w, h) ->
    cx.translate x, y
    @pathOn cx, w, h

    {pw, px, r} = CommandBlock::params()
    for t in @subviews when t.isScriptArg
      cx.moveTo t.x, t.y + r
      cx.lineTo t.x, t.y + t.h - r
      cx.lineTo t.x + r, t.y + t.h
      cx.lineTo w - r, t.y + t.h
      cx.lineTo w, t.y + t.h + r
      cx.lineTo w, t.y - r
      cx.lineTo w - r, t.y
      cx.lineTo t.x + r, t.y
      cx.lineTo t.x + px + pw + r - .25, t.y
      cx.lineTo t.x + px + pw - .25, t.y + r
      cx.lineTo t.x + px + .25, t.y + r
      cx.lineTo t.x + px - r + .25, t.y
      cx.lineTo t.x + r, t.y
      cx.closePath()
      # cx.arc t.x + r, t.y + r, r, Math.PI, Math.PI * 3/2
      # cx.arc @w - r, t.y - r, r, Math.PI/2, 0, true
      # cx.arc @w - r, t.y + t.h + r, r, 0, Math.PI * 3/2, true
      # cx.arc t.x + r, t.y + t.h - r, r, Math.PI/2, Math.PI
    cx.translate -x, -y

  pathFullOutlineOn: (cx, x, y, w, h) ->
    cx.translate x, y
    @pathOutlineOn cx, w, h

    {pw, px, r} = CommandBlock::params()
    for t in @subviews when t.isScriptArg
      cx.translate 0, -.5
      cx.moveTo t.x - .5, t.y + t.h - r
      cx.lineTo t.x - .5, t.y + r + .5
      cx.lineTo t.x + r, t.y
      cx.lineTo t.x + px - r, t.y
      cx.lineTo t.x + px, t.y + r
      cx.lineTo t.x + px + pw, t.y + r
      cx.lineTo t.x + px + pw + r, t.y
      cx.lineTo w - r, t.y
      cx.lineTo w, t.y - r
      cx.translate 0, .5
    cx.translate -x, -y

  hitTest: (x, y) -> 0 <= x < @w and 0 <= y < @h

  objectAt: (x, y) ->
    return o for a in @args when o = a.objectAt x-a.x, y-a.y
    return @ if @hitTest x, y

  detach: ->
    if not @parent
      new Script [@]
    else if @parent.isBlock
      @parent.resetArg @
    else if @parent.isScript
      @parent.splitFrom @

  enumerateScripts: (fn, x, y) ->
    x += @x
    y += @y
    for t in @subviews when t.isScriptArg
      t.enumerateScripts fn, x, y

module.exports = {Block}
{CommandBlock} = require "./command-block"
{Label} = require "./label"
{Arg} = require "./arg"
{Script} = require "./script"
