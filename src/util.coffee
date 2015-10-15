{slugify} = require "am/util-shared"

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

humanNumber = (n) ->
  return n if n < 1000
  n /= 1000
  return "#{Math.floor n}k" if n < 1000
  n /= 1000
  "#{Math.floor n}M"

extend = (base, map) ->
  base[k] = v for k, v of map
  base

emitter = (o) ->
  o.on = (event, fn) ->
    ((@listeners ?= Object.create null)[event] ?= []).push fn
  o.unlisten = (event, fn) ->
    return unless list = @listeners?[event]
    i = list.indexOf fn
    list.splice i, 1 if i isnt -1
  o.emit = (event, args...) ->
    return unless list = @listeners?[event]
    fn args... for fn in list

module.exports = {format, escape, emitter, T, relativeDate, humanNumber, slugify}
