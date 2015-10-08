{View} = require "scene"
{T} = require "am/util"

class Join extends View
  @content: ->
    @article =>
      @section class: "login", keydown: "onKeyDown", input: "onInput", =>
        @h1 T("Sign up")
        @input outlet: "username", placeholder: T("Username"), class: "large"
        @input outlet: "email", type: "email", placeholder: T("Email"), class: "large"
        @input outlet: "password", type: "password", placeholder: T("Password"), class: "large"
        @button T("Sign up"), class: "large accent", click: "submit"

  title: -> T("Sign up")

  initialize: ({@app}) ->
    app.router.goBack "/" if app.server.user
  enter: ->
    @username.focus()

  onKeyDown: (e) ->
    if e.keyCode is 13
      @submit()
      e.preventDefault()

  onInput: ->
    @error.style.display = "none"

  submit: ->
    @username.disabled = @email.disabled = @password.disabled = yes
    @app.server.signUp {
      username: @username.value
      email: @email.value
      password: @password.value
    }, (err) =>
      @username.disabled = @email.disabled = @password.disabled = no
      return if err # TODO
      @app.router.goBack "/"

module.exports = {Join}
