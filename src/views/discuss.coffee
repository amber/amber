{View, $} = require "space-pen"
{T} = require "am/util"

class Discuss extends View
  @content: ->
    @article =>
      @h1 T("Discuss Amber")
      for i in [1..50]
        @section class: "topic", =>
          @a "The name of topic ##{i}", class: "name", href: "/topic/#{i}"
          @div class: "subtitle", =>
            name = "nathan"
            url = "/#{name}"
            time = "10 minutes ago"
            @raw T("<a href=\"{url}\">{name}</a> created {time}", {url, name, time})

module.exports = {Discuss}
