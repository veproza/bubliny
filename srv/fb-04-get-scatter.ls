require! {
  mysql
  async
  fs
}

pageNames =
  "0": "-"
  "30575632699": "ods"
  "34825122262": "reflex"
  "39371299263": "sz"
  "43855944703": "svobodni"
  "50309511751": "CRo1"
  "52117071582": "MF Dnes"
  "52479821102": "respekt"
  "53247283454": "hospodarky"
  "88822578037": "lidovky"
  "90002267161": "top09"
  "93433992603": "ihned"
  "100683176313": " idnes"
  "109323929038": " pirati"
  "123858471641": " Zpravy.rozhlas.cz"
  "137067469008": " CT24"
  "137301989386": " aktualne.cz"
  "142069753862": " nova"
  "202451429883": " novinky"
  "206045673805": " denik.cz"
  "111041662264882": "cssd"
  "114811848586566": "tyden"
  "120250914680166": "eurozpravy"
  "135144949863739": "parlace"
  "139079856198676": "prvnizpravy"
  "143886599126215": "protiproud"
  "197466333678437": "delnici"
  "210778132327279": "prima"
  "211401918930049": "ano"
  "213277405366807": "super.cz"
  "231702800367893": "ln"
  "298789466930469": "kscm"
  "363829437158226": "aeronet"
  "482885755074163": "Tydenikpolicie"
  "513697425424894": "IvCRN"
  "526346124083250": "usvit"
pageIds = for pageId of pageNames => pageId
pageIds .= slice 1
sql = mysql.createConnection do
  user: \root
  database: \tst
# pageIds.length = 1
(err, lines) <~ async.mapSeries pageIds, (pageId, cb) ->
  console.log pageId
  query = "SELECT name, page_id, COUNT(page_id) AS p, (COUNT(page_id) / total_unique_users) * 100 AS perc FROM `fb-page-users` JOIN `fb-pages` ON page_id = id WHERE user_id IN (SELECT user_id FROM `fb-likes` WHERE page_id=#{pageId}) GROUP BY page_id ORDER BY page_id ASC"
  (err, data) <~ sql.query query
  assoc = {}
  for datum in data
    assoc[datum.page_id] = if datum.perc == 100
      "-"
    else
      datum.perc.toString!replace "." ","
  line = pageIds.map -> assoc[it] || "0"
  line.unshift pageNames[pageId]
  cb err, line.join "\t"
lines.unshift do
  ((["0"]) ++ pageIds)
    .map (-> pageNames[it])
    .join "\t"
out = lines.join "\n"
fs.writeFileSync "#__dirname/../data/fb-scatter.tsv", out
setTimeout process.exit, 500
