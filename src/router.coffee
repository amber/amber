{urls} = require "am/urls"
{NotFound} = require "am/views/not-found"
{InternalError} = require "am/views/internal-error"

class Router
  constructor: (@app) ->
    app.router = @
    @domain = "#{location.protocol}//#{location.host}"
    @route()
    addEventListener "popstate", @route
    document.addEventListener "click", @navigate

  navigate: (e) =>
    return if e.metaKey or e.shiftKey or e.ctrlKey or e.altKey
    t = e.target
    while t
      if t.tagName is "A"
        if @domain is t.href.slice 0, @domain.length
          e.preventDefault()
          @go t.href
        return
      t = t.parentNode

  go: (url) ->
    if "/" is url.slice -1
      url = url.slice 0, -1
    scrollTo 0, 0
    history.pushState null, null, url
    @route()

  route: =>
    target = location.pathname
    targetSegments = target.split "/"
    for pattern, View of urls
      segments = pattern.split "/"
      continue if segments.length isnt targetSegments.length
      match = yes
      slugs = {}
      for segment, i in segments
        ts = decodeURIComponent targetSegments[i]
        if ":" is segment.charAt 0
          slugs[segment.slice 1] = ts
        else
          if ts isnt segment
            match = no
            break
      if match
        try
          view = new View slugs
        catch e
          @app.setView new InternalError
            name: e.constructor.name
            message: e.message
            stack: e.stack
          setTimeout -> throw e
          return
        @app.setView view
        return
    @app.setView new NotFound {url: target}

module.exports = {Router}
