module.exports = class TopicSummary
  constructor: ({@id, @url, @title, @author, created, @tags, @viewCount, @postCount, @starred, @unread}) ->
    @created = new Date created
