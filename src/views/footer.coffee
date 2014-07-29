{View, $} = require "space-pen"

class Footer extends View
  @content: ->
    @footer =>
      @a "Contact", href: "/contact"
      @a "About", href: "/about"
      @a "Terms", href: "/terms"
      @p "Made with ♡ by Nathan Dinsmore and Truman Kilen."

module.exports = {Footer}
