{View} = require "scene"
{T} = require "am/util"
{TabPanel} = require "am/views/editor/tab-panel"
{ScriptEditor} = require "am/views/editor/script-editor"

class Editor extends View
  @content: ->
    @div class: "editor", =>
      @subview new ScriptEditor
      # @div class: "left-panel", =>
      #   @div class: "stage"
      #   @div class: "sprite-list", =>
      #     @div class: "bar"
      #     @div class: "content"
      # @subview new TabPanel

module.exports = {Editor}
