require! fs
require! async
process.chdir __dirname

externalScripts =
  # \https://samizdat.cz/tools/tooltip/v1.1.4.d3.js
  ...

externalStyles =
  # \https://samizdat.cz/tools/tooltip/v1.1.4.css
  ...

externalData =
  # "style": "#__dirname/www/screen.css"
  "tweety": "#__dirname/data/tweety_clean.tsv"
  "tagy": "#__dirname/data/tagy.tsv"

preferScripts = <[ geoUtils.js utils.js postInit.js _loadData.js ../data.js init.js _loadExternal.js]>
deferScripts = <[ base.js ]>
develOnlyScripts = <[ _loadData.js _loadExternal.js]>
productionOnlyScripts = <[ _analytics.js ]>
gzippable = <[ www/index.deploy.html www/script.deploy.js ]>
safe-deployable =
  "www/index.deploy.html"
  "www/script.deploy.js"
  "www/index.deploy.html.gz"
  "www/script.deploy.js.gz"
  "www/screen.deploy.css"

build-styles = (options = {}, cb) ->
  require! cssmin
  (err, [external, local]) <~ async.parallel do
    * (cb) -> fs.readFile "#__dirname/www/external.css", cb
      (cb) -> prepare-stylus \screen, options, cb
  console.log err if err
  out = cssmin external + "\n\n\n" + local
  filename = if options.deploy then "screen.deploy.css" else "screen.css"
  tasks = [-> fs.writeFile "#__dirname/www/screen.css", out, it]
  if options.deploy
    tasks.push -> fs.writeFile "#__dirname/www/screen.deploy.css", out, it
  <~ async.parallel tasks
  cb?!

prepare-stylus = (file, options, cb) ->
  console.log "Building Stylus"
  require! stylus
  (err, data) <~ fs.readFile "#__dirname/www/styl/#file.styl"
  data .= toString!
  stylusCompiler = stylus data
    ..include "#__dirname/www/styl/"
    ..define \iurl stylus.url paths: ["#__dirname/www/img/"]
  if options.compression
    stylusCompiler.set \compress true
  (err, css) <~ stylusCompiler.render
  throw err if err
  console.log "Stylus built"
  cb null css

build-script = (file, cb) ->
  require! child_process:{exec}
  (err, result) <~ exec "lsc -o #__dirname/www/js -c #__dirname/#file"
  if err
    console.error err
  cb err

build-all-scripts = (cb) ->
  console.log "Building scripts..."
  require! child_process:{exec}
  (err, result) <~ exec "lsc -o #__dirname/www/js -c #__dirname/www/ls"
  throw err if err
  console.log "Scripts built"
  cb?!

download-external-scripts = (cb) ->
  console.log "Dowloading scripts..."
  require! request
  (err, responses) <~ async.map externalScripts, request~get
  bodies = responses.map (.body)
  <~ fs.writeFile "#__dirname/www/external.js" bodies.join "\n;\n"
  console.log "Scripts loaded"
  cb?!

download-external-data = (cb) ->
  console.log "Combining data..."
  files = for key, datafile of externalData => {key, datafile}
  out = {}
  (err) <~ async.each files, ({key, datafile}:file, cb) ->
    (err, data) <~ getExternalData datafile
    return cb that if err
    data .= toString!
    if \json is datafile.substr -4, 4
      data = JSON.parse data
    out[key] = data
    cb!
  console.log err if err
  <~ fs.writeFile "#__dirname/www/data.js", "window.ig.data = #{JSON.stringify out};"
  console.log "Data combined"
  cb?!

getExternalData = (address, cb) ->
  if address.split ":" .0 in <[http https]>
    require! request
    (err, res, body) <~ request.get address
    cb err, body
  else
    fs.readFile address, cb

download-external-styles = (cb) ->
  console.log "Downloading styles..."
  require! request
  (err, responses) <~ async.map externalStyles, request~get
  contents = responses.map (.body)
  <~ fs.writeFile "#__dirname/www/external.css" contents.join "\n\n"
  console.log "Styles loaded"
  cb!

