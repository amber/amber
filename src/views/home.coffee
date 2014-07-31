{View} = require "scene"
{T} = require "am/util"
{Carousel} = require "am/views/carousel"

class Home extends View
  @content: ->
    @article =>
      @h1 T("Featured projects")
      @subview "featured", new Carousel
      @h1 T("Projects by people you follow")
      @subview "follow", new Carousel
      @h1 T("Starred by people you follow")
      @subview "starred", new Carousel
      @h1 T("New projects")
      @subview "new", new Carousel

module.exports = {Home}
