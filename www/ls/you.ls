
ig.drawYou = (e, pageList, distancesAssoc) ->
  pages = pageList.map ({page, address}) -> {page, address, user_count:0}
  container = d3.select e
  pagesDone = 0

  graphContainer = container.append \div
    ..attr \class "ig pages-container"
  userParty =
    antisys: no
    name: "Vámi sledované stránky"
    isUser: yes
    pages: []
  parties = ig.getPagesData!
  nonUserParties = parties.slice!
  parties.unshift userParty
  barchart = ig.drawBarchart graphContainer, parties, distancesAssoc, {left: parties.0, right: parties.1}

  updateView = ->
    pagesToDisplay = pages
      .filter (.user_count)
      .sort (a, b) -> b.user_count - a.user_count

    userParty.pages.length = 0
    pageNames = []
    for page in pagesToDisplay
      pageNames.push page.page
      userParty.pages.push page
    barchart.update!

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
    if pagesDone < 10
      askMore that if data?paging?next
  window.fbAsyncInit = ->
    FB.init do
      appId : '1808244062726682',
      xfbml : true,
      version : 'v2.8'
    (res) <~ FB.getLoginStatus
    if res.status !== \connected
      button = container.append \a
        ..attr \class \login-button
        ..html "Přihlásit do FB"
        ..attr \href \#
        ..on \click ->
          d3.event.preventDefault!
          FB.login do
            ->
            {scope: 'user_posts'}
    else
      console.log "Asking..."
      (data) <~ FB.api '/me/posts/?fields=link'
      processData data
