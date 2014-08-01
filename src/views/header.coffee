{View} = require "scene"
{T} = require "am/util"

visible = (el, force) ->
  el.style.display = (if force then "inline-block" else "none")

class Header extends View
  @content: ->
    @header =>
      @div outlet: "container", class: "container", =>
        @a T("Amber"), dataKey: "Amber", href: "/"
        @a T("Create"), dataKey: "Create", href: "/new"
        @a T("Explore"), dataKey: "Explore", href: "/explore"
        @a T("Discuss"), dataKey: "Discuss", href: "/discuss"
        @a T("Sign In"), outlet: "login", dataKey: "Sign In", class: "right", href: "/login"
        @a T("Sign Out"), style: "display: none", outlet: "logout", dataKey: "Sign Out", class: "right", click: "signOut"
        @input type: "search", outlet: "search", keydown: "onKeyDown", placeholder: T("Search…")

  initialize: ({@app}) ->

  updateLanguage: ->
    for a in @container.querySelectorAll "a"
      a.textContent = T(a.dataset.key)
    @search.attr "placeholder", T("Search…")

  focusSearch: (content) ->
    @search.value = content if content?
    @search.focus()

  setUser: (user) ->
    visible @login, not user
    visible @logout, user

  signOut: ->
    @app.server.signOut =>
      @app.router.route()

  onKeyDown: (e) ->
    switch e.keyCode
      when 13
        e.preventDefault()
        @parent.router.go "/search/#{encodeURIComponent @search.value}"
      when 27
        @search.blur()

module.exports = {Header}
