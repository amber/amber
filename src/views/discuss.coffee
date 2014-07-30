{View, $} = require "space-pen"
{T} = require "am/util"

class Discuss extends View
  @content: ->
    @article click: "navigate", =>
      @h1 T("Discuss Amber")
      @section class: "discuss-bar", =>
        @div class: "input-wrapper", =>
          @input outlet: "filter", placeholder: T("Filter…")
        @a T("New Topic"), class: "button", href: "/discuss/new"
      tags = "announcement,suggestion,bug,request,question,help,extension".split ","
      for i in [1..50]
        @section class: "topic #{if i < 6 then "unread" else ""}", =>
          @button class: "star", click: "star", title: T("Star")
          @button class: "read", click: "read", title: T("Mark as read")
          @div class: "title", =>
            @img src: "http://lorempixel.com/100/100/abstract/#{i % 7}"
            @a "The name of topic ##{i}", href: "/topic/#{i}", class: "name"
            has = {}
            for x in [1..10] when (t = tags[Math.random() * 100 | 0]) and not has[t]
              @a class: "tag tag-#{t}", "data-tag": t, href: "/discuss/label:#{t}", T(t)
              has[t] = yes
          @div class: "subtitle", =>
            name = "nathan"
            url = "/#{name}"
            time = "10 minutes ago"
            @raw T("<a href=\"{url}\">{name}</a> created {time}", {url, name, time})

  title: -> T("Discuss")

  afterAttach: ->
    @filter.focus()

  navigate: (e) ->
    return if e.metaKey or e.shiftKey or e.altKey or e.ctrlKey
    if t = $(e.target).closest(".tag")[0]
      e.preventDefault()
      e.stopPropagation()
      @addToken "label:#{t.dataset.tag}"

  addToken: (token) ->
    tokens = @filter.val().trim().split /\s+/
    return unless -1 is tokens.indexOf token
    t = @filter.val()
    @filter.val t + (if /\S$/.test t then " " else "") + token

  star: (e, el) ->
    el.closest(".topic").toggleClass "starred"

  read: (e, el) ->
    el.closest(".topic").removeClass "unread"

module.exports = {Discuss}
