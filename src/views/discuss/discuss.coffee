{View} = require "scene"
{T, format, escape, scrollIntoViewVBody} = require "am/util"
{TopicItem} = require "am/views/discuss/topic-item"
data = require "am/data"

CHUNK_SIZE = 20
TAG_RE = /^\s*\[([^\]]+)\]\s*$/

class Discuss extends View
  @content: ({app, filter}) ->
    @article class: "discuss", click: "navigate", =>
      @h1 T("Discuss Amber")
      @section class: "tag-bar", =>
        for t in data.staticTags
          if t is "open_issues"
            @a class: "tag tag-open_issues", dataFilter: data.filter.openIssues, href: "/discuss/issues", "open issues"
          else
            @a class: "tag tag-#{t}", dataFilter: "[#{t}] ", href: "/discuss/t/#{t}", t
      @section class: "discuss-bar#{if app.server.user then " signed-in" else ""}", =>
        @div class: "input-wrapper", =>
          @input outlet: "filter", input: "refilter", keydown: "onFilterKey", type: "search", placeholder: T("Filter…"), value: filter ? ""
        if app.server.user
          @a T("New topic"), class: "button accent", href: "/discuss/new"
      @div outlet: "content"

  enter: ->
    addEventListener "scroll", @update
    @update()
    document.addEventListener "keydown", @keyDown

    @filter.selectionStart = @filter.selectionEnd = @filter.value.length
    @filter.focus()

  exit: ->
    removeEventListener "scroll", @update
    document.removeEventListener "keydown", @keyDown

  initialize: ({@app}) ->
    @topics = []
    @selectedIndex = -1

  reset: ->
    @loading = no
    @done = no
    @offset = 0
    @selectedIndex = -1
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
      if @offset is topics.length and not @done and document.activeElement is document.body
        @select 0

  keyDown: (e) =>
    unfocused = document.activeElement is document.body
    if e.keyCode is 40 or unfocused and e.keyCode is 74
      @select Math.min @topics.length - 1, @selectedIndex + 1
      e.preventDefault()
    if e.keyCode is 38 or unfocused and e.keyCode is 75
      @select Math.max 0, @selectedIndex - 1
      e.preventDefault()
    if unfocused
      if e.keyCode is 70
        @filter.focus()
        e.preventDefault()
      if e.keyCode in [13, 79] and t = @topics[@selectedIndex]
        t.navigate()

  select: (i) ->
    @filter.blur()
    @topics[@selectedIndex]?.setSelected no
    if t = @topics[@selectedIndex = i]
      t.setSelected yes
      scrollIntoViewVBody t.base, 50

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
        if t.dataset.filter
          @setFilter t.dataset.filter
        else
          @addToken "[#{t.dataset.tag}]"
        return
      t = t.parentNode

  setFilter: (t) ->
    @filter.value = t
    @updateURL()
    scrollTo 0, 0
    @filter.focus()

  addToken: (token) ->
    tokens = @filter.value.trim().split /\s+/
    return unless -1 is tokens.indexOf token
    t = @filter.value
    @setFilter t + (if /\S$/.test t then " " else "") + token + " "

  refilter: ->
    clearInterval @interval
    @interval = setTimeout @updateURL, 1000

  updateURL: =>
    filter = @filter.value
    url = if x = TAG_RE.exec filter
      "/discuss/t/#{encodeURIComponent x[1]}"
    else if filter is data.filter.openIssues
      "/discuss/issues"
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
      if e.shiftKey
        @filter.blur()

module.exports = {Discuss}
