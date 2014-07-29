{View, $} = require "space-pen"
{format} = require "am/util"

class NotFound extends View
  @content: ({url}) ->
    @article =>
      @h1 "Not Found"
      @p format """The page at "{url}" does not exist.""", {url}

module.exports = {NotFound}
