slugify = (name) ->
  name.replace(/^\W+|\W+$|['"()]/g, '').replace(/\W+/g, '-').toLowerCase()

capitalize = (s) -> s[0].toUpperCase() + s.slice 1

deslugify = (name) ->
  capitalize name.replace(/-/g, ' ')

module.exports = {slugify, capitalize, deslugify}
