class ig.Drawing
  (@container, @categories, @tags, @tweets, @tagTweets) ->
    @virtualMouseY = Math.floor window.innerHeight * 0.3
    @virtualMouseIsCustom = no
    @containerOffset = ig.utils.getOffset @container.node!
    @prepareTagTweets!
    @setEvents!
    @drawBarcharts!
    @drawBarchartIntermezzo!
    @drawVerticalChart!
    @drawVerticalChartIntermezzo!
    @drawTimeline!
    @setActivity "bar"


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
    window.addEventListener \scroll @~onScroll

  setVirtualMousePosition: (@virtualMouseY) ->
    @virtualMouseIsCustom = yes
    @onScroll!

  onScroll: ->
    @scrollTop = window.document.body.scrollTop + @virtualMouseY - @containerOffset.top
    desiredActivity = if @scrollTop < @verticalChartOffset.top - 100px
      "bar"
    else if @scrollTop < @verticalChartOffset.top + @verticalChartHeight + 100px
      "vertical"
    else
      "timeline"
    @ensureActive desiredActivity
    if @currentlyActive is "vertical"
      @updateVerticalChartDisplay!

  resize: ->
    if not @virtualMouseIsCustom
      @virtualMouseY = Math.floor window.innerHeight * 0.3
    for tag in @tags
      tag.recalculatePosition!
    @updateTagTweets!
    @verticalChartOffset = ig.utils.getOffsetRelative @verticalChartElement.node!, @container.node!
    @verticalChartHeight = @verticalChartElement.node!clientHeight
    @containerOffset = ig.utils.getOffset @container.node!
    @onScroll!

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

  drawTimeline: ->
    texts =
      * date: "duben – květen 2015"
        monthId: 2
        length: 3
        text: "Peroutka, <span class='big-only'>nejmenování profesorů</span><span class='small-only'>profesoři</span>"
      * date: "září – listopad 2015"
        monthId: 7
        length: 3
        text: "Ztohoven, Albertov"
      * date: "březen – duben 2016"
        monthId: 13
        length: 2
        text: "Návštěva čínského prezidenta"
      * date: "říjen 2016"
        monthId: 20
        length: 1
        text: "Řízení letového provozu, Brady, Herman, Peroutka"

    @timelineElement = @container.append \div
      ..attr \class \timeline

    @timelineLabels = @timelineElement.append \div
      ..attr \class \labels
      ..selectAll \div.label .data texts .enter!append \div
        ..attr \class \label
        ..style \left -> "#{it.monthId / 21 * 100}%"
        ..append \span
          ..attr \class \date
          ..html (.date)
        ..append \span
          ..attr \class \text
          ..html (.text)
      ..selectAll \div.line .data texts .enter!append \div
        ..style \left -> "#{(it.monthId - 0.3) / 21 * 100}%"
        ..attr \class \line
        ..style \width -> "#{(it.length) / 21 * 100}%"

  drawVerticalChart: ->
    @mainTagTweets = @tagTweets.filter -> it.isMain
    tweetSize = @tags.0.tweetSize
    @verticalChartElement = @container.append \div
      ..attr \class \vertical-chart
      ..style \height "#{@mainTagTweets.length * tweetSize}px"
    @verticalChartOffset = ig.utils.getOffsetRelative @verticalChartElement.node!, @container.node!
    @verticalChartHeight = @verticalChartElement.node!clientHeight
    @verticalChartDisplayElement = @container.append \a
      ..attr \target \_blank
      ..attr \class \vertical-chart-display
    content =  @verticalChartDisplayElement.append \div
      ..attr \class \content
    @verticalChartDisplayCitationElement = content.append \blockquote
    @verticalChartDisplayTimeElement = content.append \span
      ..attr \class \time
    @verticalChartDisplayTagsElement = content.append \span
      ..attr \class \tags


  updateVerticalChartDisplay: ->
    relativeTop = @scrollTop
    minTop = @verticalChartOffset.top - @tags.0.tweetSize
    maxTop = minTop + @verticalChartHeight - 2
    relativeTop = minTop if relativeTop < minTop
    relativeTop = maxTop if relativeTop >= maxTop
    for tweet in @mainTagTweets
      if tweet.y > relativeTop
        break
    @verticalChartDisplayCitationElement.html tweet.tweet.text
    @verticalChartDisplayTimeElement.html "@PREZIDENTmluvci, #{toHumanDate tweet.tweet.date}"
    tags = for tag in tweet.tweet.tags
      tag.name
    tags .= join ", "
    @verticalChartDisplayTagsElement.html "Otření: #tags"
    @verticalChartDisplayElement.style \top "#{relativeTop}px"
    @verticalChartDisplayElement.attr \href tweet.tweet.link
    @tagTweetElements

  reorderTagtweetsToTimeline: ->
    perMonth = for i in [1 to 21] => 0
    timelineNode = @timelineElement.node!
    timelineOffset = ig.utils.getOffsetRelative timelineNode, @container.node!
    timelineWidth = Math.min 1000, timelineNode.clientWidth
    xSize = timelineWidth / 21
    tweetSize = @tags.0.tweetSize
    cols = if timelineWidth > 378 then 2 else 1
    timelineHeight = 97 * tweetSize / cols
    @timelineLabels.style \top "#{timelineHeight}px"
    @timelineElement.style \height "#{timelineHeight}px"
    for tagTweet in @tagTweets
      if tagTweet.isMain
        tagTweet.used = yes
        monthId = @getMonthId tagTweet
        yOffset = (Math.floor perMonth[monthId] / cols) * tweetSize
        xOffset = monthId * xSize + (perMonth[monthId] % cols * tweetSize)
        tagTweet.x = xOffset
        tagTweet.y = timelineOffset.top + timelineHeight - yOffset - tweetSize
        perMonth[monthId]++
      else
        tagTweet.used = no


  getMonthId: (tagTweet) ->
    year = tagTweet.tweet.date.getFullYear!
    month = tagTweet.tweet.date.getMonth!
    if year == 2015
      month - 1
    else
      11 + month

  ensureActive: (target) ->
    return if target is @currentlyActive
    @setActivity target

  setActivity: (target) ->
    if target == "vertical"
      tweetSize = @tags.0.tweetSize
      count = 0
      @verticalChartDisplayElement.classed \active yes
      for tag in @tags
        tag.displayType = "vertical"
      for tagTweet in @tagTweets
        if tagTweet.isMain
          tagTweet.x = @verticalChartOffset.left
          tagTweet.y = @verticalChartOffset.top + count * tweetSize
          tagTweet.used = true
          count++
        else
          tagTweet.used = no
    else if target == "timeline"
      for tag in @tags
        tag.displayType = "timeline"
      @reorderTagtweetsToTimeline!
      @verticalChartDisplayElement.classed \active no
    else
      self = @
      @barChartActiveAreas.each (tag) ->
        tag.setParentElementBar @, self.container.node!
      @verticalChartDisplayElement.classed \active no
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

  drawBarchartIntermezzo: ->
    @container.append \div
      ..attr \class \intermezzo
      ..append \p
        ..html "Za každým jedním <span class='tweet'></span>čtverečkem stojí jeden tweet. Jedna hláška, za kterou byl placen daňovými polatníky. Podívejte se, co za vaše peníze všechno vytvořil…"

  drawVerticalChartIntermezzo: ->
    @container.append \div
      ..attr \class \intermezzo
      ..append \p
        ..html "A lepší to nebude. Ovčáček si totiž přidává."

months = <[ledna února března dubna května června července srpna září října listopadu prosince]>
toHumanDate = ->
  "#{it.getDate!}. #{months[it.getMonth!]} #{it.getFullYear!}"
