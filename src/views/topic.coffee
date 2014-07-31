{View, $$} = require "scene"
{T} = require "am/util"
{NotFound} = require "am/views/not-found"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 outlet: "title"

  initialize: ({@id, @app}) ->
    @app.server.getTopic {@id}, (err, d) =>
      if err
        @app.setView new NotFound {url: location.pathname}
        return
      @title.textContent = d.title
      @base.appendChild $$ ->
        for {author, created, body} in d.posts
          @section class: "post", =>
            @img src: "http://lorempixel.com/100/100/abstract/1"
            @div class: "author", =>
              url = "/user/#{author}"
              @html T("<a href=\"{url}\">{author}</a> posted {created}", {url, author, created})
            @p body

  title: -> "The name of topic ##{@id}"

module.exports = {Topic}
