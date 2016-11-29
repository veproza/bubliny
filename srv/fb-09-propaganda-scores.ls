require! {
  "rss-parser": rss
  async
  fb: FB
  fs
  request
  mysql
}
sql = mysql.createConnection do
  user: \root
  database: \tst

(err, data) <~ sql.query """select user_id, count(user_id) as activity, (avg(is_propaganda) * 100) as propaganda, (avg(is_commercial) * 100) as comm
  FROM `fb-likes-2` JOIN `fb-pages-2` ON (page_id = id and is_news = 1)
  WHERE user_id IN (SELECT user_id FROM `fb-page-users` WHERE page_id = 43855944703)
  GROUP BY user_id"""
console.log err if err
data .= map (-> it.user_id + "\t" + it.activity + "\t" + it.propaganda + "\t" + it.comm)
# data.unshift "user_id\tactivity\tpropaganda\tcomm"

fs.writeFileSync do
  "#__dirname/../data/fb-propaganda-score-43855944703.tsv"
  data.join "\n"

sql.end!
