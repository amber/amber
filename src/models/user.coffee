module.exports = class User
  constructor: ({@id, @name, isAdmin}) ->
    @isAdmin = !!isAdmin

  canEditPost: (p) -> @isAdmin or @id is p.author or p.isWiki()
