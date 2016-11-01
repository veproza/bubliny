class ig.Drawing
  (@container, @categories, @tags, @tweets, @tagTweets) ->
    @prepareTagTweets!
    @setResizeEvent!
    @drawBarcharts!
    @drawBarchartIntermezzo!


  setResizeEvent: ->
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

  resize: ->
    for tag in @tags
      tag.recalculatePosition!
    @updateTagTweets!

  prepareTagTweets: ->
    @tagTweetsContainer = @container.append \div
      ..attr \class \tag-tweets

  updateTagTweets: ->
    activeTagTweets = @tagTweets.filter -> it.used
    @tagTweetsContainer.selectAll \div .data activeTagTweets, (.tagTweetId)
      ..enter!append \div
        ..attr \class \tweet
      ..exit!
        ..remove!
      ..style \transform -> "translate(#{it.x}px, #{it.y}px)"

  clearTagTweetUse: ->
    for tagTweet in @tagTweets
      tagTweet.used = no


  drawBarcharts: ->
    self = @
    element = @container.append \div
      ..attr \class \bar-charts
      ..selectAll \div .data @categories .enter!append \div
        ..attr \class -> \category
        ..append \h3
          ..html (.name)
        ..selectAll \div .data (.tags) .enter!append \div
          ..attr \class \tag
          ..append \h4
            ..html (.name)
          ..append \div
            ..attr \class \tag-area
            ..each (tag) ->
              tag.setParentElement @, self.container.node!
    @updateTagTweets!

  drawBarchartIntermezzo: ->
