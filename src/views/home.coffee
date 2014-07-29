{View, $} = require "space-pen"
{Carousel} = require "am/views/carousel"

class Home extends View
  @content: ->
    @article =>
      @h1 "Featured projects"
      @subview "featured", new Carousel
      @h1 "Projects by people you follow"
      @subview "follow", new Carousel
      @h1 "Starred by people you follow"
      @subview "starred", new Carousel
      @h1 "New projects"
      @subview "new", new Carousel

module.exports = {Home}
