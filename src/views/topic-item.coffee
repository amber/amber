{View, $, $$} = require "space-pen"
{T, extend} = require "am/util"

class TopicItem extends View
  @content: ->
    @section class: "topic", =>
      @div class: "stat", =>
        @span outlet: "views"
        @strong T("views")
      @div class: "stat", =>
        @span outlet: "posts"
        @strong T("posts")
      @button class: "star", click: "star", title: T("Star")
      @button class: "read", click: "read", title: T("Mark as read")
      @div class: "title", =>
        @img outlet: "avatar"
        @a outlet: "title", class: "name"
        @span outlet: "tags"
      @div class: "subtitle", outlet: "subtitle"

  initialize: (@d) -> @apply()
  update: (map) ->
    extend @d, map
    @d[k] = v for k, v of map

  apply: ->
    {id, title, unread, starred, author, created, tags, views, posts} = @d

    @title.attr "href", "/topic/#{id}"
    @title.text title
    @avatar.attr "src", "http://lorempixel.com/100/100/abstract/#{id % 7}"
    @toggleClass "unread", unread
    @toggleClass "starred", starred
    @subtitle.html T("<a href=\"{url}\">{author}</a> created {created}", {url: "/user/#{author}", author, created})
    @views.text views
    @posts.text posts

    @tags.append $$ ->
      for t in tags
        @a class: "tag tag-#{t}", "data-tag": t, href: "/discuss/#{encodeURIComponent "label:#{t}"}", T(t)

  star: (e, el) ->
    el.closest(".topic").toggleClass "starred"

  read: (e, el) ->
    el.closest(".topic").removeClass "unread"

module.exports = {TopicItem}
