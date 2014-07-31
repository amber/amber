{View, $$} = require "scene"
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
    @apply()

  apply: ->
    {id, title, unread, starred, author, created, tags, views, posts} = @d

    @title.setAttribute "href", "/topic/#{id}"
    @title.textContent = title
    @avatar.setAttribute "src", "http://lorempixel.com/100/100/abstract/#{id % 7}"
    @base.classList.toggle "unread", unread
    @base.classList.toggle "starred", starred
    @subtitle.innerHTML = T("<a href=\"{url}\">{author}</a> created {created}", {url: "/user/#{author}", author, created})
    @views.textContent = views
    @posts.textContent = posts

    @tags.removeChild @tags.lastChild while @tags.firstChild
    @tags.appendChild $$ ->
      for t in tags
        @a class: "tag tag-#{t}", "data-tag": t, href: "/discuss/#{encodeURIComponent "label:#{t}"}", T(t)

  star: -> @base.classList.toggle "starred"
  read: -> @base.classList.remove "unread"

module.exports = {TopicItem}
