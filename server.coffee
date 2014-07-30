fs = require "fs"
http = require "http"
polvo = require "polvo"

polvo release: yes

html = ["text/html", fs.readFileSync "public/index.html"]
js = ["application/javascript", fs.readFileSync "public/app.js"]
css = ["text/css", fs.readFileSync "public/app.css"]
icons = ["image/svg+xml", fs.readFileSync "public/icons.svg"]

app = http.createServer (req, res) ->
  [type, contents] = switch req.url
    when "/app.js" then js
    when "/app.css" then css
    when "/icons.svg" then icons
    else html

  res.writeHead 200,
    "Content-Length": contents.length
    "Content-Type": type
  res.end contents

app.listen process.env.PORT || 8080
