require! fs
data = fs.readFileSync "#__dirname/../data/tweety.tsv"
  .toString!
  .split "\r\n"
  .filter -> it.length
  .slice 1
  .map (.split "\t")
  .filter -> it.3
  .map ->
    it.0 .= replace 'https://twitter.com/PREZIDENTmluvci/status/' ''
    it.1 = new Date it.1 .getTime!
    it.5 .= replace /, /g ","
    [it.0, it.1, it.2, it.5].join "\t"
data.unshift "id\ttime\ttext\ttags"
data .= join "\n"

fs.writeFileSync "#__dirname/../data/tweety_clean.tsv", data
