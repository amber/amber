{View, $} = require "space-pen"
{T} = require "am/util"

class Login extends View
  @content: ->
    @article =>
      @section class: "login", keydown: "onKeyDown", =>
        @h1 T("Sign in")
        @input outlet: "username", placeholder: T("Username")
        @input type: "password", placeholder: T("Password")
        @button T("Sign in"), click: "submit"

  title: -> T("Sign in")

  afterAttach: (onDom) -> @username.focus() if onDom

  onKeyDown: (e) ->
    if e.keyCode is 13
      @submit()
      e.preventDefault()

  submit: ->
    @parentView.router.go "/home"

module.exports = {Login}
