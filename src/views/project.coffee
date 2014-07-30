{View, $} = require "space-pen"
{T} = require "am/util"

class Project extends View
  @content: ({id}) ->
    @article =>
      @h1 "Project ##{id}"
      @section class: "project-subtitle", =>
        users = "nathan MathWizz someone user userwithalongername".split " "
        name = users[id % 7]
        url = "/#{name}"
        time = "#{id * 32471 % 50 + 5} minutes ago"
        @raw T("<a href=\"{url}\">{name}</a> created {time}", {url, name, time})
      @section class: "project", =>
        @div class: "controls", =>
          @button class: "flag"
          @button class: "stop"
          @button class: "full-screen"
        @img class: "player", src: "http://lorempixel.com/480/360/abstract/#{id % 7}"
        @div class: "stats", =>
          @div class: "stat", "#{id * 3461 % 700}", => @strong T("views")
          @div class: "stat", "#{id * 5713 % 20}", => @strong T("stars")
          @div class: "stat", "#{id * 4671 % 10}", => @strong T("remixes")
        @section class: "notes", "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
module.exports = {Project}
