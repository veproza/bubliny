
ig.drawYou = (e, pageList, distancesAssoc) ->
  pages = pageList.map ({page, address}) -> {page, address, user_count:0}
  container = d3.select e
  pagesDone = 0
  userParty =
    antisys: no
    name: "Vámi sdílené stránky"
    isUser: yes
    pages: []
  parties = ig.getPagesData!
  nonUserParties = parties.slice!
  parties.unshift userParty
  barchart = null
  updateView = ->
    pagesToDisplay = pages
      .filter (.user_count)
      .sort (a, b) -> b.user_count - a.user_count
    userParty.pages.length = 0
    container.classed \is-empty pagesToDisplay.length == 0
    userPageNames = []
    for page in pagesToDisplay
      userPageNames.push page.page
      userParty.pages.push page

    pd = for party in nonUserParties
      distance = 0
      pageNames = party.pages.map (.page)
      for userPageName, userIndex in userPageNames
        pageIndex = pageNames.indexOf userPageName
        if pageIndex == -1 then pageIndex = 21
        distance += Math.abs userIndex - pageIndex
      name = party.name
      party.user_distance = distance
      {name, distance}
    parties.sort (a, b) -> a.user_distance - b.user_distance
    nonUserParties.sort (a, b) -> a.user_distance - b.user_distance
    pd.sort (a, b) -> a.distance - b.distance
    for {name}, index in pd
      distancesAssoc["#{name}-#{userParty.name}"] = (index + 1) + "."
      distancesAssoc["#{userParty.name}-#{name}"] = (index + 1) + "."
    if pagesToDisplay.length
      initBarchart! if not barchart
      barchart.update!
      barchart.selectParty 1, nonUserParties.0

  askMore = (address) ->
    (err, data) <~ d3.json address
    processData data

  processData = (data) ->
    if data.data
      for datum in data.data
        continue unless datum.link
        domain = datum.link.split "//" .pop! .split "/" .0
        if 0 <= domain.indexOf "rozhlas.cz"
          if (0 <= datum.link.indexOf "rozhlas.cz/zpravy") || domain == "interaktivni.rozhlas.cz"
            domain = "rozhlas.cz/zpravy"
        activePage = null
        for page in pages
          if 0 <= domain.indexOf page.address
            activePage := page
            break
        if activePage
          activePage.user_count++
    updateView!
    ++pagesDone
    if pagesDone < 20 and data?paging?next
      askMore data.paging.next
    else
      container.append \div
        ..attr \class \empty-note
        ..html "<h3>Nic jsme nenašli</h3><p>Nesdílel(a) jste odkaz na žádný námi sledovaný server. Do naší analýzy jste se tedy nedostal(a)."
      container.classed \done yes

  initBarchart = ->
    graphContainer = container.append \div
      ..attr \class "ig pages-container"
    barchart := ig.drawBarchart graphContainer, parties, distancesAssoc, {left: parties.0, right: parties.1}
    graphContainer.select ".agreement .label" .html "nejbližší"
  getFirstBatch = ->
    (data) <~ FB.api '/me/posts/?fields=link'
    processData data

  window.fbAsyncInit = ->
    FB.init do
      appId : '1808244062726682',
      xfbml : true,
      version : 'v2.8'
    (res) <~ FB.getLoginStatus
    if res.status !== \connected
      button = container.append \a
        ..attr \class \login-button
        ..html "Přihlašte se svým Facebook účtem"
        ..attr \href \#
        ..on \click ->
          d3.event.preventDefault!
          FB.login do
            ->
              button.remove!
              getFirstBatch!
            {scope: 'user_posts'}
    else
      getFirstBatch!
