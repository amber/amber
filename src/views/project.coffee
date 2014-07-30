{View, $} = require "space-pen"

class Project extends View
  @content: ({id}) ->
    @article =>
      @h1 "Project ##{id}"
      @section class: "project", =>
        @div class: "left-controls", =>
          @button class: "flag"
          @button class: "stop"
          @button class: "full-screen"
        @img class: "player", src: "http://lorempixel.com/480/360/abstract/#{id % 7}"
        @div class: "right-controls"

module.exports = {Project}
