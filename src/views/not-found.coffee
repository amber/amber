{View} = require "scene"
{T} = require "am/util"

class NotFound extends View
  @content: ({url}) ->
    @article =>
      @h1 T("Not found")
      @p =>
        @text T("The page at “{url}” does not exist.", {url})
        if /^\/wiki\/(?!new\/)/.test url
          @text " "
          @html T("You can {a}create it{aEnd} if you like.", {
            a: """<a href="/wiki/new#{url.slice 5}">"""
            aEnd: "</a>"
          })

  title: -> T("Not found")

module.exports = {NotFound}
