tags = []
tagsAssoc = {}
getTag = (str) ->
  tagsAssoc[str]

tagTweets = []
lastTagTweetId = 0
tagTranslation =
  "herman": "daniel herman"
  "horacek": "michal horacek"
  "ln": "lidove noviny"
  "aktualne": "aktualne.cz"


ig.getTags = -> tags
ig.getTagTweets = -> tagTweets
tweetSize = x: 9, y: 9
class Tag
  (@data) ->
    @str = str = @data.tag
    @name = @data["název"]
    tagsAssoc[str] = @
    tags.push @
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
    if numRows == 1 && lastRowCount
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
    uniqueTags = {}
    for str, index in @data.tags.split ","
      if tagTranslation[str]
        # console.log str, that, "->" @data.tags
        str = that
      if uniqueTags[str] isnt void
        console.log str, @data.text
      continue unless uniqueTags[str] is void
      uniqueTags[str] = index
    @tags = for str, index of uniqueTags
      continue unless str
      if tagTranslation[str]
        # console.log str, that, "->" @data.tags
        str = that
      tag = getTag str
      if tag
        tag.addTweet @, index == 0
      # else
      #   console.log str, @data.text
    @text = @data.text

ig.dataParser = (row) ->
  new Tweet row

ig.tweetParser = (row) ->
  new Tag row
