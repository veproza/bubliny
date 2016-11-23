window.ig =
  projectName : "red-feed-blue-feed"
  containers: {}

containers = document.querySelectorAll '.ig'
if not containers.length
  document.body.className += ' ig'
  window.ig.containers.base = document.body
else
  for container in containers
    window.ig.containers[container.getAttribute 'data-ig'] = container

if d3?
  if document.getElementById 'fallback'
    that.parentNode.removeChild that
