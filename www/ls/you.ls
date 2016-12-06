
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
    # pagesToDisplay = [{"page":"zpravy.rozhlas.cz","address":"rozhlas.cz/zpravy","user_count":15},{"page":"Hospodářské noviny","address":"ihned.cz","user_count":8},{"page":"lidovky.cz","address":"lidovky.cz","user_count":8},{"page":"iDNES.cz","address":"idnes.cz","user_count":7},{"page":"HlídacíPes.org","address":"hlidacipes.org","user_count":1},{"page":"Týdeník Respekt","address":"respekt.cz","user_count":1},{"page":"ČT24","address":"ceskatelevize.cz","user_count":1},{"page":"Aktuálně.cz","address":"aktualne.cz","user_count":1},{"page":"Týden","address":"tyden.cz","user_count":1},{"page":"Deník.cz","address":"denik.cz","user_count":1},{"page":"Novinky.cz","address":"novinky.cz","user_count":1},{"page":"Časopis Reflex","address":"reflex.cz","user_count":1}]

    userParty.pages.length = 0
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
    if pagesDone < 20
      askMore that if data?paging?next
  # updateView!
  # return
  getFirstBatch = ->
    graphContainer = container.append \div
      ..attr \class "ig pages-container"
    (data) <~ FB.api '/me/posts/?fields=link'
    barchart := ig.drawBarchart graphContainer, parties, distancesAssoc, {left: parties.0, right: parties.1}
    graphContainer.select ".agreement .label" .html "nejbližší"
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
