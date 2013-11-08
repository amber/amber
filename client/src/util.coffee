{ Function, hasOwnProperty } = @

unless Function.prototype.bind
    Function.prototype.bind = (context) ->
        => @apply context, arguments

extend = (o, p) ->
    o[key] = value for key, value of p
    o

addClass = (element, name) ->
    if -1 is (' ' + element.name + ' ').indexOf ' ' + name + ' '
        element.className += (if element.className then ' ' else '') + name

removeClass = (element, name) ->
    i = (' ' + element.className + ' ').indexOf ' ' + name + ' '
    element.className = (element.className.substr 0, i - 1) + (element.className.substr i + name.length) if -1 isnt i

toggleClass = (element, name, active = (not hasClass element, name)) ->
    if active
        addClass element, name
    else
        removeClass element, name

hasClass = (element, name) ->
    -1 isnt (' ' + element.className + ' ').indexOf ' ' + name + ' '

format = (format) ->
    args = arguments
    i = 1

    format.replace /%([1-9]\d*)?/g, ({}, n) -> if n then args[n] else args[i++]

htmle = (string) ->
    string
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')

htmlu = (string) ->
    string
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&amp;/g, '&')

bbTouch = (element, e) ->
    bb = element.getBoundingClientRect()
    inBB e, bb

inBB = (e, bb) ->
    e.x + e.radiusX >= bb.left and e.x - e.radiusX <= bb.right and
        e.y + e.radiusY >= bb.top and e.y - e.radiusY <= bb.bottom

class Base
    @property: (name, options = {}) ->
        if typeof options is 'function'
            options =
                readonly: true
                get: options

        setName = 'set' + name[0].toUpperCase() + name.substr 1
        _name = '_' + name

        @event event if event = options.event
        setter = options.set ? (value) -> @[_name] = value
        getter = options.get ? -> @[_name]
        apply = options.apply

        @::[_name] = options.value ? null

        Object.defineProperty @::, name,
            set: if options.readonly then undefined else (value) ->
                old = @[_name]
                setter.call @, value
                apply.call @, value, old if apply and old isnt value
                @dispatch event, new amber.event.PropertyEvent().setObject @ if event
            get: getter
            readonly: options.readonly

        @::[setName] = (value) ->
            @[name] = value
            @

    @event: (name) ->
        low = name[0].toLowerCase() + name.substr 1
        @::['on' + name] = (listener, context) -> @listen name, listener, context
        @::['un' + name] = (listener) -> @unlisten name, listener
        @::[low + 'Listeners'] = -> @listeners name

    listen: (name, handler, context = @) ->
        (@['$listeners_' + name] ?= []).push
            listener: handler
            context: context
        @

    unlisten: (name, handler) ->
        if a = @['$listeners_' + name]
            for o, i in a
                if o.listener is handler
                    a.splice i, 1
                    break
        @

    listeners: (name) ->
        @['$listeners_' + name] ? []

    clearListeners: (name) ->
        delete @['$listeners_' + name]
        @

    dispatch: (name, event) ->
        a = @[key = '$listeners_' + name]
        if a
            for o in a
                o.listener.call o.context, event
        @

    set: (properties) ->
        @[key] = value for key, value of properties
        @

@module = (name, content = {}) ->
    m = window
    parts = name.split '.'
    while part = parts.shift()
        m = m[part] ?= {}
    extend m, content

module 'amber.util', {
    Base
    extend
    addClass
    removeClass
    toggleClass
    hasClass
    format
    htmle
    htmlu
    bbTouch
    inBB
}
