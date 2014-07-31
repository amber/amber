{View} = require "scene"
{T} = require "am/util"

class Footer extends View
  @content: ->
    @footer =>
      @a T("Contact"), "data-key": "Contact", href: "/contact"
      @a T("About"), "data-key": "About", href: "/about"
      @a T("Terms"), "data-key": "Terms", href: "/terms"
      @p T("Made with ♡ by Nathan Dinsmore and Truman Kilen."), outlet: "love"

  updateLanguage: ->
    for a in @querySelectorAll "a"
      a.textContent = T(a.dataset.key)
    @love.text T("Made with ♡ by Nathan Dinsmore and Truman Kilen.")

module.exports = {Footer}
