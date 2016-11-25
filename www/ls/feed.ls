ig.drawFeed = (c) ->
  container = d3.select c
  data = d3.tsv.parse ig.data.posts
  partiesAssoc = {}
  for datum in data
    datum.id = datum.page_id + "_" + datum.post_id
    if not partiesAssoc[datum.party]
      partiesAssoc[datum.party] = {name: datum.party, posts: []}
    partiesAssoc[datum.party].posts.push datum
  parties = for party, data of partiesAssoc => data
  antisys = <[BPI DSSS IvČRN KSČM ND SPD SPO Svob. Úsvit]>
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

  for let part in <[left right]>
    feed = container.append \div
      ..attr \class "feed " + part
    selector = feed.append \ul
      ..attr \class \selector
    content = feed.append \div
      ..attr \class \content
    selectParty = (party, limit = 5) ->
      return unless feed.node!offsetWidth
      selectorItems.classed \active -> it is party
      data = party.posts.slice 0, limit
      content.selectAll \.more .remove!
      id = (d, i) -> d.id + "_" + i
      content.selectAll \.fb-post .data data, id
        ..exit!remove!
        ..enter!append \div
          ..attr \data-href -> "https://www.facebook.com/#{it.page_id}/posts/#{it.post_id}"
          ..attr \class \fb-post
      if limit < 40
        content.append \a
          ..attr \class \more
          ..attr \href \#
          ..html "Načíst další"
          ..on \click ->
            d3.event.preventDefault!
            selectParty party, limit + 10
      FB?XFBML.parse!

    selectorItems = selector.selectAll \li .data parties .enter!append \li
      ..append \a
        ..html (.name)
        ..attr \href \#
        ..on \click ->
          d3.event.preventDefault!
          selectParty it
    <~ setTimeout _, 1000
    selectParty defaults[part]
