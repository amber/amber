{View} = require "scene"
{T} = require "am/util"

class Topic extends View
  @content: ({id}) ->
    @article =>
      @h1 "The name of topic ##{id}"
      for i in [1..100]
        @section class: "post", =>
          @img src: "http://lorempixel.com/100/100/abstract/#{i % 7}"
          @div class: "author", =>
            users = "nathan MathWizz someone user userwithalongername".split " "
            name = users[i % 7]
            url = "/user/#{name}"
            time = "#{i * 32471 % 50 + 5} minutes ago"
            @html T("<a href=\"{url}\">{name}</a> posted {time}", {url, name, time})
          @p (if i % 2 then "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." else "This is a shorter message.")

  initialize: ({@id}) ->
  title: -> "The name of topic ##{@id}"

module.exports = {Topic}
