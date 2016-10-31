ig.utils = utils = {}


utils.offset = (element, side) ->
  top = 0
  left = 0
  do
    top += element.offsetTop
    left += element.offsetLeft
  while element = element.offsetParent
  {top, left}


utils.deminifyData = (minified) ->
  out = for row in minified.data
    row_out = {}
    for column, index in minified.columns
      row_out[column] = row[index]
    for column, indices of minified.indices
      row_out[column] = indices[row_out[column]]
    row_out
  out


utils.formatNumber = (input, decimalPoints = 0) ->
  input = parseFloat input
  if decimalPoints
    wholePart = Math.floor input
    decimalPart = Math.abs input % 1
    decimalPart = Math.round decimalPart * Math.pow 10, decimalPoints
    if decimalPart >= Math.pow 10, decimalPoints
      decimalPart -= Math.pow 10, decimalPoints
      wholePart += 1
    wholePart = insertThousandSeparator wholePart
    decimalPart = decimalPart.toString()
    while decimalPart.length < decimalPoints
      decimalPart = "0" + decimalPart
    "#{wholePart},#{decimalPart}"
  else
    wholePart = Math.round input
    insertThousandSeparator wholePart


insertThousandSeparator = (input, separator = ' ') ->
    price = Math.round(input).toString()
    out = []
    len = price.length
    for i in [0 til len]
      out.unshift price[len - i - 1]
      isLast = i is len - 1
      isThirdNumeral = 2 is i % 3
      if isThirdNumeral and not isLast
        out.unshift separator
    out.join ''

utils.divideToParts = (extent, breaks) ->
  for i in [0 til breaks]
    extent.0 + i * ((extent.1 - extent.0) / (breaks - 1))
