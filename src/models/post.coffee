module.exports = class Post
  constructor: ({@id, @author, @body, created, updated}, @index, @topic) ->
    @created = new Date created
    @updated = new Date updated
