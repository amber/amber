{View, $$} = require "scene"
{emitter} = require "am/util"

class TagEditor extends View
  emitter @::

  @content: ({placeholder} = {}) ->
    @div class: "text-field tags-editor", mousedown: "onMouseDown", =>
      @span outlet: "tagContainer", class: "tags"
      @div outlet: "metrics", class: "metrics"
      @input outlet: "input", input: "onInput", keypress: "onKeyPress", keydown: "onKeyDown", focus: "onFocus", blur: "onBlur", placeholder: placeholder ? ""

  enter: -> @onInput()

  initialize: ({permanent}) ->
    @permanent = permanent ? []
    @tags = []
    @addTag t for t in @permanent

  addTag: (tag) ->
    return unless tag = tag.trim()
    @tags.push tag
    @tagContainer.appendChild $$ -> @span tag, class: "tag tag-#{tag}"

  popTag: ->
    return if @tags.length <= @permanent.length
    @tagContainer.removeChild @tagContainer.lastElementChild
    @tags.pop()

  clearTags: ->
    @tagContainer.removeChild @tagContainer.lastChild while @tagContainer.children.length > @permanent.length
    @tags = @permanent.slice()

  getTags: -> @tags
  setTags: (tags) ->
    @clearTags()
    for t in @permanent.concat tags then @addTag t
    @input.value = ""
    @onInput()

  onInput: ->
    @metrics.textContent = @input.value or @input.placeholder or " "
    @input.style.width = "#{@metrics.offsetWidth + 1}px"
    @input.classList.toggle "nonempty", !!@input.value.trim()

  onMouseDown: ->
    setTimeout => @input.focus()

  onKeyPress: (e) ->
    if e.keyIdentifier in ["U+0020", "U+002C"]
      @commit()
      e.preventDefault()

  onKeyDown: (e) ->
    if e.keyCode is 13
      @commit()
      e.preventDefault()
    if e.keyCode is 8 and @input.selectionStart is @input.selectionEnd and @input.selectionStart is 0 and @tags.length > @permanent.length
      if e.metaKey
        @clearTags()
      else
        tag = @popTag()
        unless e.altKey or e.ctrlKey
          @input.value = tag + @input.value
          @input.selectionStart = @input.selectionEnd = tag.length
          @onInput()
        e.preventDefault()

  commit: ->
    @addTag @input.value.trim()
    @input.value = ""
    @onInput()

  onFocus: -> @base.classList.add "focused"
  onBlur: ->
    @base.classList.remove "focused"
    if @input.value
      @commit()

module.exports = {TagEditor}
