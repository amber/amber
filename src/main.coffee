{App} = require "am/app"
{Router} = require "am/router"

@app = new App
router = new Router app
app.embed document.body
