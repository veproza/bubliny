top = document.querySelector 'header'
updateTopClass = (scrollTop) ->
  top.className = if scrollTop > 0 then "" else "top"

updateScroll = (scrollTop) ->
  updateTopClass scrollTop

updateScroll document.body.scrollTop
window.addEventListener "scroll" -> updateScroll document.body.scrollTop
tweets = d3.tsv.parse ig.data.tweety, ig.dataParser

tagTweets = ig.getTagTweets!
tags = ig.getTags!
tags.sort (a, b) -> b.tweetCount - a.tweetCount

new ig.Drawing do
  d3.select ig.containers.drawing
  tags
  tweets
  tagTweets
