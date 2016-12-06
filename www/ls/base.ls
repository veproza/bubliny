distances = d3.tsv.parse ig.data.distances
distancesAssoc = {}
for distance in distances
  distance.score = parseInt distance.score, 10
  distancesAssoc["#{distance.party1}-#{distance.party2}"] = distance.score
  distancesAssoc["#{distance.party2}-#{distance.party1}"] = distance.score

# ig.drawFlow that if ig.containers.flow
# ig.drawFeed that if ig.containers.feed
# ig.drawForce that, distances if ig.containers.force
# ig.drawPages that, distancesAssoc if ig.containers.pages
# ig.drawPages that, distancesAssoc if ig.containers.pages_filtered
ig.drawYou that, ig.pageList, distancesAssoc if ig.containers.you
