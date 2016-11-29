require! {
  "rss-parser": rss
  async
  fb: FB
  fs
  request
  mysql
}
accessToken = "EAACEdEose0cBAGrorqJxSuU5ijyEXa68mvCXhYOVZBG5qznZBBFvfAUnYFuYkzUrSZBpZBvAF0CZBAmT7O6LZCDcvYKGTzzuz0W8kjCWVE5YsyyZBHyZByXEszxJ74ZBJdnL9Mlm4xsvwoByg7qopGYIAmrVkISrvXZCmFQd6zYjpYCwZDZD"
sources =
  [100683176313, "idnes"]
  [52479821102, "respekt"]
  [1437121429870192, "dvtv"]
  [513697425424894, "IvCRN"]
  [43855944703, "svobodni"]
  [179497582061065, "okamura"]
  [90002267161, "top09"]
  [214827221987263, "andrej"]
  # [88822578037, "lidovky"]
  # [231702800367893, "ln"]
  # [363829437158226, "aeronet"]
  # [135144949863739, "parlace"]
  # [202451429883, "novinky"]
  # [93433992603, "ihned"]
  # [53247283454, "hospodarky"]
  # [52117071582, "MF Dnes"]
  # [137301989386, "aktualne.cz"]
  # [137067469008, "CT24"]
  # [142069753862, "nova"]
  # [210778132327279, "prima"]
  # [34825122262, "reflex"]
  # [482885755074163, "Tydenikpolicie"]
  # [114811848586566, "tyden"]
  # [50309511751, "CRo1"]
  # [123858471641, "Zpravy.rozhlas.cz"]
  # [213277405366807, "super.cz"]
  # [206045673805, "denik.cz"]
  # [143886599126215, "protiproud"]
  # [139079856198676, "prvnizpravy"]
  # [120250914680166, "eurozpravy"]
  # [111041662264882, "cssd"]
  # [30575632699, "ods"]
  # [526346124083250, "usvit"]
  # [298789466930469, "kscm"]
  # [211401918930049, "ano"]
  # [39371299263, "sz"]
  # [197466333678437, "delnici"]
  # [109323929038, "pirati"]
  # [751578688203935, "echo"]
  # [727173144044824, "svobodny forum"]
  # [272128832951927, "pratele ruska"]
  # [447515225396176, "neovlivni"]
  # [1489109218022130, "hlidacipes"]
  # [287724754662359, "hatefree"]
  # [342117105834888, "svetkolemnas"]
  # [441997272643660, "BPI"]
  # [937443906286455, "spd"]
  # [156906653206, "spo"]
  # [251656685576, "kdu"]
  # [240797486091742, "narodni demokracie"]
  # [176546515755264, "ac24"]
  # [340208672684617, "sputnik.cz"]
  # [342117105834888, "svetkolemnas"]
  # [857381140982848, "lajkit"]
  # [139079856198676, "prvnizpravy"]
  # [250871675109146, "instory"]
  # [188950254487749, "czechfreepress"]
  # [1609110509368821, "ceskoaktualne"]
  # [240233692807752, "svobodnenoviny"]
  # [880078005385630, "vlasteneckenoviny"]
  # [209103575824951, "vlastnihlavou"]
  # [1557808121115600, "infowars"]
  # [155921711663, "zvedavec"]
  # [297969846922939, "eportal.cz"]
  # [467091406762219, "casopis sifra"]
  # [373496142743854, "bezpolitickekorektnosti"]

sql = mysql.createConnection do
  user: \root
  database: \tst
# <~ sql.query "truncate table `fb-likes-2`"
# sources.length = 2

api = "https://graph.facebook.com/v2.8"
saveReaction = (userId, pageId, postId, type, cb) ->
  (err) <~ sql.query "INSERT INTO `fb-likes-2` VALUES (#userId, #pageId, #postId, '#type')"
  console.log err if err
  cb!
userLimit = 10000
<~ async.mapSeries sources, ([pageId, name], cb) ->
  process.stdout.write "\n --- Starting #name ---- \n"
  counter = 0
  address = api + "/#{pageId}/feed?fields=reactions&limit=100&access_token=#{accessToken}"
  uniqueUsers = {}
  <~ async.doWhilst do
    (cb) ->
      counter++
      uniqueUserCount = Object.keys uniqueUsers .length
      process.stdout.write "\n#name, page #counter. Current users #uniqueUserCount\n"
      (err, response, body) <~ request.get {url: address, encoding: null}
      address := null
      res = JSON.parse body
      withReactions = res.data.filter -> it.reactions
      reactions = []
      <~ async.eachSeries withReactions, (post, cb) ->
        [pageId, postId] = post.id.split "_"
        reactions = post.reactions
        <~ async.each reactions.data, (reaction, cb) ->
          userId = reaction.id
          type = reaction.type
          uniqueUsers[userId] = 1
          saveReaction userId, pageId, postId, type, cb
        <~ async.whilst do
          -> reactions.paging?next and ((userLimit > Object.keys uniqueUsers .length) || counter <= 2)
          (cb) ->
            process.stdout.write " - #{Object.keys uniqueUsers .length}"
            address = reactions.paging.next.replace "&limit=25" "&limit=100"
            (err, res, body) <~ request.get {url: address, encoding: null}
            reactions := JSON.parse body
            <~ async.each reactions.data, (reaction, cb) ->
              userId = reaction.id
              type = reaction.type
              uniqueUsers[userId] = 1
              saveReaction userId, pageId, postId, type, cb
            cb!
        cb!
      # console.log res.paging.next
      uniqueUserCount = Object.keys uniqueUsers .length
      console.log "\nCall count: ", (JSON.parse that .call_count) if response.headers['x-app-usage']
      if res.paging?next and (counter < 20 && (uniqueUserCount < userLimit || counter < 2))
        address := res.paging.next
      cb!
    -> address isnt null
  cb!
console.log "Done."
sql.end!
