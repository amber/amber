fs = require "fs"
http = require "http"
path = require "path"
browserify = require "browserify"
coffeeify = require "coffeeify"
stylus = require "stylus"

aliasify = require('aliasify').configure
  aliases:
    main: "./src/main.coffee"
    am: "./src"
    scene: "./lib/scene/lib/scene.coffee"
    markup: "./lib/markup/markup.js"
  configDir: __dirname
  verbose: no

b = browserify
  extensions: [".coffee"]
  debug: yes

b.transform coffeeify
b.transform aliasify

b.add "#{__dirname}/src/main.coffee"

reloading = no
again = no
do reload = ->
  if reloading
    again = yes
    return
  reloading = yes
  console.log "reloading…"
  b.bundle (err, buf, map) ->
    return console.log err if err

    fs.writeFileSync "#{__dirname}/static/app.js", buf

    reloading = no
    console.log "done"
    if again
      again = no
      reload()

MIME_TYPES =
  html: "text/html"
  css: "text/css"
  svg: "image/svg+xml"
  js: "application/javascript"
  map: "application/json"

timeout = null
fs.watch "#{__dirname}/src", ->
  clearTimeout timeout
  timeout = setTimeout reload, 50

app = http.createServer (req, res) ->
  resolved = if "/static/" is req.url.slice 0, 8
    path.resolve "/", req.url.slice 8
  else "/index.html"

  ext = resolved.split('.').pop()

  rs = fs.createReadStream "#{__dirname}/static#{resolved}"
  rs.on "open", ->
    res.writeHead 200, "Content-Type": MIME_TYPES[ext] ? "text/plain"
    rs.pipe res
  rs.on "error", (err) ->
    res.writeHead 404
    res.end "Not found."

app.listen process.env.PORT || 8080
