ig.drawPages = (c) ->
  container = d3.select c
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
  parties.sort (a, b) ->
    isA = if 0 <= antisys.indexOf a.name then 1 else 0
    isB = if 0 <= antisys.indexOf b.name then 1 else 0
    if isA - isB
      that
    else if a.name > b.name
      1
    else
      -1
  defaults =
    left: partiesAssoc["TOP09"]
    right: partiesAssoc["Úsvit"]
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
  drawJoins = ->
    return unless sides.0 and sides.1
    assoc = {}
    arr = []
    for page, index in sides.0.pages
      leftIndex = index
      rightIndex = 21
      for rightPage, index in sides.1.pages
        if rightPage.page is page.page
          rightIndex = index
          break
      continue if rightIndex is 21

      p = {page, leftIndex, rightIndex, path: [leftIndex, leftIndex, rightIndex, rightIndex]}
      assoc[page] = p
      arr.push p
    svg.selectAll \path .data arr, (.page.page)
      ..exit!remove!
      ..enter!append \path
      ..transition!
        ..duration 400
        ..attr \d -> path it.path
  topContainer = container.append \div
    ..attr \class \top-container
  bottomContainer = container.append \div
    ..attr \class \bottom-container
  for let part, index in <[left right]>
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
        ..attr \height lineHeight * partiesAssoc["TOP09"].pages.length
    selectParty = (party) ->
      sides[index] = party
      selectorItems.classed \active -> it is party
      data = party.pages
      id = (d, i) -> d.page
      max = data.0.user_count
      content.selectAll \.page .data data, id
        ..exit!remove!
        ..enter!append \div
          ..attr \class \page
          ..append \div
            ..attr \class \label
        ..style \width -> "#{it.user_count / max * 50}%"
        ..style \top (d, i) -> "#{lineHeight * i}px"
        ..select \.label
          ..html (d, i) -> "#{i + 1}. #{d.page}"
      drawJoins!

    selectorItems = selector.selectAll \li .data parties .enter!append \li
      ..classed \antisys -> it.name in antisys
      ..append \a
        ..html (.name)
        ..attr \title -> ig.strany[it.name]
        ..attr \href \#
        ..on \click ->
          d3.event.preventDefault!
          selectParty it
    selectParty defaults[part]
