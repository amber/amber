{View, $} = require "space-pen"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 "The name of topic ##{id}"

  initialize: ({@id}) ->
  title: -> "The name of topic ##{@id}"

module.exports = {Topic}
