window.ig =
  projectName : "red-feed-blue-feed"
  containers: {}
if 0 <= window.location.search.indexOf 'game'
  if window.location.protocol == 'http:' and window.location.host != 'localhost'
    window.location = window.location.href.replace 'http://' 'https://'
  document.querySelector 'main.container' .innerHTML = '''  <h1>Otestujte si svou sociální bublinu</h1>
  <h2>Jste systémoví, nebo antisystémoví? Vyzkoušejte si, k jaké straně či hnutí se kloníte na Facebooku</h2>
  <p class='no-delimiter'>Uživatelé Facebooku žijí v <a href="http://www.lidovky.cz/bubliny.aspx" target="_blank">zajetí sociálních bublin</a>. Sdílí články ze stále stejných zdrojů, a to takových, které potvrzují jejich vidění světa. Zkuste jednoduchý test, který prověří, jaká média sdílíte vy. A uvidíte, ke které bublině na největší světové sociální síti patříte.</p>
  <p><em>Vaše data nesbíráme ani jinam neodesíláme, podrobněji vizte sekci <a href="#privacy">Ochrana osobních údajů</a>.</em></p>
  <div class="ig you" data-ig="you"></div>
  <h3 id="privacy">Ochrana osobních údajů</h3>
  <p>Aplikace přistupuje k vašim příspěvkům na síti Facebook. Nestahuje je však na žádný server, pracuje s nimi pouze ve vašem prohlížeči. Přenos probíhá šifrovaně stejným protokolem, jakým přistupujete na samotný web <a href="https://facebook.com">Facebook.com</a>. Poté, co tuto stránku opustíte, váš prohlížeč všechna stažená data vymaže z paměti. Zdrojové kódy této aplikace si můžete prohlédnout v <a href="https://github.com/veproza/bubliny/tree/fb-hra">repozitáři</a>.</p>'''
  document.querySelector 'footer' .innerHTML = "Vydáno 12. prosince 2016<br>
    Autoři: Jakub Zelenka, Tomáš Málek, Marcel Šulek a Štěpán Korčiš<br>
    © 2016 MAFRA, a.s."
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
