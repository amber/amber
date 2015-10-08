{View} = require "scene"
{Carousel} = require "am/views/carousel"
{T} = require "am/util"

class Splash extends View
  @content: ->
    @article =>
      @div class: "splash", =>
        @div class: "left", =>
          @h1 T("Realtime collaborative programming.")
          @p T("Create interactive stories, games, music, and art with people around the world.")
        @div class: "right", keydown: "onKeyDown", =>
          @input outlet: "username", placeholder: T("Username"), class: "large"
          @input outlet: "email", type: "email", placeholder: T("Email address"), class: "large"
          @input outlet: "password", type: "password", placeholder: T("Password"), class: "large"
          @button click: "signUp", class: "large accent", T("Sign up")
      @h1 T("Featured projects")
      @subview "featured", new Carousel

  enter: -> @username.focus()

  signUp: ->
    @username.disabled = @email.disabled = @password.disabled = yes
    @parent.server.signUp {
      username: @username.value
      email: @email.value
      password: @password.value
    }, (err) =>
      @username.disabled = @email.disabled = @password.disabled = no
      return if err # TODO
      @parent.router.go "/"

  onKeyDown: (e) ->
    if e.keyCode is 13
      e.preventDefault()
      @signUp()

module.exports = {Splash}
