socket = require "./socket"

events = Object.create null
watchers = Object.create null

objEvent = (name) ->
  watchers[name] = Object.create null
  events[name] = yes

watch = (s, name, id = null) ->
  unwatch s
  set = if events[name]
    watchers[name][id] ?= []
  else
    watchers[name] ?= []
  s.watchName = name
  s.watchId = id
  set.push s

unwatch = (s) ->
  if name = s.watchName
    if list = (if events[name] then watchers[name][s.watchId] else watchers[name])
      i = list.indexOf s
      list.splice i, 1 unless i is -1
    s.watchName = s.watchId = null

objEvent "topic"

exports.emit = (name, id, d) ->
  if list = (if events[name] then watchers[name][id] else watchers[name])
    for s in list
      s.emit "update", d

socket.on "disconnect", -> unwatch @
socket.on "unwatch", -> unwatch @

socket.on "watch", {name: String}, Function, ({name, id}, cb) ->
  watch @, name, id
