{View, $} = require "space-pen"

class Project extends View
  @content: ({id}) ->
    @article =>
      @h1 "Project ##{id}"

module.exports = {Project}
