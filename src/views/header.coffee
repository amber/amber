{View, $} = require "space-pen"
{T} = require "am/util"

class Header extends View
  @content: ->
    @header =>
      @div outlet: "container", class: "container", =>
        @a T("Amber"), "data-key": "Amber", href: "/"
        @a T("Create"), "data-key": "Create", href: "/create"
        @a T("Explore"), "data-key": "Explore", href: "/explore"
        @a T("Discuss"), "data-key": "Discuss", href: "/discuss"
        @a T("Sign In"), "data-key": "Sign In", class: "right", href: "/login"
        @input type: "search", outlet: "search", keydown: "onKeyDown", placeholder: T("Search…")

  updateLanguage: ->
    for a in @container.children "a"
      a.textContent = T(a.dataset.key)
    @search.attr "placeholder", T("Search…")

  focusSearch: (content) ->
    @search.val content if content?
    @search.focus()

  onKeyDown: (e) ->
    if e.keyCode is 27
      @search.blur()

module.exports = {Header}