combine-scripts = (options = {}, cb) ->
  console.log "Combining scripts..."
  require! "uglify-js":uglify
  (err, files) <~ fs.readdir "#__dirname/www/js"
  files .= filter -> it isnt 'script.js.map'
  if options.compression
    files .= filter -> it not in develOnlyScripts
    files.push "../data.js"
  else
    files .= filter -> it not in productionOnlyScripts
  files .= sort (a, b) ->
    indexA = deferScripts.indexOf a
    indexB = deferScripts.indexOf b
    if indexA == -1 and -1 != preferScripts.indexOf a
      indexA = -2 + -1 * preferScripts.indexOf a
    if indexB == -1 and -1 != preferScripts.indexOf b
      indexB = -2 + -1 * preferScripts.indexOf b

    indexA - indexB
  files .= map -> "#__dirname/www/js/#it"
  minifyOptions = {}
  if not options.compression
    minifyOptions
      ..compress     = no
      ..mangle       = no
      ..outSourceMap = "../js/script.js.map"
      ..sourceRoot   = "../../"
  result = uglify.minify files, minifyOptions

  {map, code} = result
  if not options.compression
    code += "\n//@ sourceMappingURL=./js/script.js.map"
    patt = __dirname.replace /\\/g '\\\\\\\\'
    map .= replace do
      new RegExp do
        patt
        'g'
      ''
    fs.writeFile "#__dirname/www/js/script.js.map", map
  else
    external = fs.readFileSync "#__dirname/www/external.js"
    code = external + "\n;\n" + code
  if options.deploy
    fs.writeFileSync "#__dirname/www/script.deploy.js", code
  else
    fs.writeFileSync "#__dirname/www/script.js", code
  console.log "Scripts combined"
  cb? err

run-script = (file) ->
  require! child_process:{exec}
  (err, stdout, stderr) <~ exec "lsc #__dirname/#file"
  console.error stderr if stderr
  console.log stdout

test-script = (file) ->
  require! child_process:{exec}
  [srcOrTest, ...fileAddress] = file.split /[\\\/]/
  fileAddress .= join '/'
  <~ build-all-server-scripts
  cmd = "mocha --compilers ls:livescript -R tap --bail #__dirname/test/#fileAddress"
  (err, stdout, stderr) <~ exec cmd
  niceTestOutput stdout, stderr, cmd

build-all-server-scripts = (cb) ->
  require! child_process:{exec}
  (err, stdout, stderr) <~ exec "lsc -o #__dirname/lib -c #__dirname/src"
  throw stderr if stderr
  cb? err

relativizeFilename = (file) ->
  file .= replace __dirname, ''
  file .= replace do
    new RegExp \\\\, \g
    '/'
  file .= substr 1

gzip-files = (cb) ->
  require! child_process:{exec}
  console.log "Zopfli-ing..."
  (err, stdout, stderr) <~ exec "zopfli #{gzippable.join ' '}"
  console.log "Zopflied"
  cb err

refresh-manifest = (cb) ->
  (err, file) <~ fs.readFile "#__dirname/www/manifest.template.appcache"
  return if err
  file .= toString!
  file += '\n# ' + new Date!toUTCString!
  <~ fs.writeFile "#__dirname/www/manifest.appcache", file
  cb?!

copy-index = ->
  fs.createReadStream "#__dirname/www/_index.html" .pipe do
    fs.createWriteStream "#__dirname/www/index.html"

deploy-files = (cb) ->
  console.log "Deploying files..."
  <~ async.each safe-deployable, (file, cb) ->
    fs.rename do
      "#__dirname/#file"
      "#__dirname/#{file.replace '.deploy' ''}"
      cb
  cb?!

