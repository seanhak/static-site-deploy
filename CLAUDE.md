# static-site-deploy

Delad GitHub Actions-workflow (`workflow_call`) och hjälpskript för Seans statiska sajter i S3 bakom Cloudflare. Se README.md för sajtlista, användning och vad workflowen gör.

`docs/sites.md` beskriver det som är gemensamt för alla sajterna. Den importeras av `/Volumes/SD/git/seanhak/CLAUDE.md` och gäller alltså i varje sajtrepo. Håll den uppdaterad när workflowen eller uppsättningen ändras.

## Noteringar
- Sajterna anropar `@v1`. En ändring här når dem först när `v1` flyttas och sajten deployas igen. Ändringar som inte är bakåtkompatibla blir `v2`.
- Workflowen måste tåla sajter som saknar vissa filer (script.js, SVG, bilder, manifest, humans.txt …). Lägg ett skydd runt varje steg som förutsätter en filtyp.
- Repot är publikt, eftersom det privata hemlisar.com-repot också måste kunna anropa det. Lägg aldrig in hemligheter här. Allt känsligt kommer från anroparens secrets.
- Versioner av npm-verktygen är låsta i workflowen.
- Skripten läser listan i `scripts/sites.txt`. `update-bucket-policies.sh` frågar innan den skriver.
- Utan `CF_API_TOKEN`/`CF_ZONE_ID` hoppas purge över med en varning, i stället för att deployen misslyckas.
