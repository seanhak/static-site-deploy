#!/usr/bin/env bash
# Snabbkoll av alla sajter i sites.txt: svarar sidan, går den via Cloudflare, har den rätt
# Cache-Control, och är S3-bucketen stängd för allt utom Cloudflare. Läser bara, ändrar inget.
set -uo pipefail
cd "$(dirname "$0")"
grep -v '^#' sites.txt | while read -r domain bucket project; do
  [ -n "$domain" ] || continue
  h=$(curl -sI --max-time 10 "https://$domain/")
  code=$(echo "$h" | awk 'NR==1{print $2}')
  server=$(echo "$h" | awk -F': ' 'tolower($1)=="server"{print $2}' | tr -d '\r')
  cc=$(echo "$h" | awk -F': ' 'tolower($1)=="cache-control"{print $2}' | tr -d '\r')
  direct=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "http://$bucket.s3-website.eu-north-1.amazonaws.com/")
  status="ok"
  [ "$code" = "200" ] && [ "$server" = "cloudflare" ] && [ "$cc" = "no-cache" ] && [ "$direct" = "403" ] || status="KOLLA"
  printf '%-6s %-22s %-8s http=%s server=%s cache-control=%s s3-direkt=%s\n' "$status" "$domain" "$project" "$code" "$server" "$cc" "$direct"
done
