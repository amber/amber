{View, $} = require "space-pen"
{T} = require "am/util"

class AddTopic extends View
  @content: ->
    @article =>
      @h1 T("New topic")

module.exports = {AddTopic}
