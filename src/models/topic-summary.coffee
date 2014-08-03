module.exports = class TopicSummary
  constructor: ({@id, @title, @author, created, @tags}) ->
    console.log created
    @created = new Date created
