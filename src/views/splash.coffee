{View, $} = require "space-pen"
{Carousel} = require "am/views/carousel"

class Splash extends View
  @content: ->
    @article =>
      @div class: "splash", =>
        @div class: "left", =>
          @h1 "Realtime collaborative programming."
          @p "Create interactive stories, games, music, and art with people around the world."
        @div class: "right", =>
          @input outlet: "username", placeholder: "Username"
          @input type: "email", placeholder: "Email address"
          @input type: "password", placeholder: "Password"
          @button "Sign up"
      @h1 "Featured projects"
      @subview "featured", new Carousel

  afterAttach: ->
    @username.focus()

module.exports = {Splash}