inject-index = (cb) ->
  require! child_process:{exec}
  require! 'html-minifier':htmlmin
  require! request
  files =
    "#__dirname/www/_index.html"
    "#__dirname/www/script.deploy.js"
    "#__dirname/www/screen.deploy.css"
  (err, [index, script, style]) <~ async.map files, fs.readFile
  (err, response, d3body) <~ request.get "https://d3js.org/d3.v3.min.js"
  fullScript = d3body + script.toString!
  console.log err if err
  index .= toString!
  index .= replace '<script src="script.js" charset="utf-8" async></script>', -> "<script>#{fullScript}</script>"
  index .= replace '<link rel="stylesheet" href="screen.css">', "<style>#{style.toString!}</style>"
  htmlminConfig =
    collapseWhitespace: 1
    removeAttributeQuotes: 1
    removeRedundantAttributes: 1
    useShortDoctype: 1
    minifyJS: 1
    minifyCSS: 1
  # minified = index
  minified = htmlmin.minify index, htmlminConfig
  minified .= replace "<script src=https://samizdat.cz/tools/d3/3.5.3.min.js></script>" ""
  # minified .= replace /<path(.*?)>/g "<path$1/>"
  <~ fs.writeFile "#__dirname/www/index.deploy.html", minified
  cb?!


niceTestOutput = (test, stderr, cmd) ->
  lines         = test.split "\n"
  oks           = 0
  fails         = 0
  out           = []
  shortOut      = []
  disabledTests = []
  for line in lines
    if 'ok' == line.substr 0, 2
      ++oks
    else if 'not' == line.substr 0,3
      ++fails
      out.push line
      shortOut.push line.match(/not ok [0-9]+ (.*)$/)[1]
    else if 'Disabled' == line.substr 0 8
      disabledTests.push line
    else if line and ('#' != line.substr 0, 1) and ('1..' != line.substr 0, 3)
      console.log line# if ('   ' != line.substr 0, 3)
  if oks && !fails
    console.log "Tests OK (#{oks})"
    disabledTests.forEach -> console.log it
  else
    #console.log "!!!!!!!!!!!!!!!!!!!!!!!    #{fails}    !!!!!!!!!!!!!!!!!!!!!!!"
    if out.length
      console.log shortOut.join ", "#line for line in shortOut
    else
      console.log "Tests did not run (error in testfile?)"
      console.log test
      console.log stderr
      console.log cmd


[lsc, thisFile, task, ...args] = process.argv
switch task
| \build
  download-external-scripts!
  <~ download-external-styles
  # build-styles compression: no
  <~ build-all-scripts
  copy-index!
  combine-scripts compression: no

| \deploy
  <~ download-external-styles
  <~ build-styles compression: yes deploy: yes
  <~ async.parallel do
    * download-external-scripts
      download-external-data
      # build-all-server-scripts!
      # refresh-manifest!
  <~ build-all-scripts
  <~ combine-scripts compression: yes deploy: yes
  <~ inject-index!
  <~ gzip-files!
  <~ deploy-files!

| \build-styles
  copy-index!
  t0 = Date.now!
  <~ build-styles compression: no
  <~ download-external-data!

| \build-script
  currentfile = args[0]
  copy-index!
  file = relativizeFilename currentfile
  isServer = \src/ == file.substr 0, 4
  isScript = \srv/ == file.substr 0, 4
  isTest = \test/ == file.substr 0, 5
  isWww = \www/ == file.substr 0, 4
  if isServer or isTest
    test-script file
  else if isScript
    run-script file
  else if isWww
    (err) <~ build-script file
    combine-scripts compression: no if not err
  else
    <~ async.parallel do
      * download-external-scripts
        download-external-data
        download-external-styles
    <~ build-styles
    <~ build-all-scripts
    <~ combine-scripts


| \name
  name = args[0] || process.cwd!split /[/\\]/ .pop!
  fs.readFile "./package.json", (err, data) ->
    data = JSON.parse data.toString!
    data.name = name
    fs.writeFile "./package.json", JSON.stringify data, true, 2
  fs.readdir '.', (err, files) ->
    files.forEach (file) ->
      [...names, suffix] = file.split '.'
      oldname = names.join '.'
      if suffix in <[sublime-project sublime-workspace]>
        fs.rename file, file.replace oldname, name
  fs.readFile "./www/ls/init.ls", (err, data) ->
    return if err
    data .= toString!
    data .= replace /projectName : "(.*?)"/ 'projectName : "' + name + '"'
    fs.writeFile "./www/ls/init.ls" data
  fs.readFile "./www/_index.html", (err, data) ->
    return if err
    data = data.toString!replace /<title>(.*?)<\/title>/ "<title>#name</title>"
    fs.writeFile "./www/_index.html" data
