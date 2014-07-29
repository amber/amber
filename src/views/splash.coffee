{View, $} = require "space-pen"
{Carousel} = require "am/views/carousel"

class Splash extends View
  @content: ->
    @article =>
      @div class: "splash", =>
        @div class: "left", =>
          @h1 "Realtime collaborative programming."
          @p "Create interactive stories, games, music, and art with others around the world."
      @h1 "Featured projects"
      @subview "featured", new Carousel

module.exports = {Splash}
