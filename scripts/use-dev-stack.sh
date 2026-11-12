#!/usr/bin/env bash
# Points the app's Debug build at the local dev stack: writes Config/Supabase.local.xcconfig
# (git-ignored) with the dev stack's anon key, read from the wehoop-api .env. Never the trial
# stack, never a cloud key; the key is not printed. Usage: scripts/use-dev-stack.sh
set -euo pipefail
cd "$(dirname "$0")/.."
BACKEND=${WEHOOP_API_REPO:-$HOME/Projects/wehoop-api-m5}
grep -q '^SUPABASE_URL=http://127.0.0.1:54321$' "$BACKEND/.env" || { echo "STOP: $BACKEND/.env is not the dev stack"; exit 64; }
KEY=$(grep '^SUPABASE_ANON_KEY=' "$BACKEND/.env" | cut -d= -f2- | tr -d '"'"'")
[[ -n $KEY ]] || { echo "STOP: no SUPABASE_ANON_KEY in $BACKEND/.env"; exit 64; }
OUT=Config/Supabase.local.xcconfig
git check-ignore -q "$OUT" || { echo "STOP: $OUT is not git-ignored"; exit 64; }
umask 077
printf '// Written by scripts/use-dev-stack.sh: the local dev stack. Git-ignored.\nWEHOOP_SUPABASE_URL = http:/$()/127.0.0.1:54321\nWEHOOP_SUPABASE_ANON_KEY = %s\n' "$KEY" > "$OUT"
# Undo scripts/use-demo.sh's API override (only that one; a hand-written override is kept).
API=Config/WehoopAPI.local.xcconfig
if [[ -f $API ]] && head -1 "$API" | grep -q 'scripts/use-demo.sh'; then rm "$API"; echo "removed $API (demo API override)"; fi
echo "wrote $OUT (dev stack, key not shown); rebuild the app to pick it up"
