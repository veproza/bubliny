data = d3.tsv.parse ig.data.pages, (row) ->
  row.user_count = parseInt row.user_count
  row

partiesAssoc = {}
for datum in data
  if not partiesAssoc[datum.party]
    partiesAssoc[datum.party] = {name: datum.party, pages: []}
  partiesAssoc[datum.party].pages.push datum
parties = for party, data of partiesAssoc => data
antisys = <[BPI DSSS IvČRN ND SPD Úsvit]>
for party in parties
  party.antisys = party.name in antisys
parties.sort (a, b) ->
  isA = if a.antisys then 1 else 0
  isB = if b.antisys then 1 else 0
  if isA - isB
    that
  else if a.name > b.name
    1
  else
    -1

ig.drawPages = (c, distancesAssoc) ->
  container = d3.select c
  defaults =
    left: partiesAssoc["TOP09"]
    right: partiesAssoc["Úsvit"]
  if "pages" is c.getAttribute \data-ig
    defaults =
      left: partiesAssoc["KSČM"]
      right: partiesAssoc["DSSS"]
  barchart container, parties, distancesAssoc, defaults

ig.getPagesData = ->
  parties.slice!

ig.drawBarchart = barchart = (container, parties, distancesAssoc, defaults) ->
  sides = []
  lineHeight = 26
  leftContent = null
  svgWidth = 80
  path = d3.svg.line!
    ..interpolate \monotone
    ..x (d, i) -> switch i
      | 0 => 0
      | 1 => 8
      | 2 => svgWidth - 8
      | 3 => svgWidth
    ..y -> it * lineHeight
  svg = null
  agreement = null
  drawJoins = ->
    return unless sides.0 and sides.1
    assoc = {}
    arr = []
    for pageData, index in sides.0.pages
      {page} = pageData
      leftIndex = index
      rightIndex = 21
      for rightPage, index in sides.1.pages
        if rightPage.page is page
          rightIndex = index
          break
      continue if rightIndex is 21

      p = {page, pageData, leftIndex, rightIndex, path: [leftIndex, leftIndex, rightIndex, rightIndex]}
      assoc[page] = p
      arr.push p
    svg.selectAll \path .data arr, (.page)
      ..exit!remove!
      ..enter!append \path
      ..attr \class \page-highlightable
      ..transition!
        ..duration 400
        ..attr \d -> path it.path
  drawAgreement = ->
    return unless sides.0 and sides.1
    name1 = sides.0.name
    name2 = sides.1.name
    if name1 is name2
      d = 0
    else
      d = distancesAssoc["#{name1}-#{name2}"]
    label =
      | typeof d == "string" => d
      | otherwise
        maxD = 634
        agg = d / maxD
        "#{Math.round agg * 100}"
    agreement.select \.value .html label
  bottomContainer = container.append \div
    ..attr \class \bottom-container
  topContainer = bottomContainer.append \div
    ..attr \class \top-container
  highlightablePages = null
  parts = for let part, index in <[left right]>
    topPages = topContainer.append \div
      ..attr \class "feed pages #part"
    selector = topPages.append \ul
      ..attr \class \selector
    pages = bottomContainer.append \div
      ..attr \class "feed pages #part"
    content = pages.append \div
      ..attr \class \content
    if part == "left"
      svg := content.append \svg
        ..attr \width svgWidth
        ..attr \height lineHeight * parties.1.pages.length
      agreement := topContainer.append \div
        ..attr \class \agreement
        ..append \span
          ..attr \class \value
        ..append \span
          ..attr \class \label
          ..html "vzdálenost"

    highlightMedium = ({page})->
      highlightablePages.classed \active -> it.page is page

    downlightMedium = ->
      highlightablePages.classed \active no

    selectParty = (party) ->
      sides[index] = party
      data = party.pages
      update!
      selectorItems.classed \active -> it is party

    selectorItems = null

    update = ->
      data = sides[index].pages
      selectorItems := selector.selectAll \li .data parties
        ..enter!append \li
          ..append \a
            ..attr \href \#
            ..on \click ->
              d3.event.preventDefault!
              selectParty it
        ..classed \antisys (.antisys)
        ..classed \user-party (.isUser)
        ..select \a
          ..html (.name)
          ..attr \title -> ig.strany[it.name]
      return unless data.0
      max = data.0.user_count
      content.selectAll \.page .data data, (.page)
        ..exit!remove!
        ..enter!append \div
          ..attr \class "page page-highlightable"
          ..append \div
            ..attr \class \label
        ..style \width -> "#{it.user_count / max * 50}%"
        ..style \top (d, i) -> "#{lineHeight * i}px"
        ..select \.label
          ..html (d, i) -> "#{i + 1}. #{d.page}"
        ..on \mouseover highlightMedium
        ..on \mouseout downlightMedium
        ..on \touchstart highlightMedium
      drawJoins!
      drawAgreement!
      highlightablePages := container.selectAll \.page-highlightable
    selectParty defaults[part]
    {update, selectParty}

  update = ->
    for part in parts
      part.update!
  selectParty = (part, party) -> parts[part].selectParty party
  {update, selectParty}
