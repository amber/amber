module.exports = class User
  constructor: ({@id, @name, isAdmin}) ->
    @isAdmin = !!isAdmin
