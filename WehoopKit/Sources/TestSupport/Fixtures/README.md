# Golden fixtures

Captured by wehoop-api `pnpm golden` from a dev stack seeded with `pnpm seed:dev` (backend 5ab49f7, 2026-11-01T15:51:55.761Z).
API bodies are the bytes the Hono API serves; view rows are the bytes the local PostgREST returns to the anon role.
Every file was parsed with its contract schema before it was written. `manifest.json` lists each file with its contract type.
Ids differ per `db reset`: recapture the whole set (`scripts/sync-goldens.sh` in the app), never edit a file by hand.

- `wnba/sim-93ee7c68`: Las Vegas Aces at New York Liberty, 2026 Commissioner’s Cup final; full coverage, every change type, five deleted events
- `ncaawb/sim-d9b71fe0`: Northwestern at Michigan State, 2025 REG; full coverage
- `ncaawb/sim-d9b71fe0-extended`: the same recording relabelled extended_boxscore: status and period changes only, stats at stats_final_at
- `unrivaled/docs-838316ea`: Lunar Owls at Mist, hand-assembled from docs samples; Elam period, target 84 (partly synthetic, fixtures/unrivaled/README.md)
