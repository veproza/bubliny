ig.drawYou = (e, pageList, distances, distancesAssoc) ->
  pages = pageList.map ({page, address}) -> {page, address, user_count:0}
  container = d3.select e
  pagesDone = 0
  userParty =
    antisys: no
    name: "Vámi sdílené stránky"
    isUser: yes
    pages: []
  userDistancesAssoc = {}
  parties = ig.getPagesData!
  nonUserParties = parties.slice!
  parties.unshift userParty
  barchart = null
  computingNote = null
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
    distanceExtent = d3.extent pd.map (.distance)
    normalExtent = [72, 634]
    scale = (normalExtent.1 - normalExtent.0) / (distanceExtent.1 - distanceExtent.0)
    for {name, distance} in pd
      normalizedDistance = ((distance - distanceExtent.0) * scale) + normalExtent.0
      if userDistancesAssoc[name] is void
        userDistancesAssoc[name] = {party1: "Vy", party2: name, score: 0}
        distances.push userDistancesAssoc[name]
      userDistancesAssoc[name].score = normalizedDistance
    parties.sort (a, b) ->
      if a.user_distance - b.user_distance
        that
      else if a.name > b.name
        1
      else
        -1
    nonUserParties.sort (a, b) ->
      if a.user_distance - b.user_distance
        that
      else if a.name > b.name
        1
      else
        -1
    pd.sort (a, b) ->
      if a.distance - b.distance
        that
      else if a.name > b.name
        1
      else
        -1
    for {name}, index in pd
      distancesAssoc["#{name}-#{userParty.name}"] = (index + 1) + "."
      distancesAssoc["#{userParty.name}-#{name}"] = (index + 1) + "."
    if pagesToDisplay.length
      initBarchart! if not barchart
      computingNote.html "Chviličku strpení, než to spočítáme. Zatím to vypadá, že nejblíž vám je <b>#{nonUserParties[0].name}</b>, následovaný <b>#{nonUserParties[1].name}</b> a&nbsp;<b>#{nonUserParties[2].name}</b>. Naopak nejdál vám je uskupení <b>#{nonUserParties[*-1].name}</b>.<br><div class='spinner'></div>"
      barchart.update!
      barchart.selectParty 0, userParty
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
      pageUrl = encodeURI "https://www.lidovky.cz/bubliny.aspx?game"
      imageUrl = encodeURI "https://1gr.cz/fotky/lidovky/16/113/lnorg/MSK67a421_socimg.jpg"
      name = encodeURI "Otestujte si svou sociální bublinu"
      description = encodeURI "Vyzkoušejte si, jaká strana je nejbližší vašemu chování na Facebooku. Unikátní projekt serveru Lidovky.cz."
      caption = encodeURI "Lidovky.cz"
      if computingNote.html!
        drawForce!
        computingNote.html "Hotovo! Vaše příspěvky se nejvíc shodují s lidmi, kteří sledují <b>#{nonUserParties[0].name}</b>, <b>#{nonUserParties[1].name}</b> nebo <b>#{nonUserParties[2].name}</b>. Naopak nejdál vám je uskupení <b>#{nonUserParties[*-1].name}</b>.<br><span class='dismiss-btn btn'>Podrobné výsledky</span>"
      else
        computingNote.remove!
      container.append \div
        ..attr \class \final-buttons
        ..append \a
          ..attr \class "btn btn-share"
          ..attr \href "https://www.facebook.com/v2.2/dialog/feed?app_id=1808244062726682&name=#{name}&description=#description&caption=#caption&display=popup&href=#{pageUrl}&picture=#{imageUrl}&link=#{pageUrl}&redirect_uri=#{pageUrl}&ref=click_share&sdk=joey&version=v2.2"
          ..html "Sdílet výsledek"
          ..on \click ->
            d3.event.preventDefault!
            window.open @href, "_blank", "width=560, height=300"
        ..append \a
          ..attr \target \_blank
          ..attr \class "btn btn-link-full"
          ..attr \href "http://lidovky.cz/bubliny.aspx"
          ..html "Přečtěte si celou analýzu sociálních bublin"

  initBarchart = ->
    graphContainer = container.append \div
      ..attr \class "ig pages-container"
    computingNote := container.append \a
      ..attr \class "computing-note"
      ..attr \href \#
      ..on \click ->
        d3.event.preventDefault!
        computingNote.classed \exiting yes
        <~ setTimeout _, 600
        computingNote.remove!
    barchart := ig.drawBarchart graphContainer, parties, distancesAssoc, {left: userParty, right: parties.1}
    graphContainer.select ".agreement .label" .html "nejbližší"

  drawForce = ->
    forceContainer = container.append \div
      ..attr \class "ig force-container force"
    forceContainer.append \h3
      ..html "Vaše poloha v českém politickém spektru"
    ig.drawForce forceContainer.node!, distances

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
        ..attr \class "btn login-button"
        ..html "Přihlaste se svým Facebook účtem"
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
