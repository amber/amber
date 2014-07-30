{View, $} = require "space-pen"

class Login extends View
  @content: ->
    @article =>
      @section class: "login", =>
        @input placeholder: "Username"
        @input type: "password", placeholder: "Password"
        @button "Sign in", click: "submit"

  submit: =>
    @parentView.router.go "/home"

module.exports = {Login}
