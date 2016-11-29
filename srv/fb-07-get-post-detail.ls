require! {
  "rss-parser": rss
  async
  fb: FB
  fs
  request
  mysql
}
accessToken = "EAACEdEose0cBAHZCpxS8dEdZB6jOEhNpj2q0lRZCA87cVpW7wU6ryOfxWwvk9PO9x3hy7oYcbfKoVZCLH1VgTNtr0U3hIy4x0uNNuN0gOQ7WCo0DcvqHk6pFkuknwunwp46IWQlxPMtjy0Hp3wsLfVH8KfKSgkk6lZAt62PnOAgZDZD"

sql = mysql.createConnection do
  user: \root
  database: \tst
<~ sql.query "SET NAMES utf8"
# <~ sql.query "truncate table `top-links`"
(err, data) <~ sql.query '''SELECT concat(page_id, '_', post_id) AS fullPostId FROM `fb-posts` WHERE name='' '''
api = "https://graph.facebook.com/v2.8"
console.log err if err

counter = 0
# posts.length = 1
<~ async.eachSeries data, ({fullPostId}, cb) ->
  counter++
  [page_id, post_id] = fullPostId.split "_"
  address = api + "/#{fullPostId}?fields=id,name,message,description,caption,link,created_time,full_picture&access_token=#{accessToken}"
  (err, response, body) <~ request.get {url: address, encoding: null}
  console.log err if err
  res = JSON.parse body
  console.log "#{counter} / #{data.length}"
  {name,message,description,caption,link,created_time,full_picture} = res
  (err) <~ sql.query "UPDATE `fb-posts` SET ? WHERE page_id=#{page_id} AND post_id=#{post_id}", {name, message, description, caption, link, created_time,full_picture}
  console.log err if err
  cb!
sql.end!
