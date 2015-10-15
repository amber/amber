fs = require "fs"
http = require "http"
path = require "path"
cluster = require "cluster"
url = require "url"

require "colors"
browserify = require "browserify"
coffeeify = require "coffeeify"
stylus = require "stylus"
nib = require "nib"
glob = require "glob"
watch = require "node-watch"

if cluster.isMaster
  worker = cluster.fork()

  cluster.on "exit", ->
    cluster.fork()

  return

BASE_DIR = path.resolve __dirname, ".."

aliasify = require('aliasify').configure
  aliases:
    main: "./src/main.coffee"
    am: "./src"
    scene: "./lib/scene/lib/scene.coffee"
    markup: "./lib/markup/markup.js"
  configDir: BASE_DIR
  verbose: no

b = browserify
  extensions: [".coffee"]
  debug: yes

b.transform coffeeify
b.transform aliasify

b.add "#{BASE_DIR}/src/main.coffee"

reloading = no
again = no
jsFirstTime = yes
do reload = ->
  if reloading
    again = yes
    return
  reloading = yes
  b.bundle (err, buf, map) ->
    if err
      console.log "js: err".red
      io.sockets.emit "js error", "#{err}"
      console.log "#{err}"
    else
      fs.writeFileSync "#{BASE_DIR}/static/app.js", buf
      console.log "js: ok".grey

    reloading = no
    if again
      again = no
      reload()
    else unless err
      io.sockets.emit "reload js" unless jsFirstTime
    jsFirstTime = no

cssFirstTime = yes
do reloadCSS = ->
  glob "#{BASE_DIR}/src/**/*.styl", (err, matches) ->
    return console.log err if err
    matches = (m for m in matches when "_" isnt path.basename(m)[0])
    matches.push "#{BASE_DIR}/lib/markup/markup.css"
    app = ""
    left = matches.length
    for m in matches
      stylus ""+fs.readFileSync(m), filename: m
        .use nib()
        .import 'nib'
        .render (err, css, js) ->
          if err
            console.log "css: err".red
            io.sockets.emit "css error", "#{err}"
            console.log "#{err}"
          else
            app += css + "\n"
            return if --left
            fs.writeFileSync "#{BASE_DIR}/static/app.css", app
            io.sockets.emit "reload css" unless cssFirstTime
            cssFirstTime = no
            console.log "css: ok".grey

MIME_TYPES =
  html: "text/html"
  css: "text/css"
  svg: "image/svg+xml"
  js: "application/javascript"
  map: "application/json"

timeout = null
cssTimeout = null
watch "#{BASE_DIR}/src", (file) ->
  return if /\.tmp$/.test file # ignore rename from atomic save
  if /\.styl$/.test file
    console.log "~ #{path.relative BASE_DIR, file}".yellow
    clearTimeout cssTimeout
    cssTimeout = setTimeout reloadCSS, 50
  else
    clearTimeout timeout
    console.log "~ #{path.relative BASE_DIR, file}".green
    timeout = setTimeout reload, 50

watch __dirname, (file) ->
  return if /\/data\//.test file # ignore mongodb changes
  console.log "~ #{path.relative BASE_DIR, file}".cyan
  cluster.worker.kill()

app = http.createServer (req, res) ->
  {pathname} = url.parse req.url
  resolved = if "/static/" is pathname.slice 0, 8
    path.resolve "/", pathname.slice 8
  else "/index.html"

  ext = resolved.split('.').pop()

  rs = fs.createReadStream "#{BASE_DIR}/static#{resolved}"
  rs.on "open", ->
    res.writeHead 200,
      "Content-Type": MIME_TYPES[ext] ? "text/plain"
      "Cache-Control": "no-cache"
    rs.pipe res
  rs.on "error", (err) ->
    res.writeHead 404
    res.end "Not found."

io = require("./base") app
app.listen process.env.PORT || 8080
