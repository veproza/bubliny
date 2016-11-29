require! {
  async
  fs
  mysql
}
sql = mysql.createConnection do
  user: \root
  database: \tst
pagesToNames = {}
(err, data) <~ sql.query "SELECT id, name FROM `fb-pages-2`"
data.forEach -> pagesToNames[it.id] = it.name

(err, data) <~ sql.query "SELECT DISTINCT originating_page_id FROM `fb-page-top-pages`"
pages1 = data.map (.['originating_page_id'])
pages2 = data.map (.['originating_page_id'])
distances = []
perPage = {}
(err) <~ async.eachSeries pages1, (pageId, cb) ->
  (err, data) <~ sql.query "SELECT target_page_id FROM `fb-page-top-pages` WHERE originating_page_id=#pageId ORDER BY user_count DESC"
  return cb err if err
  perPage[pageId] = data.map (.['target_page_id'])
  cb!

done = {}
out = []
pages1.forEach (page1, index1) ->
  out[index1] ?= []
  pages2.forEach (page2, index2) ->
    # return if page1 is page2
    distance = 0
    pageId = [page1, page2]
    pageId.sort!
    pageId .= join "-"
    # return if done[pageId]
    perPage[page1].forEach (medium1, medium1Index) ->
      medium2Index = perPage[page2].indexOf medium1
      if medium2Index == -1
        return console.log "Medium not found!"
      distance += Math.abs medium2Index - medium1Index
    done[pagexId] = 1
    out[index1][index2] = distance
    distances.push "#{pagesToNames[page1]}\t#{pagesToNames[page2]}\t#distance"

# console.log distances.join "\n"
console.log out
sql.end!
