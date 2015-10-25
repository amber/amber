{Base} = require "./base"

registry = new Map

class Arg extends Base
  isArg: yes

  @for: (type, menu, value) ->
    Cons = registry.get type
    new Cons type, menu, value

  @type: (type) -> registry.set type, this
  @types: (types...) -> @type t for t in types

  @content: ->
    @div class: "abs"

  objectAt: (x, y) ->
    @ if @hitTest x, y

module.exports = {Arg}
