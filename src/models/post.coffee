module.exports = class Post
  constructor: ({@id, @hidden, @author, @body, created, updated}, @index, @topic) ->
    @created = new Date created
    @updated = new Date updated

  isWiki: -> "wiki" in @topic.tags and @index is 0
