module.exports = class TopicSummary
  constructor: ({@id, @title, @author, created, @tags}) ->
    @created = new Date created
