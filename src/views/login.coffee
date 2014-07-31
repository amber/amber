{View} = require "scene"
{T} = require "am/util"

class Login extends View
  @content: ->
    @article =>
      @section class: "login", keydown: "onKeyDown", =>
        @h1 T("Sign in")
        @input outlet: "username", placeholder: T("Username"), class: "large"
        @input type: "password", placeholder: T("Password"), class: "large"
        @button T("Sign in"), class: "large accent", click: "submit"

  title: -> T("Sign in")

  enter: -> @username.focus()

  onKeyDown: (e) ->
    if e.keyCode is 13
      @submit()
      e.preventDefault()

  submit: ->
    @parent.router.go "/home"

module.exports = {Login}
