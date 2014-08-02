fs = require "fs"
http = require "http"
path = require "path"
browserify = require "browserify"
coffeeify = require "coffeeify"
stylus = require "stylus"
nib = require "nib"
glob = require "glob"
watch = require "node-watch"

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
  b.bundle (err, buf, map) ->
    return console.log err if err

    fs.writeFileSync "#{__dirname}/static/app.js", buf

    reloading = no
    console.log "js: ok"
    if again
      again = no
      reload()

do reloadCSS = ->
  glob.sync "#{__dirname}/src/**/*.styl", (err, matches) ->
    return console.log err if err
    matches = (m for m in matches when "_" isnt path.basename(m)[0])
    app = ""
    left = matches.length
    for m in matches
      stylus ""+fs.readFileSync(m), filename: m
        .use nib()
        .import 'nib'
        .render (err, css, js) ->
          return console.log err if err
          app += css + "\n"
          return if --left
          fs.writeFileSync "#{__dirname}/static/app.css", app
          console.log "css: ok"

MIME_TYPES =
  html: "text/html"
  css: "text/css"
  svg: "image/svg+xml"
  js: "application/javascript"
  map: "application/json"

timeout = null
cssTimeout = null
watch "#{__dirname}/src", (file) ->
  return if /\.tmp$/.test file # ignore rename from atomic save
  console.log "~ #{path.relative __dirname, file}"
  if /\.styl$/.test file
    clearTimeout cssTimeout
    cssTimeout = setTimeout reloadCSS, 50
  else
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
