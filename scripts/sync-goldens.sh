#!/usr/bin/env bash
# Recaptures WehoopKit/Sources/TestSupport/Fixtures (the golden JSON TestSupport vends,
# M5 S1) from a wehoop-api checkout whose DEV stack is seeded (`pnpm seed:dev` there), and
# records the backend commit in scripts/goldens-source. Ids differ per `db reset`, so the
# whole set is replaced; review the diff of manifest.json and the decode tests, never a file by hand.
#
# Usage: scripts/sync-goldens.sh [path/to/wehoop-api]   (default: $WEHOOP_API_DIR or ~/Projects/wehoop-api)
set -euo pipefail

api="${1:-${WEHOOP_API_DIR:-$HOME/Projects/wehoop-api}}"
app="$(cd "$(dirname "$0")/.." && pwd)"
out="$app/WehoopKit/Sources/TestSupport/Fixtures"

[[ -f "$api/src/bin/golden.ts" ]] || { echo "no wehoop-api checkout with pnpm golden at $api" >&2; exit 2; }
[[ -f "$api/.env" ]] || { echo "$api/.env (dev stack, MODE=sim) is required" >&2; exit 2; }

rm -rf "$out"
(cd "$api" && set -a && source .env && set +a && pnpm -s golden --out "$out")
sha="$(git -C "$api" rev-parse HEAD)"
dirty="$(git -C "$api" status --porcelain -- src supabase/migrations | wc -l | tr -d ' ')"
{
  echo "# The wehoop-api commit WehoopKit/Sources/TestSupport/Fixtures was captured from (scripts/sync-goldens.sh)."
  echo "# Capture needs that checkout's dev stack seeded with pnpm seed:dev; CI only decodes the committed files."
  echo "$sha"
} > "$app/scripts/goldens-source"
echo "captured TestSupport/Fixtures from wehoop-api $sha$( (( dirty > 0 )) && echo ' (WARNING: source files uncommitted there)')"
