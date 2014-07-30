{urls} = require "am/urls"
{NotFound} = require "am/views/not-found"

class Router
  constructor: (@app) ->
    app.router = @
    @domain = "#{location.protocol}//#{location.host}"
    @route()
    addEventListener "popstate", @route
    document.addEventListener "click", @navigate

  navigate: (e) =>
    t = e.target
    while t
      if t.tagName is "A"
        if @domain is t.href.slice 0, @domain.length
          scrollTo 0, 0
          history.pushState null, null, t.href
          e.preventDefault()
          @route()
        return
      t = t.parentNode

  route: =>
    target = location.pathname
    targetSegments = target.split "/"
    for pattern, View of urls
      segments = pattern.split "/"
      continue if segments.length isnt targetSegments.length
      match = yes
      slugs = {}
      for segment, i in segments
        if ":" is segment.charAt 0
          slugs[segment.slice 1] = targetSegments[i]
        else
          if targetSegments[i] isnt segment
            match = no
            break
      if match
        @app.setView new View slugs
        return
    @app.setView new NotFound {url: target}

module.exports = {Router}
