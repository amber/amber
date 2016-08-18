{Splash} = require "am/views/splash"
{Home} = require "am/views/home"
{Login} = require "am/views/login"
{Join} = require "am/views/join"
{Discuss} = require "am/views/discuss/discuss"
{AddTopic} = require "am/views/discuss/add-topic"
{Topic} = require "am/views/discuss/topic"
{Explore} = require "am/views/explore"
{Search} = require "am/views/search"
{Project} = require "am/views/project"
{AddPage} = require "am/views/wiki/add-page"
{Editor} = require "am/views/editor/editor"

wiki = ({app}) -> new Topic {app, url: location.pathname}

urls =
  "/": (d) -> new (if d.app.server.user then Home else Splash) d
  "/new": Editor
  "/home": Home
  "/login": Login
  "/join": Join
  "/explore": Explore
  "/discuss": Discuss
  "/discuss/new": AddTopic
  "/discuss/issues": ({app}) -> new Discuss {app, filter: "([bug] OR [suggestion]) -[fixed] -[duplicate] -[closed] "}
  "/discuss/s/:filter": Discuss
  "/discuss/t/:tag": ({app, tag}) -> new Discuss {app, filter: "[#{tag}] "}
  "/topic/:id": Topic
  "/search/:query": Search
  "/project/:id": Project
  "/wiki": wiki
  "/wiki/new": AddPage
  "/wiki/new/:page": AddPage
  "/wiki/all": ({app}) -> new Discuss {app, filter: "[wiki] "}
  "/wiki/t/:tag": ({app, tag}) -> new Discuss {app, filter: "[wiki] [#{tag}] "}
  "/wiki/:page": wiki
  "/terms": wiki
  "/privacy": wiki
  "/about": wiki

module.exports = {urls}
