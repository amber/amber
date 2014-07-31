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

relativeDate = (date) ->
  now = new Date
  delta = (now - date) / 1000 / 60
  return T("a minute ago") if delta <= 1
  return T("{n} minutes ago", {n: Math.ceil delta / 60}) if delta <= 59
  delta /= 60
  return T("an hour ago") if delta <= 1
  return T("{n} hours ago", {n: Math.ceil delta / 60 / 60}) if delta <= 23
  "#{date.getDay()} #{MONTH_NAMES[date.getMonth()]} #{if now.getFullYear() is date.getFullYear() then "" else date.getFullYear()}"

extend = (base, map) ->
  base[k] = v for k, v of map
  base

module.exports = {format, escape, T, relativeDate}
