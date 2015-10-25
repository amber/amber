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
    @cv.style.transform = "translate(#{-out.left}px,#{-out.right}px)"

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

  layout: ->
    pad = @padding()
    sp = @spacing()

    x = pad.left
    h = 0
    for view, i in @subviews
      x += sp.x if i
      view.moveTo x, pad.top
      x += view.w
      h = Math.max h, view.h

    @setSize x + pad.right, pad.top + h + pad.bottom

  sizeChanged: (w, h) ->
    out = @outset()
    pr = devicePixelRatio ? 1
    fw = w + out.left + out.right
    fh = h + out.top + out.bottom

    @cv.width = fw * pr
    @cv.height = fh * pr
    @cv.style.width = "#{fw}px"
    @cv.style.height = "#{fh}px"

    @cx.scale pr, pr
    @draw()

  outset: -> left: 0, right: 0, top: 0, bottom: 0
  padding: -> left: 3, right: 3, top: 3, bottom: 3
  spacing: -> x: 4, y: 4

  draw: ->
    out = @outset()

    @cx.fillStyle = @color
    @cx.beginPath()
    @pathOn @cx, out.left, out.top, @w, @h
    @cx.fill()

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

module.exports = {Block}
{Label} = require "./label"
{Arg} = require "./arg"
{Script} = require "./script"
