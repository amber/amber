{View, $} = require "space-pen"
{Carousel} = require "am/views/carousel"
{T} = require "am/util"

class Splash extends View
  @content: ->
    @article =>
      @div class: "splash", =>
        @div class: "left", =>
          @h1 T("Realtime collaborative programming.")
          @p T("Create interactive stories, games, music, and art with people around the world.")
        @div class: "right", =>
          @input outlet: "username", placeholder: T("Username"), class: "large"
          @input type: "email", placeholder: T("Email address"), class: "large"
          @input type: "password", placeholder: T("Password"), class: "large"
          @button class: "large accent", T("Sign up")
      @h1 T("Featured projects")
      @subview "featured", new Carousel

  afterAttach: ->
    @username.focus()

module.exports = {Splash}
