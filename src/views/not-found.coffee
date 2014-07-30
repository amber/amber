{View, $} = require "space-pen"
{T} = require "am/util"

class NotFound extends View
  @content: ({url}) ->
    @article =>
      @h1 T("Not found")
      @p T("The page at \"{url}\" does not exist.", {url})

module.exports = {NotFound}
