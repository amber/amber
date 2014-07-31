{View} = require "scene"
{T} = require "am/util"

class Search extends View
  @content: ({query}) ->
    @article =>
      @h1 T("Search results for \"{query}\"", {query})

module.exports = {Search}
