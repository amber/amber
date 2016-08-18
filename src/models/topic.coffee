Post = require "am/models/post"

module.exports = class Topic
  constructor: ({@id, @url, @title, @author, created, @tags, posts}) ->
    @created = new Date created
    @posts = (new Post p, i, @ for p, i in posts)

  addPost: (d) ->
    @posts.push post = new Post d, @posts.length, @
    post
