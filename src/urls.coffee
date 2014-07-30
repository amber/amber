{Splash} = require "am/views/splash"
{Home} = require "am/views/home"
{Login} = require "am/views/login"

urls =
  "/": Splash
  "/home": Home
  "/login": Login

module.exports = {urls}
