#!/usr/bin/env bash
# Regenerates WehoopKit/Sources/Contracts/Generated from the backend's Zod schemas
# (wehoop-api `pnpm gen:swift`, M5 B1) and records which backend commit it came from
# in scripts/contracts-source, which CI uses to verify the files are in sync.
#
# Usage: scripts/sync-contracts.sh [path/to/wehoop-api]   (default: $WEHOOP_API_DIR or ~/Projects/wehoop-api)
#        scripts/sync-contracts.sh --check [path/to/wehoop-api]   # verify only, exit 1 on drift
set -euo pipefail

check=0
if [[ "${1:-}" == "--check" ]]; then check=1; shift; fi
api="${1:-${WEHOOP_API_DIR:-$HOME/Projects/wehoop-api}}"
app="$(cd "$(dirname "$0")/.." && pwd)"
out="$app/WehoopKit/Sources/Contracts/Generated"

[[ -f "$api/src/contracts/registry.ts" ]] || { echo "no wehoop-api checkout at $api" >&2; exit 2; }

if (( check )); then
  (cd "$api" && pnpm -s gen:swift --check --out "$out")
  exit $?
fi

(cd "$api" && pnpm -s gen:swift --out "$out")
sha="$(git -C "$api" rev-parse HEAD)"
dirty="$(git -C "$api" status --porcelain -- src/contracts src/model src/api/routes/players.ts src/leagues/codes.ts | wc -l | tr -d ' ')"
{
  echo "# The wehoop-api commit WehoopKit/Sources/Contracts/Generated was emitted from (scripts/sync-contracts.sh)."
  echo "# CI checks out this commit and runs: pnpm gen:swift --check --out WehoopKit/Sources/Contracts/Generated"
  echo "$sha"
} > "$app/scripts/contracts-source"
echo "synced Contracts/Generated from wehoop-api $sha$( (( dirty > 0 )) && echo ' (WARNING: schema files uncommitted there)')"
