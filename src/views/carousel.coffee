{View, $} = require "space-pen"

class Carousel extends View
  @content: ->
    @section class: "carousel", =>
      for i in [1..10]
        @a href: "/projects/#{i}", =>
          @img src: """data:image/svg+xml,<svg xmlns=&quot;http://www.w3.org/2000/svg&quot;/>"""
          @div class: "label", "Project ##{i}"

module.exports = {Carousel}
