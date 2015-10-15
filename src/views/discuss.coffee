{View} = require "scene"
{T, format, escape} = require "am/util"
{TopicItem} = require "am/views/topic-item"

CHUNK_SIZE = 20
TAG_RE = /^\s*\[([^\]]+)\]\s*$/

class Discuss extends View
  @content: ({app, filter}) ->
    @article class: "discuss", click: "navigate", =>
      @h1 T("Discuss Amber")
      @section class: "discuss-bar#{if app.server.user then " signed-in" else ""}", =>
        @div class: "input-wrapper", =>
          @input outlet: "filter", input: "refilter", keydown: "onFilterKey", type: "search", placeholder: T("Filter…"), value: filter ? ""
        if app.server.user
          @a T("New topic"), class: "button accent", href: "/discuss/new"
      @div outlet: "content"

  enter: ->
    addEventListener "scroll", @update
    @update()

    @filter.selectionStart = @filter.selectionEnd = @filter.value.length
    @filter.focus()

  exit: -> removeEventListener "scroll", @update

  initialize: ({@app}) ->
    @topics = []

  reset: ->
    @loading = no
    @done = no
    @offset = 0
    for t in @topics then t.remove()
    @topics = []
    @update()

  offset: 0
  update: =>
    return if @loading or @done
    return unless scrollY > document.body.offsetHeight - 2000
    @loading = yes
    @app.server.searchTopics {query: @filter.value, @offset, length: CHUNK_SIZE}, (err, topics) =>
      @loading = no
      return if err # TODO
      @offset += topics.length
      @done = yes if topics.length < CHUNK_SIZE
      for t in topics
        @topics.push topic = new TopicItem {d: t, @app}
        @add topic, @content

  title: ->
    filter = @filter.value
    if filter
      T("Discuss “{filter}”", {filter})
    else T("Discuss")

  navigate: (e) ->
    return if e.metaKey or e.shiftKey or e.altKey or e.ctrlKey
    t = e.target
    while t?.nodeType is 1
      if t.classList.contains "tag"
        e.preventDefault()
        e.stopPropagation()
        @addToken "[#{t.dataset.tag}]"
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
    @interval = setTimeout @updateURL, 1000

  updateURL: =>
    filter = @filter.value
    url = if x = TAG_RE.exec filter
      "/discuss/t/#{encodeURIComponent x[1]}"
    else if filter
      "/discuss/s/#{encodeURIComponent filter}"
    else
      "/discuss"
    if url isnt location.pathname
      @parent.router.goSilent url
    @app.setTitle @title()
    @reset()

  onFilterKey: (e) ->
    if e.keyCode is 13
      e.preventDefault()
      clearInterval @interval
      @updateURL()

module.exports = {Discuss}
