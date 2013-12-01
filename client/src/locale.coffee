{ hasOwnProperty } = @
{ Base, format } = amber.util

class Locale extends Base
  constructor: (@id, @name) -> super()
  @property 'id'
  @property 'name'

locales = {}
currentLocale = 'en-US'
localeList = [
  new Locale 'en-US', 'English (US)'
  new Locale 'en-PT', 'Pirate-speak'
]

getText = (id) ->
  l = locales[currentLocale]
  if hasOwnProperty.call l, id
    result = l[id]
  else
    if currentLocale isnt 'en-US'
      console.warn 'missing translation key "' + id + '"'
    result = id

  if arguments.length is 1
    result
  else
    format.apply null, [result].concat [].slice.call arguments, 1

maybeGetText = (trans) ->
  if trans and trans.$ then getText trans.$ else trans

getList = (list) ->
  (locales[currentLocale].__list or locales['en-US'].__list) list

getPlural = (a, b, n) ->
  if n is 1 then getText b, n else getText a, n

module 'amber', {
  locales
}
module 'amber.locale', {
  Locale
  currentLocale
  getText
  maybeGetText
  getList
  getPlural
}
