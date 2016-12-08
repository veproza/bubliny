ig.drawForce = (c, distances) ->
  container = d3.select c
  width = container.node!offsetWidth
  height = container.node!offsetHeight
  factor = Math.min do
    1
    (Math.min width, height) / 600
  nodes = []
  links = []
  nodesAssoc = {}
  window.addEventListener \resize ->
    width := container.node!offsetWidth
    height := container.node!offsetHeight
    svg.attr {width, height}
    force
      ..size [width, height]
  antisys = <[BPI DSSS IvČRN ND SPD Úsvit]>
  for distance in distances
    if nodesAssoc[distance.party1] is void
      nodesAssoc[distance.party1] = {name: distance.party1}
      nodes.push nodesAssoc[distance.party1]
    if nodesAssoc[distance.party2] is void
      nodesAssoc[distance.party2] = {name: distance.party2}
      nodes.push nodesAssoc[distance.party2]
    links.push {source: nodesAssoc[distance.party1], target: nodesAssoc[distance.party2], value: distance.score}

  force = d3.layout.force!
    ..gravity 0.05
    ..distance -> it.value * factor
    ..charge -100
    ..size [width, height]
    ..nodes nodes
    ..links links
    ..start!
  svg = container.append \svg
    ..attr {width, height}
  link = svg.selectAll \.link .data links .enter!append \line
    ..attr \class \link
  node = svg.selectAll \.node .data nodes .enter!append \g
    ..attr \class \node
    ..classed \antisys -> it.name in antisys
    ..classed \you -> it.name == "Vy"
    ..call force.drag
    ..append \circle
      ..attr \r 8
    ..append \text
      ..text (.name)
      ..attr \x 12
  force.on \tick ->
    link
      ..attr \x1 -> it.source.x
      ..attr \y1 -> it.source.y
      ..attr \x2 -> it.target.x
      ..attr \y2 -> it.target.y
    node.attr \transform -> "translate(#{it.x},#{it.y})"
