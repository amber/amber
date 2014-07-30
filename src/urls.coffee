{Splash} = require "am/views/splash"
{Home} = require "am/views/home"
{Login} = require "am/views/login"
{Discuss} = require "am/views/discuss"

urls =
  "/": Splash
  "/home": Home
  "/login": Login
  "/discuss": Discuss

module.exports = {urls}
