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
  console.log partiesAssoc
  defaults =
    left: partiesAssoc["TOP09"]
    right: partiesAssoc["Úsvit"]

  for let part in <[left right]>
    pages = container.append \div
      ..attr \class "feed pages " + part
    selector = pages.append \ul
      ..attr \class \selector
    content = pages.append \div
      ..attr \class \content
    selectParty = (party) ->
      selectorItems.classed \active -> it is party
      data = party.pages
      id = (d, i) -> d.page
      max = data.0.user_count
      lineHeight = 26
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

    selectorItems = selector.selectAll \li .data parties .enter!append \li
      ..append \a
        ..html (.name)
        ..attr \href \#
        ..on \click ->
          d3.event.preventDefault!
          selectParty it
    selectParty defaults[part]
