snake = (s) -> s.replace /[A-Z]/g, (x) -> "_#{x.toLowerCase()}"

class Builder
  events = "blur change click dblclick error focus input keydown keypress keyup load mousedown mousemove mouseout mouseover mouseup resize scroll select submit unload".split " "
  tags = "a abbr address area article aside audio b base bdi bdo blockquote br button canvas caption cite code col colgroup command datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hr i iframe img input ins kbd keygen label legend li link main map mark menu meta meter nav noscript object ol optgroup option output p param pre progress q rp rt ruby s samp script section select small source span strong style sub summary sup table tbody td textarea tfoot th thead time title tr track u ul var video wbr".split " "

  constructor: ->
    @context = []
    @base = null

  tag: (name, contents...) ->
    el = document.createElement name
    for item in contents
      switch typeof item
        when "function"
          @context.push el
          item()
          @context.pop()
        when "object"
          @key el, k, v for k, v of item
        else
          el.appendChild document.createTextNode ""+item
    @add el

  text: (string) ->
    @add document.createTextNode string

  html: (html) ->
    el = document.createElement "div"
    el.innerHTML = html
    while child = el.firstChild
      @add child

  add: (el) ->
    if @context.length
      @context[@context.length - 1].appendChild el
    else
      @base = el

  key: (el, k, v) ->
    if -1 is events.indexOf k
      el.setAttribute snake(k), v
    else
      @event el, k, v

  event: (el, k, v) ->
    el.addEventListener k, v ? ->

  for name in tags
    do (name) =>
      @::[name] = (contents...) -> @tag name, contents...

$$ = (f) ->
  b = new Builder
  f.call b
  b.base

class ViewBuilder extends Builder
  constructor: (@view) -> super

  key: (el, k, v) ->
    if k is "outlet"
      @view[v] = el
    else super

  event: (el, k, v) ->
    v = @view[v] if typeof v is "string"
    super el, k, v?.bind @view

  subview: (sv) ->
    @view.subviews.push sv
    sv.parent = @view
    @add sv.base

class View
  constructor: (args...) ->
    @subviews = []
    b = new ViewBuilder @
    @content.call b, args...
    @base = b.base
    @initialize? args...

  inDocument: no

  add: (sv, mount = @base, before = null) ->
    sv.removeFromParent()
    if before
      mount.insertBefore sv.base, before
    else
      mount.appendChild sv.base
    @subviews.push sv
    sv.parent = @
    sv.tryDocument()
    @

  replace: (ex, sv) ->
    sv.removeFromParent()
    @subviews.push sv
    sv.parent = @
    ex.tryExit()
    ex.base.parentNode.replaceChild sv.base, ex.base
    ex.removeFromParent()
    sv.tryDocument()

  embed: (mount) ->
    mount.appendChild @base
    @tryDocument()
    @

  remove: ->
    @tryExit()
    @removeFromParent()
    if node = @base.parentNode
      node.removeChild @base
    @

  removeFromParent: ->
    return unless @parent
    views = @parent.subviews
    i = views.indexOf @
    views.splice i, 1 if i isnt -1
    @parent = null

  tryDocument: ->
    p = @base
    while p
      if p.tagName is "BODY"
        @tryEnter()
        return
      p = p.parentNode
    @tryExit()

  tryEnter: ->
    return if @inDocument
    @inDocument = yes
    @enter?()
    sv.tryEnter() for sv in @subviews

  tryExit: ->
    return unless @inDocument
    @exit?()
    @inDocument = no
    sv.tryExit() for sv in @subviews

module.exports = {$$, View, Builder}
