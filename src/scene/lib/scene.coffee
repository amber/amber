class Builder
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
          for k, v of item
            el.setAttribute k, v
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

  for name in "a abbr address area article aside audio b base bdi bdo blockquote br button canvas caption cite code col colgroup command datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hr i iframe img input ins kbd keygen label legend li link main map mark menu meta meter nav noscript object ol optgroup option output p param pre progress q rp rt ruby s samp script section select small source span strong style sub summary sup table tbody td textarea tfoot th thead time title tr track u ul var video wbr".split " "
    do (name) =>
      @::[name] = (contents...) -> @tag name, contents...

$$ = (f) ->
  b = new Builder
  f.call b
  b.base

class View

module.exports = {$$, View, Builder}
