require! {
  "rss-parser": rss
  async
  fs
  request
  mysql
}
sql = mysql.createConnection do
  user: \root
  database: \tst

(err, data) <~ sql.query """select distinct page_id from `fb-posts`"""
console.log err if err
accessToken = "EAACEdEose0cBABRXjZAkJF5gYsHnluVZA7ExFUZBKf7Vkr9aLCz3mbZBZB445fapBGE3AZCXV4wD6LKDi14WfTMZCWSe8ghBdpr96JjVs2RCjUNyk52UaMOIHkqgEDnPEBAZChMbSR2kkwDqDrquT8ZCyfnfe7zkL9XEiXNZAquZC0K6QZDZD"
api = "https://graph.facebook.com/v2.8"
# data.length = 1
<~ async.eachSeries data, ({page_id}, cb) ->
  address = api + "/#{page_id}/feed/?fields=shares&limit=100&access_token=#{accessToken}"
  counter = 0
  <~ async.doWhilst do
    (cb) ->
      console.log address
      (err, response, body) <~ request.get {url: address, encoding: null}
      console.log err if err
      res = JSON.parse body
      if res.data
        res.data.forEach ->
          [pageId, postId] = it.id.split "_"
          count = (it.shares?count || 0)
          (err) <~ sql.query "UPDATE `fb-posts` set share_count=#count where page_id=#{pageId} and post_id=#{postId} LIMIT 1"
          console.log err if err
      counter++
      address := null
      if counter < 3 and res.paging?next
        address := res.paging.next
      cb!
    -> address
  cb!

sql.end!
