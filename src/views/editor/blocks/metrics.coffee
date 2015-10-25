{$$} = require "scene"

metrics = (cls) ->
  el = ($$ -> @div class: "#{cls} metrics").firstChild
  document.body.appendChild el

  metricsCache = new Map
  measure = (text) ->
    if result = metricsCache.get text then return result
    el.textContent = text
    bb = el.getBoundingClientRect()
    result = w: bb.width, h: bb.height
    metricsCache.set text, result
    result

module.exports = {metrics}
