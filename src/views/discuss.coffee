{View} = require "scene"
{T, format, escape} = require "am/util"
{TopicItem} = require "am/views/topic-item"

CHUNK_SIZE = 20

class Discuss extends View
  @content: ({app, filter}) ->
    @article click: "navigate", =>
      @h1 T("Discuss Amber")
      @section class: "discuss-bar", =>
        @div class: "input-wrapper", =>
          @input outlet: "filter", input: "refilter", keydown: "onFilterKey", placeholder: T("Filter…"), value: filter ? ""
        @a T("New topic"), class: "button accent", href: "/discuss/new"

  enter: ->
    addEventListener "scroll", @update
    @update()

    @filter.selectionStart = @filter.selectionEnd = @filter.value.length
    @filter.focus()

  exit: -> removeEventListener "scroll", @update

  initialize: ({@app}) ->

  offset: 0
  update: =>
    return if @loading or @done
    return unless scrollY > document.body.offsetHeight - 2000
    @loading = yes
    @app.server.getTopics {@offset, length: CHUNK_SIZE}, (err, topics) =>
      @loading = no
      return if err # TODO
      @offset += topics.length
      @done = yes if topics.length < CHUNK_SIZE
      for t in topics
        @add new TopicItem t

  title: -> T("Discuss")

  navigate: (e) ->
    return if e.metaKey or e.shiftKey or e.altKey or e.ctrlKey
    t = e.target
    while t?.nodeType is 1
      if t.classList.contains "tag"
        e.preventDefault()
        e.stopPropagation()
        @addToken "label:#{t.dataset.tag}"
        return
      t = t.parentNode

  addToken: (token) ->
    tokens = @filter.value.trim().split /\s+/
    return unless -1 is tokens.indexOf token
    t = @filter.value
    @filter.value = t + (if /\S$/.test t then " " else "") + token + " "
    @updateURL()
    scrollTo 0, 0
    @filter.focus()

  refilter: ->
    clearInterval @interval
    @interval = setTimeout @updateURL, 700

  updateURL: =>
    @parent.router.go "/discuss/#{encodeURIComponent @filter.value}"

  onFilterKey: (e) ->
    if e.keyCode is 13
      e.preventDefault()
      clearInterval @interval
      @updateURL()

module.exports = {Discuss}
