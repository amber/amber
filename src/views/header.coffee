{View, $} = require "space-pen"

class Header extends View
  @content: ->
    @header =>
      @div class: "container", =>
        @a "Amber", href: "/"
        @a "Create", href: "/create"
        @a "Explore", href: "/explore"
        @a "Discuss", href: "/discuss"
        @input type: "search", placeholder: "Search…"

module.exports = {Header}
