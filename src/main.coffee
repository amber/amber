{App} = require "am/app"
{Router} = require "am/router"
{Server} = require "am/models/server"

window.app = new App
server = new Server app
router = new Router app
app.embed document.body
