{Arg} = require "./arg"

class ScriptArg extends Arg
  @type "t"
  isScriptArg: true
  wrapBefore: true
  wrapAfter: true

  @content: ->
    @div class: "abs", =>
      @subview "script", new Script

  layout: ->
    @setSize 0, Math.max 16, @script.h

  enumerateScripts: (fn, x, y) ->
    x += @x
    y += @y
    @script.enumerateScripts fn, x, y

  enumerateArgs: (fn, x, y) ->
    x += @x; y += @y
    fn this, x, y
    @script.enumerateArgs fn, x, y

  objectAt: (x, y) -> @script.objectAt x, y

{Script} = require "./script"
module.exports = {ScriptArg, Script}
