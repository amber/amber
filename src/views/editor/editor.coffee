{View} = require "scene"
{T} = require "am/util"
{TabPanel} = require "am/views/editor/tab-panel"

class Editor extends View
  @content: ->
    @div class: "editor", =>
      @div class: "left-panel", =>
        @div class: "stage"
        @div class: "sprite-list", =>
          @div class: "bar"
          @div class: "content"
      @subview new TabPanel

module.exports = {Editor}
