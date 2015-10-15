markup = require "markup"
{T} = require "am/util"

markup.templates.tag = (x, name) ->
  n = encodeURIComponent name
  """<a class="tag tag-#{n}" href="/discuss/t/#{n}">#{T(name)}</a>"""

module.exports = markup
