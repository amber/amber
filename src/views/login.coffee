{View, $} = require "space-pen"

class Login extends View
  @content: ->
    @article =>
      @section class: "login", keydown: "onKeyDown", =>
        @h1 "Sign In"
        @input outlet: "username", placeholder: "Username"
        @input type: "password", placeholder: "Password"
        @button "Sign in", click: "submit"

  afterAttach: (onDom) -> @username.focus() if onDom

  onKeyDown: (e) ->
    if e.keyCode is 13
      @submit()
      e.preventDefault()

  submit: ->
    @parentView.router.go "/home"

module.exports = {Login}
