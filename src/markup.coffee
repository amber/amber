markup = require "markup"
{T, slugify} = require "am/util"

markup.templates.tag = (x, name) ->
  n = encodeURIComponent name
  """<a class="tag tag-#{n}" href="/discuss/t/#{n}">#{T(name)}</a>"""

markup.templates.wiki = (x, page, text) ->
  """<a href="/wiki/#{slugify page}">#{text ? page}</a>"""

module.exports = markup
