top = document.querySelector 'header'
updateTopClass = (scrollTop) ->
  top.className = if scrollTop > 0 then "" else "top"

updateScroll = (scrollTop) ->
  updateTopClass scrollTop

updateScroll document.body.scrollTop
window.addEventListener "scroll" -> updateScroll (window.document.documentElement.scrollTop || window.document.body.scrollTop)

distances = d3.tsv.parse ig.data.distances
distancesAssoc = {}
for distance in distances
  distance.score = parseInt distance.score, 10
  distancesAssoc["#{distance.party1}-#{distance.party2}"] = distance.score
  distancesAssoc["#{distance.party2}-#{distance.party1}"] = distance.score

ig.drawFeed that if ig.containers.feed
ig.drawForce that, distances if ig.containers.force
ig.drawPages that, distancesAssoc if ig.containers.pages
ig.drawPages that, distancesAssoc if ig.containers.pages_filtered
