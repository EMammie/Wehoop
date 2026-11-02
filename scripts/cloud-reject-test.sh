#!/usr/bin/env bash
# M5 S3: the guest reject tests (guestSession, publishRejected, publicJoinIsolated) against
# the hosted Supabase project. Run by the owner, or on the owner's go.
#
#   scripts/cloud-reject-test.sh          the cloud project, from .env.cloud-test
#   scripts/cloud-reject-test.sh --dev    the same tests on the local dev stack (a dry run)
#
# .env.cloud-test is git-ignored and filled by the owner with two lines:
#   WEHOOP_SUPABASE_URL=https://<ref>.supabase.co
#   WEHOOP_SUPABASE_ANON_KEY=<the project's anon / publishable key>
# The file is parsed, never sourced, and the key is never printed: the log under
# .local-runs/ has it (and anything JWT- or key-shaped) redacted. The cloud run also sets
# WEHOOP_EXPECT_PRIVATE_ONLY=1, so a public join of game:{id} must be refused there.
# Each run signs in 7 anonymous users (2, 2 and 3 for the public case); they can be deleted in the dashboard.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
ROOT=$PWD
ENV_FILE=.env.cloud-test
MODE=cloud
[[ ${1:-} == --dev ]] && MODE=dev

if [[ $MODE == cloud ]]; then
  [[ -f $ENV_FILE ]] || { echo "STOP: $ENV_FILE is missing"; exit 64; }
  git check-ignore -q "$ENV_FILE" || { echo "STOP: $ENV_FILE is not git-ignored"; exit 64; }
  URL= KEY=
  while IFS= read -r line || [[ -n $line ]]; do
    case $line in
      WEHOOP_SUPABASE_URL=*) URL=${line#*=} ;;
      WEHOOP_SUPABASE_ANON_KEY=*) KEY=${line#*=} ;;
    esac
  done < "$ENV_FILE"
  URL=${URL%\"}; URL=${URL#\"}; URL=${URL%/}
  KEY=${KEY%\"}; KEY=${KEY#\"}
  [[ $URL =~ ^https://[a-z0-9]{20}\.supabase\.co$ ]] || { echo "STOP: WEHOOP_SUPABASE_URL must be https://<ref>.supabase.co"; exit 64; }
  EXPECT_PRIVATE_ONLY=1
else
  BACKEND=${WEHOOP_API_REPO:-$HOME/Projects/wehoop-api-m5}
  grep -q '^SUPABASE_URL=http://127.0.0.1:54321$' "$BACKEND/.env" || { echo "STOP: $BACKEND/.env is not the dev stack"; exit 64; }
  URL=http://127.0.0.1:54321
  KEY=$(grep '^SUPABASE_ANON_KEY=' "$BACKEND/.env" | cut -d= -f2- | tr -d '"'"'")
  EXPECT_PRIVATE_ONLY=0
fi
[[ -n $KEY ]] || { echo "STOP: the anon key is empty"; exit 64; }

mkdir -p .local-runs
LOG=.local-runs/reject-$MODE-$(date -u +%Y%m%dT%H%M%SZ).log
echo "reject tests: mode=$MODE supabase=$URL expectPrivateOnly=$EXPECT_PRIVATE_ONLY"
echo "log: $ROOT/$LOG"

# The API is not used by these tests; BackendConfiguration only needs a well-formed URL.
WEHOOP_INTEGRATION=1 WEHOOP_API_URL=https://api.invalid WEHOOP_SUPABASE_URL="$URL" \
  WEHOOP_SUPABASE_ANON_KEY="$KEY" WEHOOP_EXPECT_PRIVATE_ONLY=$EXPECT_PRIVATE_ONLY \
  swift test --package-path WehoopKit \
    --filter 'DevStackIntegrationTests/(guestSession|publishRejected|publicJoinIsolated)' 2>&1 \
  | REDACT="$KEY" perl -pe 'BEGIN { $k = $ENV{REDACT} } s/\Q$k\E/[anon-key]/g if length $k;
      s/eyJ[\w-]+\.[\w-]+\.[\w-]+/[jwt]/g; s/sb_(?:publishable|secret)_[\w-]+/[key]/g' > "$LOG"
CODE=${PIPESTATUS[0]}
unset KEY

grep -E 'S3-EVIDENCE|✔ Test |✘ Test |Expectation failed|Test run with' "$LOG"
echo "swift test exit $CODE"
exit "$CODE"
