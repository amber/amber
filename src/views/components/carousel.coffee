{View} = require "scene"

class Carousel extends View
  @content: ->
    @section class: "carousel", =>
      for i in [1..10]
        @a href: "/project/#{i}", =>
          @img src: "http://lorempixel.com/160/120/abstract/#{i % 7}"
          @div class: "label", "Project ##{i}"

module.exports = {Carousel}
