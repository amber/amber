{View, $} = require "space-pen"

class Home extends View
  @content: ->
    @article =>
      @h1 "Featured projects"
      @p "Projects that we think are interesting go here."
      @h1 "New projects"
      @p "Projects that were shared recently go here."
      @h1 "Projects by people you follow"
      @p "Projects that people you follow shared recently go here."
      @h1 "Starred by people you follow"
      @p "Projects that people you follow starred recently go here."

module.exports = {Home}
