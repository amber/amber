{View} = require "scene"
{RelativeDate} = require "am/views/relative-date"

class Post extends View
  @content: ({author, created, body}) ->
    @section class: "post", =>
      @img src: "http://lorempixel.com/100/100/abstract/1"
      @div class: "author", =>
        @a href: "/user/#{author}", author
        @text " posted "
        @subview new RelativeDate created
      @p body

module.exports = {Post}
