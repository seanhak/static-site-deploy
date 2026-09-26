# Gemensamt för de statiska sajterna

Gäller alla sajter i `README.md`:s tabell (botabra.se, seanhak.com, hemlisar.com, mellandagsrejva.com, lål.com, ñä.com och öø.com). Varje sajts egen CLAUDE.md beskriver bara det som är unikt för den: design, struktur, värden och undantag.

## Kod
- Ren HTML, CSS och JavaScript, utan ramverk och utan build-steg lokalt. Minifieringen sker bara i deployen, så källfilerna får ha kommentarer.
- Styling i `styles.css`, logik i `script.js`. Undvik inline CSS och script i index.html om det inte finns en stark anledning.
- Typsnitt är självhostade som woff2 i `fonts/`, bara latin-delen och bara de vikter som används. Inga länkar till Google Fonts.
- Ingen statistik eller tredjepartsskript. Cloudflare Web Analytics kan slås på i Cloudflare utan kodändring om det behövs.
- Varje sajt har `site.webmanifest`, `robots.txt`, `sitemap.xml`, `llms.txt`, `humans.txt` och `.well-known/security.txt`. Datum och `Expires` i dem är platshållare som stämplas vid deploy.
- Adresser i meta-taggar, sitemap och liknande är absoluta och använder sajtens kanoniska värd (apex, eller www för IDN-domänerna, se nedan).

## Lokal förhandsgranskning
VS Code-tasken "Starta lokal server" (browser-sync med CSS-injicering och omladdning), eller `python3 -m http.server <port>`. Varje sajt har en egen fast port så att alla kan köras samtidigt:

| Sajt | Port |
|---|---|
| botabra.se | 8001 |
| seanhak.com | 8002 |
| hemlisar.com | 8003 |
| mellandagsrejva.com | 8004 |
| lål.com | 8005 |
| ñä.com | 8006 |
| öø.com | 8007 |

En ny sajt får nästa lediga port, i sin `.vscode/tasks.json` och i tabellen här. `/Volumes/SD/git/seanhak/seanhak.code-workspace` öppnar alla repon i ett fönster, med tasks för skripten i static-site-deploy.

## Infrastruktur (samma för alla)
- AWS-konto 568395190971. S3-bucket i eu-north-1 med static website hosting, `index.html` som index- och error-dokument.
- Bucket policyn släpper bara in Cloudflares IP-spann. `scripts/update-bucket-policies.sh` uppdaterar alla.
- Cloudflare (gratisplan) framför: SSL Flexible (S3:s website-endpoint har bara HTTP), Always Use HTTPS, HSTS en månad utan includeSubDomains, Browser Cache TTL "Respect existing headers", en cache-regel (edge TTL en dag, browser TTL **Respect origin**) och en redirect-regel mellan apex och www (301, behåller sökväg och query).
  - Cache-regelns browser TTL får inte vara *Bypass cache*, för då lägger Cloudflare till `no-store` på allt.
- Route 53 är bara registrar: auto-renew och transfer lock på (.se stöder inte transfer lock). DNS ligger i Cloudflare (`ines`/`pete.ns.cloudflare.com`).
- Domäner utan mail har null MX (`.`), `v=spf1 -all` och DMARC `p=reject`. Mailposter ska alltid vara DNS only (grå moln).
- **IDN-domäner** (`xn--…`): S3 tillåter inte bucketnamn som börjar med `xn--`, och gratisplanen kan inte skriva om Host-headern. Därför ligger de sajterna på `www`, bucketen heter `www.<domän>` och apex skickas vidare till www.
- GitHub loggar in i AWS via OIDC (en delad provider, taggad `project=shared`) och en roll per sajt som bara får lista, ladda upp och ta bort i sin bucket. Rollen litar bara på sitt eget repo.
  - Äldre repon använder standardformatet `repo:seanhak/<repo>:ref:refs/heads/main` i trust policyn. Nya repon (botabra.se, hemlisar.com) använder "immutable subject", `repo:seanhak@1853138/<repo>@<repo-id>:ref:refs/heads/main`. Kontrollera med `gh api repos/seanhak/<repo>/actions/oidc/customization/sub`. Fel format ger "Not authorized to perform sts:AssumeRoleWithWebIdentity".
- Secrets per repo: `AWS_ROLE_ARN` (krävs), `CF_ZONE_ID` och `CF_API_TOKEN` (Zone → Cache Purge → Purge). Utan de två sista hoppas cache-tömningen över med en varning.
- Allt i AWS taggas `project=<projekt>` (bucket, roll, domän och hosted zone). Nyckeln är aktiverad som cost allocation tag.

## Deploy
Varje sajts `.github/workflows/deploy.yml` körs vid push till `main` och via `workflow_dispatch`, och anropar bara `seanhak/static-site-deploy/.github/workflows/deploy.yml@v1` med bucketnamnet (och eventuellt `copyright-name`/`humans-date-label`). Stegen ändras i static-site-deploy, inte i sajterna:
- Bara sajtens filtyper (html, css, js, svg, png, ico, jpg, webp, avif, woff2, txt, xml, webmanifest) kopieras till `dist/`. `.md`, dotmappar och verktyg publiceras aldrig, utom `.well-known/`. En ny filtyp måste läggas till i vitlistan.
- Stämplas: `lastmod` och humans.txt-datum (senaste commit), `Expires` i security.txt (ett år fram), eventuellt ©-år, och `?v=<commit>` på styles.css/script.js.
- styles.css bäddas in i HTML:en. Minifiering med esbuild och html-minifier-terser, alla kommentarer tas bort. Förlustfri bildoptimering med svgo, optipng och jpegoptim.
- Cache-Control: HTML `no-cache`, JS och woff2 ett år `immutable`, txt en timme, övrigt en dag. Sedan töms Cloudflares cache.
- En ändring i static-site-deploy når sajterna först när taggen `v1` flyttas och sajten deployas igen.
