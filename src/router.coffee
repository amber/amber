{urls} = require "am/urls"
{NotFound} = require "am/views/not-found"

class Router
  constructor: (@app) -> @route()

  route: ->
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
        @app.setView new View
        return
    @app.setView new NotFound {url: target}

module.exports = {Router}
