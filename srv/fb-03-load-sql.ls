require! {
  fs
  mysql
  async
}
sql = mysql.createConnection do
  user: \root
  database: \tst
lines = fs.readFileSync "#__dirname/../data/fb-likes-6.tsv"
  .toString!
  .split "\n"
  .slice 1
  .filter -> it

<~ sql.connect!

i = 0
<~ async.eachSeries lines, (line, cb) ->
  [user_id, id, reaction] = line.split "\t"
  [page_id, post_id] = id.split "_"
  query = "INSERT INTO `fb-likes` VALUES (#user_id, #page_id, #post_id)"
  console.log ++i
  (err) <~ sql.query query
  console.log values, err if err
  cb err

process.exit!
