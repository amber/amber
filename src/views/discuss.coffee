{View, $} = require "space-pen"
{T} = require "am/util"

class Discuss extends View
  @content: ->
    @article =>
      @h1 T("Discuss Amber")

module.exports = {Discuss}
