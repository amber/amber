{Splash} = require "am/views/splash"
{Home} = require "am/views/home"
{Login} = require "am/views/login"
{Join} = require "am/views/join"
{Discuss} = require "am/views/discuss"
{AddTopic} = require "am/views/add-topic"
{Explore} = require "am/views/explore"
{Search} = require "am/views/search"
{Project} = require "am/views/project"
{Topic} = require "am/views/topic"
{AddPage} = require "am/views/add-page"

wiki = ({app}) -> new Topic {app, url: location.pathname}

urls =
  "/": (d) -> new (if d.app.server.user then Home else Splash) d
  "/home": Home
  "/login": Login
  "/join": Join
  "/explore": Explore
  "/discuss": Discuss
  "/discuss/new": AddTopic
  "/discuss/s/:filter": Discuss
  "/discuss/t/:tag": ({app, tag}) -> new Discuss {app, filter: "[#{tag}] "}
  "/topic/:id": Topic
  "/search/:query": Search
  "/project/:id": Project
  "/wiki": wiki
  "/wiki/new": AddPage
  "/wiki/new/:page": AddPage
  "/wiki/t/:tag": ({app, tag}) -> new Discuss {app, filter: "[wiki] [#{tag}]"}
  "/wiki/:page": wiki
  "/terms": wiki
  "/privacy": wiki
  "/about": wiki

module.exports = {urls}
