class ig.Drawing
  (@container, @categories, @tags, @tweets, @tagTweets) ->
    @virtualMouseY = Math.floor window.innerHeight * 0.5
    @containerOffset = ig.utils.getOffset @container.node!
    @prepareTagTweets!
    @setEvents!
    @drawBarcharts!
    @drawBarchartIntermezzo!
    @drawVerticalChart!


  setEvents: ->
    lastResize = Date.now!
    resizeTimeout = null
    resize = ~>
      lastResize := Date.now!
      resizeTimeout := null
      @resize!


    window.addEventListener \resize ~>
      now = Date.now!
      return if resizeTimeout
      if now - lastResize > 200
        @resize!
      else
        resizeTimeout := setTimeout @~resize, (300 - (now - lastResize))
    window.addEventListener \mousemove (evt) ~>
      @setVirtualMousePosition evt.clientY
    window.addEventListener \touchstart (evt) ~>
      @setVirtualMousePosition evt.clientY
    window.addEventListener \scroll @~onScroll

  setVirtualMousePosition: (@virtualMouseY) ->
    @onScroll!

  onScroll: ->
    @scrollTop = window.document.body.scrollTop + @virtualMouseY - @containerOffset.top
    desiredActivity = if @scrollTop < @verticalChartOffset.top
      "bar"
    else
      "vertical"
    @ensureActive desiredActivity
    if @currentlyActive is "vertical"
      @updateVerticalChartDisplay!

  resize: ->
    for tag in @tags
      tag.recalculatePosition!
    @updateTagTweets!
    @verticalChartOffset = ig.utils.getOffsetRelative @verticalChartElement.node!, @container.node!
    @containerOffset = ig.utils.getOffset @container.node!

  prepareTagTweets: ->
    @tagTweetsContainer = @container.append \div
      ..attr \class \tag-tweets

  updateTagTweets: ->
    activeTagTweets = @tagTweets.filter -> it.used
    @tagTweetElements = @tagTweetsContainer.selectAll \div.tweet.active .data activeTagTweets, (.tagTweetId)
      ..enter!append \div
        ..attr \class "tweet active"
      ..exit!
        ..attr \class "tweet"
        ..style \transform -> "translate(-200px, #{it.y + 300 * (Math.random! - 0.5)}px)"
        ..transition!
          ..duration 800
          ..remove!
      ..style \transform -> "translate(#{it.x}px, #{it.y}px)"


  clearTagTweetUse: ->
    for tagTweet in @tagTweets
      tagTweet.used = no

  drawVerticalChart: ->
    @mainTagTweets = @tagTweets.filter -> it.isMain
    tweetSize = @tags.0.tweetSize
    @verticalChartElement = @container.append \div
      ..attr \class \vertical-chart
      ..style \height "#{@mainTagTweets.length * tweetSize}px"
      # ..on \mouseover ~> @ensureActive \vertical
      # ..on \touchstart ~> @ensureActive \vertical
    @verticalChartOffset = ig.utils.getOffsetRelative @verticalChartElement.node!, @container.node!

  updateVerticalChartDisplay: ->
    relativeTop = @scrollTop - @containerOffset.top + @virtualMouseY
    # console.log relativeTop
    for tweet in @mainTagTweets
      if tweet.y < relativeTop
        break
    # console.log tweet.tweet.text
    @tagTweetElements


  ensureActive: (target) ->
    return if target is @currentlyActive
    @setActivity target

  setActivity: (target) ->
    if target == "vertical"
      tweetSize = @tags.0.tweetSize
      count = 0
      for tagTweet in @tagTweets
        if tagTweet.isMain
          tagTweet.x = @verticalChartOffset.left
          tagTweet.y = @verticalChartOffset.top + count * tweetSize
          tagTweet.used = true
          count++
        else
          tagTweet.used = no
    else
      self = @
      @barChartActiveAreas.each (tag) ->
        tag.setParentElementBar @, self.container.node!
    @currentlyActive = target
    @updateTagTweets!

  drawBarcharts: ->
    element = @container.append \div
      # ..on \mouseover ~> @ensureActive \bar
      # ..on \touchstart ~> @ensureActive \bar
      ..attr \class \bar-charts
      # ..selectAll \div .data tagsToUse .enter!append \div
      #   ..attr \class -> \category
      #   ..append \h3
      #     ..html (.name)
      ..selectAll \div .data @tags .enter!append \div
        ..attr \class \tag
        ..append \h4
          ..html (.name)
        ..append \div
          ..attr \class \tag-area
    @barChartActiveAreas = element.selectAll ".tag-area"
    @setActivity "bar"

  drawBarchartIntermezzo: ->
    @container.append \div
      ..attr \class \intermezzo
      ..append \p
        ..html "Za každým jedním <span class='tweet'></span>čtverečkem stojí jeden tweet. Jedna hláška, za kterou byl placen daňovými polatníky. Podívejte se, co za vaše peníze všechno vytvořil…"
