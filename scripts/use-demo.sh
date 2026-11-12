#!/usr/bin/env bash
# Points the app's Debug build at the hosted demo environment (backend plan rev 4.15): writes
# Config/Supabase.local.xcconfig and Config/WehoopAPI.local.xcconfig (both git-ignored) from
# .env.demo-test (git-ignored: WEHOOP_SUPABASE_URL, WEHOOP_SUPABASE_ANON_KEY). Never the
# production project; the key is not printed. Undo: scripts/use-dev-stack.sh, which also removes
# the API override. Usage: scripts/use-demo.sh
set -euo pipefail
cd "$(dirname "$0")/.."
ENV=.env.demo-test
DEMO_REF=flumbayfssejcfjsearm
[[ -f $ENV ]] || { echo "STOP: no $ENV"; exit 64; }
URL=$(grep '^WEHOOP_SUPABASE_URL=' "$ENV" | cut -d= -f2-)
[[ $URL == "https://$DEMO_REF.supabase.co" ]] || { echo "STOP: $ENV is not the demo project"; exit 64; }
KEY=$(grep '^WEHOOP_SUPABASE_ANON_KEY=' "$ENV" | cut -d= -f2- | tr -d '"'"'")
[[ -n $KEY ]] || { echo "STOP: no WEHOOP_SUPABASE_ANON_KEY in $ENV"; exit 64; }
for f in Config/Supabase.local.xcconfig Config/WehoopAPI.local.xcconfig; do
  git check-ignore -q "$f" || { echo "STOP: $f is not git-ignored"; exit 64; }
done
umask 077
printf '// Written by scripts/use-demo.sh: the hosted demo. Git-ignored.\nWEHOOP_SUPABASE_URL = https:/$()/%s.supabase.co\nWEHOOP_SUPABASE_ANON_KEY = %s\n' "$DEMO_REF" "$KEY" > Config/Supabase.local.xcconfig
printf '// Written by scripts/use-demo.sh: the hosted demo API. Git-ignored.\nWEHOOP_API_URL = https:/$()/wehoop-demo.fly.dev\n' > Config/WehoopAPI.local.xcconfig
echo "wrote Config/Supabase.local.xcconfig and Config/WehoopAPI.local.xcconfig (demo, key not shown); rebuild the app"
