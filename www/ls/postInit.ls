if ig.data.style
  style = document.createElement 'style'
      ..innerHTML = ig.data.style
  document.getElementsByTagName 'head' .0.appendChild style
