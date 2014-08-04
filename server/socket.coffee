events = []
methods = []

exports.listen = (socket) ->
  for {name, fn} in events
    socket.on name, fn.bind socket
  for {name, fn} in methods
    socket[name] = fn

checkList = (types, list) ->
  return no unless types.length is list.length
  for t, i in types
    return no unless check t, list[i]
  return yes

check = (type, v) ->
  switch type
    when Function then return typeof v is "function"
    when String then return typeof v is "string"
    when Number then return typeof v is "number"
  if Array.isArray type
    return no unless Array.isArray v
    for i in v
      return no unless check type[0], i
    return yes
  if typeof type is "object"
    return no unless typeof v is "object"
    for name, t of type
      return no unless check t, v[name]
    return yes
  throw new Error "Invalid type"

exports.on = (name, types..., fn) ->
  events.push {
    name
    fn: (args...) ->
      unless checkList types, args
        return console.log "ignoring #{JSON.stringify name}", args...
      fn.apply @, args
  }

exports.method = (name, fn) ->
  methods.push {name, fn}
