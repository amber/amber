{View} = require "scene"

class ScriptsTab extends View
  @content: ->
    @div class: "panel-content", =>
      @div class: "palette"
      @subview new ScriptEditor

class EmptyTab extends View
  @content: ->
    @div class: "panel-content"

class TabPanel extends View
  @content: ->
    @div class: "tab-panel", =>
      @div class: "bar", click: "onTabClick", =>
        for t, i in [T("Scripts"), T("Sounds"), T("Costumes"), T("Info")]
          @div class: "tab", dataIndex: i, t
      @subview "content", new View

  initialize: ->
    @tabs = @base.querySelectorAll ".tab"
    @panels = [
      new ScriptsTab
      new EmptyTab
      new EmptyTab
      new EmptyTab
    ]
    @selectTab 0

  onTabClick: (e) ->
    i = +e.target.dataset.index
    if i is i then @selectTab i

  selectTab: (i) ->
    if @activeTab
      @activeTab.classList.remove "active"
    (@activeTab = @tabs[i]).classList.add "active"
    @content.replaceWith @content = @panels[i]

module.exports = {TabPanel}
{T} = require "am/util"
{Block, Script} = require "./blocks"
{ScriptEditor} = require "./script-editor"
