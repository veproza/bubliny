require! {
  async
  fb: FB
  fs
  request
}
accessToken = "EAACEdEose0cBAJBrAeKWekofSyn4RHIskRs6NZBSaTcZBcgTBaCXbfZCxYjKIWRmBvWz2pMER3F24Rpec1zR7ZC7FaR05mIZCvCq6x8b4bZASLIQCxLqZAVnZCc0eFwZBw8i2ki0eoQOzFwjgjclZBegZBTYYJWlPEbo1XUsysYzCuEqwZDZD"
FB.setAccessToken accessToken
FB.options version: 'v2.8'

ids = fs.readFileSync "#__dirname/../data/fb-sources-6.tsv"
  .toString!
  .split "\n"
  .slice 1
  .map -> it.split "\t" .0
start = 0 # ids.indexOf "142069753862_10154310996993863"
ids .= slice start
outFile = fs.createWriteStream "#__dirname/../data/fb-likes-6.tsv", flags: "a"
  # ..write "uid\tid\turl\treaction"
counter = start
async.eachSeries ids, (id, cb) ->
  endpoint = "#{id}/reactions"
  console.log id, ++counter
  <~ async.doWhilst do
    (cb) ->
      process.stdout.write "."
      # console.log endpoint
      (res) <~ FB.api endpoint
      endpoint := null
      for datum in res.data
        outFile.write "#{datum.id}\t#id\t#{datum.type}\n"
      if res.paging?next
        endpointQuery = res.paging.next.split "&limit=" .1
        endpoint := "#{id}/reactions/?limit=" + endpointQuery
      cb!
    -> endpoint isnt null

  cb!
