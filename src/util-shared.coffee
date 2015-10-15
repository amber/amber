slugify = (name) ->
  name.replace(/^\W+|\W+$|['"()]/g, '').replace(/\W+/g, '-').toLowerCase()

module.exports = {slugify}
