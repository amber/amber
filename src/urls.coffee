{Splash} = require "am/views/splash"
{Home} = require "am/views/home"
{Login} = require "am/views/login"
{Discuss} = require "am/views/discuss"
{AddTopic} = require "am/views/add-topic"
{Explore} = require "am/views/explore"
{Search} = require "am/views/search"

urls =
  "/": Splash
  "/home": Home
  "/login": Login
  "/explore": Explore
  "/discuss": Discuss
  "/discuss/new": AddTopic
  "/discuss/:filter": Discuss
  "/search/:query": Search

module.exports = {urls}
