require! {
  "rss-parser": rss
  async
  fb: FB
  fs
  request
  mysql
}
accessToken = "EAACEdEose0cBAIPWZANyii6ZB3DyZBpHHRWuZB3LJv4EU8oTQeXJA1O9WewdY2ux4goZC0EZCpZC5MM1YMZCuYhjlfU7MZBlQwvpG6xCX36x2L9SRXXnTciDdGRjTZBmkMpn4dcmTPT3rts4glGMbVZB0u7aV7M9SpDdwFRx2toyaHx7gZDZD"

sql = mysql.createConnection do
  user: \root
  database: \tst
<~ sql.query "SET NAMES utf8"

(err, data) <~ sql.query '''SELECT id FROM `fb-pages-2` WHERE is_news=1'''
api = "https://graph.facebook.com/v2.8"
console.log err if err
counter = 0
# posts.length = 1
<~ async.eachSeries data, ({id}, cb) ->
  counter++
  address = api + "/#{id}?fields=name&access_token=#{accessToken}"
  (err, response, body) <~ request.get {url: address, encoding: null}
  console.log err if err
  res = JSON.parse body
  console.log "#{counter} / #{data.length}"
  {name} = res
  (err) <~ sql.query "UPDATE `fb-pages-2` SET ? WHERE id=#{id}", {name}
  console.log err if err
  cb!
sql.end!
