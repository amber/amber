{View, $} = require "space-pen"
{T} = require "am/util"

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
        @div class: "right-controls", =>
          @div class: "stat", "#{id * 3461 % 700}", => @strong T("views")
          @div class: "stat", "#{id * 5713 % 20}", => @strong T("stars")
          @div class: "stat", "#{id * 4671 % 10}", => @strong T("remixes")

module.exports = {Project}
