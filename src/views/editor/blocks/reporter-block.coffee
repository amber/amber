{Block} = require "./block"

class ReporterBlock extends Block
  isReporter: true
  @type "r"

  padding: -> left: 7, right: 7, top: 3, bottom: 3
  params: -> r: 12

  pathOn: (cx, w, h) ->
    r = Math.min @params().r, w/2, h/2
    cx.arc r, r, r, Math.PI, Math.PI*3/2
    cx.arc w-r, r, r, Math.PI*3/2, 0
    cx.arc w-r, h-r, r, 0, Math.PI/2
    cx.arc r, h-r, r, Math.PI/2, Math.PI
    cx.closePath()

  pathOutlineOn: (cx, w, h) ->
    cx.translate 0, -.5
    r = Math.min @params().r, w/2, h/2
    cx.arc w-r, h-r, r, Math.PI/4, Math.PI/2
    cx.arc r, h-r, r, Math.PI/2, Math.PI*3/4
    cx.translate 0, .5

  enumerateArgs: (fn, x, y) ->
    x += @x; y += @y
    fn @, x, y
    a.enumerateArgs fn, x, y for a in @args

module.exports = {ReporterBlock}
