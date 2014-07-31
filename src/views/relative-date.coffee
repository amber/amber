{View} = require "scene"
{T, relativeDate} = require "am/util"

class RelativeDate extends View
  @content: -> @span()
  initialize: (@date = new Date) -> @update()

  enter: -> @interval = setInterval @update, 60 * 1000
  exit: -> clearInterval @interval

  setDate: (@date) -> @update()
  update: =>
    @base.textContent = relativeDate @date

module.exports = {RelativeDate}
