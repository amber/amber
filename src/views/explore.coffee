{View, $} = require "space-pen"
{T} = require "am/util"

class Explore extends View
  @content: ->
    @article =>
      @h1 T("Explore projects")
      for i in [1..100]
        @a href: "/project/#{i}", class: "project-icon", =>
          @img src: "http://lorempixel.com/160/120/abstract/#{i % 7}"
          @div class: "label", "Project ##{i}"

  title: -> T("Explore projects")

module.exports = {Explore}
