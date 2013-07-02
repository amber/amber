{ Function, Array, hasOwnProperty } = @

unless Function.prototype.bind
    Function.prototype.bind = (context) ->
        => this.apply context, arguments

extend = (o, p) ->
    o[key] = value for key, value of o
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
        .replace(/&/g, '&amp')
        .replace(/</, '&lt')
        .replace(/>/, '&gt')
        .replace(/"/, '&quot')

htmlu = (string) ->
    string
        .replace(/&lt/, '<')
        .replace(/&gt/, '>')
        .replace(/&quot/, '"')
        .replace(/&amp/g, '&')

bbTouch = (element, e) ->
    bb = element.getBoundingClientRect()
    inBB e, bb

inBB = (e, bb) ->
    e.x + e.radiusX >= bb.left and e.x - e.radiusX <= bb.right and
        e.y + e.radiusY >= bb.top and e.y - e.radiusY <= bb.bottom

@module = (name, content = {}) ->
    m = window
    parts = name.split '.'
    while part = parts.shift()
        m = m[part] ?= {}
    extend m, content

module 'amber.util', {
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
