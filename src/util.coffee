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

MONTH_NAMES = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec".split " "

relativeDate = (date) ->
  now = new Date
  delta = (now - date) / 1000 / 60
  return T("now") if delta < 1
  return T("a minute ago") if delta < 2
  return T("{n} minutes ago", {n: Math.floor delta}) if delta < 60
  delta /= 60
  return T("an hour ago") if delta < 2
  return T("{n} hours ago", {n: Math.floor delta}) if delta < 24
  delta /= 24
  return T("a day ago") if delta < 2
  return T("{n} days ago", {n: Math.floor delta}) if delta < 31
  "#{MONTH_NAMES[date.getMonth()]} #{date.getDate()} #{if now.getFullYear() is date.getFullYear() then "" else date.getFullYear()}"

extend = (base, map) ->
  base[k] = v for k, v of map
  base

module.exports = {format, escape, T, relativeDate}
