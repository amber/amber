{View, $} = require "space-pen"

class AddTopic extends View
  @content: ->
    @article =>
      @h1 "New topic"

module.exports = {AddTopic}
