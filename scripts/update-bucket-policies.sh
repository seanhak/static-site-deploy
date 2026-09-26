#!/usr/bin/env bash
# Uppdaterar bucket policyn på alla sajter i sites.txt med Cloudflares aktuella IP-spann.
# Kör när Cloudflare ändrar sina IP-spann (https://www.cloudflare.com/ips/). Kräver inloggad AWS CLI.
# Visar ändringen och frågar innan något skrivs. `--yes` hoppar över frågan.
set -euo pipefail
cd "$(dirname "$0")"

ips=$( (curl -sf https://www.cloudflare.com/ips-v4; echo; curl -sf https://www.cloudflare.com/ips-v6) | grep . )
count=$(echo "$ips" | wc -l | tr -d ' ')
[ "$count" -gt 15 ] || { echo "Fick bara $count IP-spann från Cloudflare, avbryter." >&2; exit 1; }
json_ips=$(echo "$ips" | python3 -c 'import sys, json; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')
echo "Cloudflare har $count IP-spann."

grep -v '^#' sites.txt | while read -r _ bucket _; do
  [ -n "$bucket" ] || continue
  policy=$(python3 -c "import json,sys; print(json.dumps({'Version':'2012-10-17','Statement':[{'Sid':'CloudflareOnly','Effect':'Allow','Principal':'*','Action':'s3:GetObject','Resource':'arn:aws:s3:::$bucket/*','Condition':{'IpAddress':{'aws:SourceIp':json.loads(sys.argv[1])}}}]}))" "$json_ips")
  current=$(aws s3api get-bucket-policy --bucket "$bucket" --query Policy --output text 2>/dev/null || echo "{}")
  if python3 -c "import json,sys; a=json.loads(sys.argv[1]); b=json.loads(sys.argv[2]); sys.exit(0 if a==b else 1)" "$current" "$policy"; then
    echo "  $bucket: redan aktuell"
    continue
  fi
  echo "  $bucket: behöver uppdateras"
  if [ "${1:-}" != "--yes" ]; then
    read -r -p "    Skriv ny policy? [j/N] " svar < /dev/tty
    [ "$svar" = "j" ] || { echo "    hoppar över"; continue; }
  fi
  aws s3api put-bucket-policy --bucket "$bucket" --policy "$policy"
  echo "    uppdaterad"
done
