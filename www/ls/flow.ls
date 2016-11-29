ig.drawFlow = (c) ->
  container = d3.select c
  data = d3.tsv.parse ig.data.pages, (row) ->
    row.user_count = parseInt row.user_count
    row

  width = 1000
  height = 400
  margin = top: 40 left: 175 right: 25 bottom: 50
  svg = container.append \svg
    ..attr {width: width + margin.left + margin.right, height: height + margin.top + margin.bottom}
  drawing = svg.append \g
    ..attr \transform "translate(#{margin.left}, #{margin.top})"
    ..attr \class \drawing
  partiesG = drawing.append \g
    ..attr \class \parties
  linesG = drawing.append \g
    ..attr \class \lines

  partiesAssoc = {}
  mediaNamesAssoc = {}
  for datum in data
    if not partiesAssoc[datum.party]
      partiesAssoc[datum.party] = {name: datum.party, pages: [], pagesFull: []}
    partiesAssoc[datum.party].pagesFull.push datum
    partiesAssoc[datum.party].pages.push datum.page
    mediaNamesAssoc[datum.page] = 1
  partyNames = for name of partiesAssoc => name
  mediaNames = for name of mediaNamesAssoc => name
  # mediaNames = ["iDNES.cz" "DVTV" "ČT24" "ParlamentníListy.cz" "Protiproud" "Echo24.cz"]
  defaultSelection = <[TOP09 ODS ANO ČSSD BPI KSČM ND]>
  x = (index, offset) ->
    offsetDir = if offset % 2 then 6 else -6
    ((index / (defaultSelection.length - 1)) * width) - ((offset || 0) * offsetDir)
  y = (index) -> (index / 20) * height
  line = d3.svg.line!
    ..x ->
      val = x it.index, it.offset
      if val == width
        val += 2
      else if val == 0
        val = -1
      val
    ..y -> y it.value
  selectors = container.selectAll \select .data [0 til defaultSelection.length] .enter!append \select
    ..style \left -> "#{margin.left + x it}px"
    ..selectAll \option .data partyNames .enter!append \option
      ..html -> it
      ..attr \selected (d, i, ii) ->
        if d is defaultSelection[ii] then "selected" else void
  go = ->
    selectedParties = []
    selectors.each -> selectedParties.push @value
    mediaAssoc = {}
    parties = selectedParties.map (party, partyIndex) ->
      data = partiesAssoc[party]
      media = mediaNames.map (medium) ->
        index = data.pages.indexOf medium
        if index == -1 then index = 20
        mediaAssoc[medium] ?= []
        mediaAssoc[medium][partyIndex] = index
        {medium, index}
      {index: partyIndex, party, data, media, mediaAssoc}
    media = for name, data of mediaAssoc => {name, data}

    mediaColors =
      "iDNES.cz": \#e41a1c
      "DVTV": \#377eb8
      "ČT24": \#984ea3
      "ParlamentníListy.cz": \#4daf4a
      "Protiproud": \#a65628
      "Echo24.cz": \#f781bf
      "lidovky.cz": \#1D4382
    interpolationBiggestStep = 0
    for {data} in media
      for i in [1 til data.length]
        diff = Math.abs data[i] - data[i - 1]
        interpolationBiggestStep = diff if diff > interpolationBiggestStep

    interpolationMethod = 2
    existingPoints = {}
    interpolateLine = (input) ->
      out = []
      out.push {index: 0, value: input.0}
      for i in [1 til input.length]
        diff = input[i] - input[i - 1]
        diffIndex = Math.abs diff / interpolationBiggestStep
        offset = 0
        if interpolationMethod == 1
          startIndex = i - 0.85
          endIndex = i - 0.15
        else if interpolationMethod
          startIndex = i - 0.5 - diffIndex / 2
          endIndex = i - 0.5 + diffIndex / 2
          point1 = [(i - 0.5), (input[i - 1] + input[i]) / 2].join "-"
          if existingPoints[point1]
            offset = existingPoints[point1]
            existingPoints[point1]++
          existingPoints[point1] = 1
        if interpolationMethod
          out.push {index: startIndex, value: input[i - 1], offset}
          out.push {index: endIndex, value: input[i], offset}
        out.push {index: i, value: input[i]}
      out
    for medium in media
      medium.interpolated = interpolateLine medium.data


    partiesG
      ..selectAll \g.party .data parties, (.index)
        ..enter!append \g
          ..attr \class \party
          ..append \rect
            ..attr \width 2
            ..attr \x -1
            ..attr \y 0
            ..attr \height height
          ..append \text
            ..attr \y -19
            ..attr \text-anchor \middle
        ..exit!remove!
        ..attr \transform ({index}) -> "translate(#{x index}, 0)"
        ..select \text
          ..text (.party)
    linesG
      ..selectAll \g.line .data media, (.name)
        ..enter!append \g
          ..append \text
            ..attr \class \name
            ..attr \x -17
            ..attr \text-anchor \end
            ..attr \dy 3
          ..append \path
            ..attr \class "back dimmable"
          ..append \path
            ..attr \class "fore dimmable"
        ..attr \class -> "line #{if mediaColors[it.name] then 'active' else 'passive'}"
        ..select \text
          ..text (.name)
          ..transition!
            ..duration 800
            ..attr \y -> y it.data.0
          ..attr \fill -> mediaColors[it.name] || \#aaa
          ..classed \non-fill -> mediaColors[it.name] is void
          ..classed \dimmable -> it.data.0 >= 20
        ..select \path.back
          ..transition!
            ..duration 800
            ..attr \d -> line it.interpolated
        ..select \path.fore
          ..attr \stroke -> mediaColors[it.name] || \#aaa
          ..transition!
            ..duration 800
            ..attr \d -> line it.interpolated
        ..selectAll \g.point .data (.data)
          ..transition!
            ..duration 800
            ..attr \transform (d, i) -> "translate(#{x i},#{y d})"
          ..enter!append \g
            ..attr \class "point dimmable"
            ..attr \transform (d, i) -> "translate(#{x i},#{y d})"
            ..append \circle
              ..attr \r 11
              ..attr \fill (d, i, ii) -> mediaColors[media[ii].name] || \#aaa
            ..append \text
              ..attr \text-anchor \middle
              ..attr \y 4
          ..select \text
            ..text ->
              if it > 19 then
                "+"
              else
                "#{it + 1}"
  go!
  selectors.on \change go
