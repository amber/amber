{View} = require "scene"
{T} = require "am/util"

class InternalError extends View
  @content: ({name, message, stack}) ->
    @article =>
      @h1 name
      @p message
      @pre => @code stack

  title: -> T("Internal error")

module.exports = {InternalError}
