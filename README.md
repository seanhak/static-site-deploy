# static-site-deploy

Gemensam deploy för Seans statiska sajter: ren HTML/CSS/JS i S3 bakom Cloudflare, publicerad med GitHub Actions. Sajterna ligger kvar i egna repon och anropar workflowen härifrån. Det här är ingen monorepo.

| Sajt | Repo | Bucket |
|---|---|---|
| botabra.se | seanhak/botabra.se | `botabra.se` |
| seanhak.com | seanhak/seanhak.com | `seanhak.com` |
| hemlisar.com | seanhak/hemlisar.com (privat) | `hemlisar.com` |
| mellandagsrejva.com | seanhak/mellandagsrejva.com | `mellandagsrejva.com` |
| lål.com | seanhak/lal.com | `www.xn--ll-yia.com` |
| ñä.com | seanhak/na.com | `www.xn--4caz.com` |
| öø.com | seanhak/oo.com | `www.xn--ndae.com` |

## Använda den i en sajt

`.github/workflows/deploy.yml` i sajtens repo:

```yaml
name: Deploy site

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    uses: seanhak/static-site-deploy/.github/workflows/deploy.yml@v1
    with:
      bucket: example.com
      # copyright-name: Bota bra          # stämplar "© <år> Bota bra" i index.html
      # humans-date-label: Last updated   # om humans.txt är på engelska
    secrets: inherit
```

Secrets i sajtens repo: `AWS_ROLE_ARN` (krävs), `CF_ZONE_ID` och `CF_API_TOKEN`. Utan de två sista hoppas cache-tömningen över med en varning.

OIDC-inloggningen gäller det anropande repot, så varje sajts roll litar bara på sitt eget repo, precis som förut.

## Vad workflowen gör

1. Kopierar bara sajtens filtyper till `dist/` (vitlista). `.md`, dotmappar och verktyg publiceras aldrig, utom `.well-known/`.
2. Stämplar `lastmod` i sitemap.xml, datumet i humans.txt, `Expires` i security.txt, eventuellt ©-år, och `?v=<commit>` på styles.css/script.js.
3. Minifierar JS/CSS (esbuild) och HTML (html-minifier-terser), och bäddar in styles.css i HTML:en.
4. Optimerar bilder förlustfritt: svgo, optipng och jpegoptim. Varje verktyg körs bara om det finns filer av den typen.
5. Synkar till S3 med Cache-Control per filtyp: HTML `no-cache`, JS och woff2 ett år `immutable`, txt en timme, övrigt en dag.
6. Tömmer Cloudflares cache.

## Uppdatera

Sajterna pekar på taggen `v1`. Efter en ändring här:

```sh
git tag -f v1 && git push -f origin v1
```

Ändringen gäller vid varje sajts nästa deploy. Kör "Run workflow" i en sajts repo för att rulla ut direkt. Vill du testa en ändring först kan en sajt tillfälligt peka på `@main`. Gör ändringar som inte är bakåtkompatibla som `v2`.

## Skript

- `scripts/check-sites.sh` kontrollerar alla sajter: svar 200 via Cloudflare, `no-cache` på HTML och att S3 direkt ger 403. Läser bara.
- `scripts/update-bucket-policies.sh` uppdaterar alla bucket policies med Cloudflares aktuella IP-spann. Den visar vad som ändras och frågar först. Kräver inloggad AWS CLI.
- `scripts/sites.txt` är listan som skripten använder. Lägg till nya sajter här.

## Ny sajt

Se någon av sajternas README. Kort sagt: bucket och IAM-roll i AWS, zon i Cloudflare, secrets i repot och namnservrar i Route 53, och sedan en rad i `scripts/sites.txt` och tabellen ovan. Nya GitHub-repon använder "immutable subject" för OIDC. Kontrollera `sub` med `gh api repos/seanhak/<repo>/actions/oidc/customization/sub`.
