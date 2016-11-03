top = document.querySelector 'header'
updateTopClass = (scrollTop) ->
  top.className = if scrollTop > 0 then "" else "top"

updateScroll = (scrollTop) ->
  updateTopClass scrollTop

updateScroll document.body.scrollTop
window.addEventListener "scroll" -> updateScroll (window.document.documentElement.scrollTop || window.document.body.scrollTop)
tags = d3.tsv.parse ig.data.tagy, ig.tweetParser
tweets = d3.tsv.parse ig.data.tweety, ig.dataParser
categories = ig.getCategories!
tagTweets = ig.getTagTweets!
tags = ig.getTags!
tags .= filter -> it.tweetCount
for category in categories
  category.tags.sort (a, b) -> b.tweetCount - a.tweetCount
categorySorting =
  "Politika" : 1
  "Společnost" : 2
  "Média" : 3
  "Instituce" : 4
categories.sort (a, b) -> categorySorting[a.name] - categorySorting[b.name]
tags.sort (a, b) -> b.tweetCount - a.tweetCount
new ig.Drawing do
  d3.select ig.containers.drawing
  categories
  tags
  tweets
  tagTweets

