tags = []
tagsAssoc = {}
getTag = (str) ->
  if tagsAssoc[str]
    tag = that
  else
    tag = new Tag str
    tags.push tag
    tagsAssoc[str] = tag
  tag

tagTweets = []
lastTagTweetId = 0

ig.getTags = -> tags
ig.getTagTweets = -> tagTweets
tweetSize = x: 9, y: 9
class Tag
  (@str) ->
    @tweets = []
    @tweetCount = 0

  addTweet: (tweet, isMain) ->
    tagTweetId = ++lastTagTweetId
    tagTweet = {tweet, isMain, tagTweetId}
    @tweets.push tagTweet
    tagTweets.push tagTweet
    @tweetCount++

  setParentElement: (@element, @container) ->
    @recalculatePosition!

  recalculatePosition: ->
    return unless @element
    offset = getOffset @element, @container
    width = @element.offsetWidth
    height = @element.offsetHeight
    maxX = offset.left + width - tweetSize.x
    x = offset.left
    y = offset.top + height - tweetSize.y
    numCols = Math.floor width / tweetSize.x
    numRows = Math.ceil @tweetCount / numCols
    lastRowCount = @tweetCount % numCols
    if numRows == 1 && numCols != lastRowCount
      lastRowOffset = tweetSize.x * 0.5 * (numCols - lastRowCount)
      x += lastRowOffset
    for tweet in @tweets
      tweet.x = x
      tweet.y = y
      tweet.used = true
      x += tweetSize.x
      if x > maxX
        x = offset.left
        y -= tweetSize.y
        #   x += 4
          # console.log lastRowOffset
    # console.log rowCount, numRows, lastRowCount

getOffset = (element, container) ->
  top = 0
  left = 0
  do
    top += element.offsetTop
    left += element.offsetLeft
    element = element.offsetParent
  while element isnt container
  {top, left}





class Tweet
  (@data) ->
    @date = new Date!
      ..setTime parseInt @data.time, 10
    @tags = for str, index in @data.tags.split ","
      continue unless str
      tag = getTag str
      tag.addTweet @, index == 0
    @text = @data.text

ig.dataParser = (row) ->
  new Tweet row
