tags = []
tagsAssoc = {}
getTag = (str) ->
  tagsAssoc[str]

tagTweets = []
lastTagTweetId = -1
tagTranslation =
  "herman": "daniel herman"
  "horacek": "michal horacek"
  "ln": "lidove noviny"
  "aktualne": "aktualne.cz"

blacklistedTags =
  "media": 1
  "opozice": 1

categories = []
categoriesAssoc = {}
class Category
  (@name) ->
    @tags = []

  addTag: ->
    @tags.push it

getCategory = (name) ->
  if categoriesAssoc[name] is void
    categoriesAssoc[name] = new Category name
    categories.push categoriesAssoc[name]
  categoriesAssoc[name]

ig.getCategories = -> categories
ig.getTags = -> tags
ig.getTagTweets = -> tagTweets
class Tag
  tweetSize: 9
  (@data) ->
    @str = str = @data.tag
    @name = @data["název"]
    tagsAssoc[str] = @
    tags.push @
    @tweets = []
    @tweetCount = 0
    @category = getCategory @data["kategorie"]
    @category.addTag @

  addTweet: (tweet, isMain) ->
    tagTweetId = ++lastTagTweetId
    category = @category
    tagTweet = {tweet, isMain, tagTweetId, category}
    @tweets.push tagTweet
    tagTweets.push tagTweet
    @tweetCount++

  setParentElementBar: (@element, @container) ->
    @displayType = "bar"
    @recalculatePosition!

  recalculatePosition: ->
    return unless @element
    if @displayType is "bar"
      @recalculatePositionBar!

  recalculatePositionVertical: ->

  recalculatePositionBar: ->
    offset = getOffset @element, @container
    width = @element.offsetWidth
    height = @element.offsetHeight
    maxX = offset.left + width - @tweetSize
    x = offset.left
    y = offset.top + height - @tweetSize
    numCols = Math.floor width / @tweetSize
    numRows = Math.ceil @tweetCount / numCols
    lastRowCount = @tweetCount % numCols
    if numRows == 1 && lastRowCount
      lastRowOffset = @tweetSize * 0.5 * (numCols - lastRowCount)
      x += lastRowOffset
    for tweet in @tweets
      tweet.x = x
      tweet.y = y
      tweet.used = true
      x += @tweetSize
      if x > maxX
        x = offset.left
        y -= @tweetSize

ig.utils.getOffsetRelative = getOffset = (element, container) ->
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
      if blacklistedTags[str]
        continue
      tag = getTag str
      if not tag
        continue
      tag.addTweet @, index == 0
      tag
    @link = "https://twitter.com/PREZIDENTmluvci/status/#{@data.id}"
    @text = @data.text

ig.dataParser = (row) ->
  new Tweet row

ig.tweetParser = (row) ->
  new Tag row
