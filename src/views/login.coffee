{View, $} = require "space-pen"

class Login extends View
  @content: ->
    @article =>
      @section class: "login", keydown: "onKeyDown", =>
        @input placeholder: "Username"
        @input type: "password", placeholder: "Password"
        @button "Sign in", click: "submit"

  onKeyDown: (e) ->
    if e.keyCode is 13
      @submit()
      e.preventDefault()

  submit: ->
    @parentView.router.go "/home"

module.exports = {Login}
