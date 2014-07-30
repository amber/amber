{Splash} = require "am/views/splash"
{Home} = require "am/views/home"
{Login} = require "am/views/login"
{Discuss} = require "am/views/discuss"
{AddTopic} = require "am/views/add-topic"

urls =
  "/": Splash
  "/home": Home
  "/login": Login
  "/discuss": Discuss
  "/discuss/new": AddTopic
  "/discuss/:filter": Discuss

module.exports = {urls}
