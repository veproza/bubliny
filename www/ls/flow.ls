ig.drawFlow = (c) ->
  container = d3.select c
  data = d3.tsv.parse ig.data.pages, (row) ->
    row.user_count = parseInt row.user_count
    row


  partiesAssoc = {}
  for datum in data
    if not partiesAssoc[datum.party]
      partiesAssoc[datum.party] = {name: datum.party, pages: [], pagesFull: []}
    partiesAssoc[datum.party].pagesFull.push datum
    partiesAssoc[datum.party].pages.push datum.page

  mediaAssoc = {}

  parties = <[TOP09 ODS ANO ČSSD BPI KSČM ND]>.map (party, partyIndex) ->
    data = partiesAssoc[party]
    media = <[iDNES.cz DVTV ČT24 ParlamentníListy.cz Protiproud]>.map (medium) ->
      index = data.pages.indexOf medium
      if index == -1 then index = 20
      mediaAssoc[medium] ?= []
      mediaAssoc[medium][partyIndex] = index
      {medium, index}
    {index: partyIndex, party, data, media, mediaAssoc}
  media = for name, data of mediaAssoc => {name, data}

  width = 1000
  height = 400
  x = (index, offset) ->
    offsetDir = if offset % 2 then 6 else -6
    ((index / (parties.length - 1)) * width) - ((offset || 0) * offsetDir)
  y = (index) -> (index / 20) * height
  line = d3.svg.line!
    ..x ->
      x it.index, it.offset
    ..y -> y it.value
  mediaColors =
    "iDNES.cz": \#e41a1c
    "DVTV": \#377eb8
    "ČT24": \#984ea3
    "ParlamentníListy.cz": \#4daf4a
    "Protiproud": \#a65628
  interpolationBiggestStep = 0
  for {data} in media
    for i in [1 til data.length]
      diff = Math.abs data[i] - data[i - 1]
      interpolationBiggestStep = diff if diff > interpolationBiggestStep

  interpolationMethod = 2
  existingPoints = {}
  interpolateLine = (input) ->
    out = []
    # out.push {index: -1, value: input.0}
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


  container.append \svg
    ..attr {width: width + 100, height: height + 100}
    ..append \g
      ..attr \class \drawing
      ..attr \transform "translate(50, 50)"
      ..append \g
        ..attr \class \parties
        ..selectAll \g.party .data parties .enter!.append \g
          ..attr \class \party
          ..attr \transform ({index}) -> "translate(#{x index}, 0)"
          ..append \rect
            ..attr \width 2
            ..attr \y 0
            ..attr \height height
          ..append \text
            ..attr \y -10
            ..attr \text-anchor \middle
            ..text (.party)
      ..append \g
        ..attr \class \lines
        ..selectAll \g.line .data media .enter!append \g
          ..attr \class \line
            ..append \path
              ..attr \class \back
              ..attr \d -> line it.interpolated
            ..append \path
              ..attr \class \fore
              ..attr \stroke -> mediaColors[it.name] || \#000
              ..attr \d -> line it.interpolated



