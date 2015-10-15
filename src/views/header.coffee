{View} = require "scene"
{T} = require "am/util"

visible = (el, flag) ->
  el.style.display = if flag then "" else "none"

class Header extends View
  @content: ->
    @header =>
      @div outlet: "container", class: "container", =>
        @a T("Amber"), dataKey: "Amber", href: "/"
        @a T("Create"), dataKey: "Create", href: "/new"
        @a T("Explore"), dataKey: "Explore", href: "/explore"
        @a T("Discuss"), dataKey: "Discuss", href: "/discuss"
        @a T("Sign In"), outlet: "login", dataKey: "Sign In", class: "right", href: "/login"
        @span class: "right drop-down", style: "display: none", outlet: "userButton", click: "toggleUserMenu", =>
          @a =>
            @span outlet: "userName"
            @span class: "arrow"
          @div class: "menu", =>
            @a T("Preferences"), dataKey: "Preferences", click: "goPreferences"
            @a T("Sign Out"), dataKey: "Sign Out", click: "signOut"
        @input type: "search", outlet: "search", keydown: "onKeyDown", placeholder: T("Search…")

  initialize: ({@app}) ->

  updateLanguage: ->
    for a in @container.querySelectorAll "a" when a isnt @userButton
      a.textContent = T(a.dataset.key)
    @search.attr "placeholder", T("Search…")

  focusSearch: (content) ->
    @search.value = content if content?
    @search.focus()

  setUser: (user) ->
    visible @login, not user
    visible @userButton, user
    if user
      console.log user
      @userName.textContent = user.name

  signOut: ->
    @app.server.signOut =>
      @app.router.route()

  toggleUserMenu: (e) ->
    e.preventDefault()
    @userButton.classList.toggle "active"

  goPreferences: (e) ->
    e.preventDefault()
    @parent.router.go "/preferences"

  onKeyDown: (e) ->
    switch e.keyCode
      when 13
        e.preventDefault()
        @parent.router.go "/search/#{encodeURIComponent @search.value}"
      when 27
        @search.blur()

module.exports = {Header}
