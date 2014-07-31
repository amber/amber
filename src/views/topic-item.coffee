{View, $$} = require "scene"
{T, extend} = require "am/util"
{RelativeDate} = require "am/views/relative-date"

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
      @div class: "subtitle", =>
        @a outlet: "author"
        @text " created "
        @subview "created", new RelativeDate

  initialize: (@d) -> @apply()
  update: (map) ->
    extend @d, map
    @d[k] = v for k, v of map
    @apply()

  apply: ->
    {id, title, unread, starred, author, created, tags, views, posts} = @d

    @title.href = "/topic/#{id}"
    @title.textContent = title
    @avatar.src = "http://lorempixel.com/100/100/abstract/1"
    @base.classList.toggle "unread", unread
    @base.classList.toggle "starred", starred
    @author.href = "/user/#{author}"
    @author.textContent = author
    @created.setDate created
    @views.textContent = views
    @posts.textContent = posts

    @tags.removeChild @tags.lastChild while @tags.firstChild
    @tags.appendChild $$ ->
      for t in tags
        @a class: "tag tag-#{t}", dataTag: t, href: "/discuss/#{encodeURIComponent "label:#{t}"}", T(t)

  star: ->
    @base.classList.toggle "starred"
    @parent.parent.server.starTopic {
      id: @d.id
      starred: @base.classList.contains "starred"
    }

  read: -> @base.classList.remove "unread"

module.exports = {TopicItem}
