{View} = require "scene"
{T, format, escape} = require "am/util"
{TopicItem} = require "am/views/topic-item"

class Discuss extends View
  @content: ({filter}) ->
    @article click: "navigate", =>
      @h1 T("Discuss Amber")
      @section class: "discuss-bar", =>
        @div class: "input-wrapper", =>
          @input outlet: "filter", input: "refilter", keydown: "onFilterKey", placeholder: T("Filter…"), value: filter ? ""
        @a T("New topic"), class: "button accent", href: "/discuss/new"

  initialize: ->
    tags = "announcement,suggestion,bug,request,question,help,extension".split ","
    users = "nathan MathWizz someone user userwithalongername person with_underscores".split " "
    for i in [1..50]
      has = {}
      for x in [1..3] when t = tags[(i + x * 35) % (11 * x)]
        has[t] = yes
      @add new TopicItem
        id: i
        title: "The name of topic ##{i}"
        unread: i < 6
        starred: i % 8 is 1
        views: i * 5713 % 900
        posts: i * 5713 % 20
        tags: Object.keys has
        author: users[i % 7]
        created: "#{i * 32471 % 50 + 5} minutes ago"

  title: -> T("Discuss")

  afterAttach: ->
    f = @filter[0]
    f.selectionStart = f.selectionEnd = f.value.length
    @filter.focus()

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
    @updateURLue
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
