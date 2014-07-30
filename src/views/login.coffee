{View, $} = require "space-pen"

class Login extends View
  @content: ->
    @article =>
      @section class: "login", =>
        @input placeholder: "Username"
        @input type: "password", placeholder: "Password"
        @button "Sign in"

module.exports = {Login}
