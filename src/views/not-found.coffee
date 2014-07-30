{View, $} = require "space-pen"
{T} = require "am/util"

class NotFound extends View
  @content: ({url}) ->
    @article =>
      @h1 T("Not Found")
      @p T("The page at \"{url}\" does not exist.", {url})

module.exports = {NotFound}
