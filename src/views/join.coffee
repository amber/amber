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
        @p outlet: "error", class: "error", style: "display: none"
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

  showError: (message) ->
    @error.textContent = message
    @error.style.display = ""

  submit: ->
    username = @username.value.trim()
    email = @email.value.trim()
    password = @password.value
    unless username
      @username.focus()
      return @showError T("You need a username.")
    unless password
      @password.focus()
      return @showError T("You need a password.")
    @username.disabled = @email.disabled = @password.disabled = yes
    @app.server.signUp {username, email, password}, (err) =>
      @username.disabled = @email.disabled = @password.disabled = no
      if err
        if err.name is "in use"
          @username.select()
          @showError T("The name “{username}” is taken.", {username})
        return # TODO
      @app.router.goBack "/"

module.exports = {Join}
