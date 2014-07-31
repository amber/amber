format = (s, v) -> s.replace /\{(\w+)\}/g, (_, name) -> v[name]

escape = (s) -> s.replace /[<>'"&]/, (c) -> switch c
  when "<" then "&lt;"
  when ">" then "&gt;"
  when "'" then "&apos;"
  when "\"" then "&quot;"
  when "&" then "&amp;"

T = (args...) ->
  if DEBUG_TRANSLATIONS?
    "!" + format args...
  else
    format args...

extend = (base, map) ->
  base[k] = v for k, v of map
  base

module.exports = {format, escape, T}
