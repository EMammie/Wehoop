# M5: Wehoop iOS on wehoop-api (modular rebuild)

Status: approved 2026-10-23. Branch `m5-modular`, cut from local `main` at `bf4902a`
(local `main` is ahead of `origin/main` 9cf4619 and has not been pushed).
Backend plan: `~/Projects/wehoop-api/docs/PLAN.md` §7 M5 (rev 4.10 records this scope; rev 4.11 adds the `.unknown` cases and the League-as-data rule, rev 4.15 the demo host, B4).

Progress (2026-11-05): S0, S1, S2 and S3 done; S4 in progress (app wired to WehoopData, game screen built; the Simulator recording and the airplane-mode row are still to run); S5–S8 not started. Backend: B1 and B2 done; B3 and B4 not started. Evidence: `devlog/evidence/M5.md`.

## Owner decisions (2026-10-22/23)

1. **Fresh modular shell in this repo**, not a refactor in place and not a new repo.
   Git history and the bundle id `com.ChallengerApp.Wehoop` are kept. The old app
   moves to `Legacy/` as a reference and is deleted before beta.
2. **Full feature parity** with the old app, plus the live game screen, standings,
   the league switch and a player's career across leagues.
3. **Minimum iOS 26.2**, as today.
4. The pre-rebuild work in progress was committed as-is on `perf/cached-date-formatters`
   (`ebfef26`) and is not merged.

6. **Career, growth and overseas leagues (2026-10-25):** not required for the first version, but the design must not block them. A player's career across our three leagues ships in S6 as the season table; growth views (per-season trends, game log) and overseas leagues (a fourth provider product) are queued for M6 below. The rule for M5: nothing in a feature module may hard-code the set of leagues.
7. **Navigation is owned by App; features emit actions (2026-10-26, after an independent review):** no feature declares a `Route` enum, a `NavigationStack`, a `NavigationPath` or a `navigationDestination`. Each feature exposes an `Actions` struct of `@MainActor` closures with no-op defaults (`didSelectGame(id)`, `didSelectPlayer(id)`, `didSelectTeam(id)`, `didRequestStandings(leagueCode)`, `didRequestSettings()`), only the hops it has; Onboarding is a flow with a completion handler. App declares one `AppRoute: Hashable, Codable, Sendable` (`game`, `player`, `team`, `standings`), an `AppSheet`, one observable stack per tab, and an `AppNavigation` that selects tabs, pushes, clears a tab's path on re-tap, and opens a `DeepLink` (dismiss the sheet, select the tab, set the path). Routes carry ids only. A notification tap is a `DeepLink` with a different parser; a link that arrives before the root view exists or while onboarding is up waits in a pending slot. Navigation is tested in AppTests (push, re-tap, deep link, bad URL) and one flow per tab in UI tests; feature tests never test navigation. The nine S0 `XRoute` enums and `ScoresRouteTests` are deleted in S1. Sub-decisions:
   - **State restoration of paths: M6.** Effect: `AppRoute` is `Codable` from day one so nothing has to change later, but no `@SceneStorage` or restore logic is written in M5; a relaunched app opens on the Scores root.
   - **One keyed `GameSync` owner per game in WehoopData, decided in S3 before the Game screen in S4.** Effect: Game(g1) → Player → Team → Game(g1) reuses one subscription and one buffer instead of resubscribing and re-snapshotting; the owner keeps a short grace period after the last view disappears; S3's acceptance gains a row for it.
   - **Typed ids in Domain now (S1): `Game.ID`, `Player.ID`, `Team.ID`, `League.Code`.** Effect: a route or action cannot be handed the wrong kind of id, and `standings(League.Code)` survives `League` becoming a struct; Contracts' string ids are wrapped once in WehoopData's mapping.
   - **Multi-window on iPad off until M6 (`UIApplicationSupportsMultipleScenes = NO`).** Effect: one scene, so `AppNavigation` lives as `@State` in the scene's root view with `onOpenURL` attached there; a second window would need per-scene navigation and a shared `GameSync` owner, which M6 can add without touching features.

## Why not refactor the existing app

Three read-only surveys (2026-10-22) found the following:

- **Data, about 3,600 lines:** built entirely around calling Sportradar from the phone.
  - Data sources return untyped `Data`, which is decoded, re-encoded and decoded again.
  - Status mapping turns `halftime`/`delayed` into `.scheduled` and then into **Final**.
  - `fetchGames` swallows network errors, so the local fallback never runs.
- **Realtime:** the WebSocket is a stub that always throws. Polling points at placeholder
  `api.unrivaled.com` URLs and re-reads a 5-minute cache.
- **Composition:** a service locator keyed by type name that `fatalError`s.
  - Without an API key the app crashes at launch: `MockRemoteDataSource` lacks
    `LeagueDataSource`, and `MainTabView` builds the Leaders view model eagerly.
  - Every view's fallback init builds Data-layer types.
- **Presentation:** four V1/V2 forks behind flags; `ObservableObject` view models with
  fire-and-forget `Task {}` loads; `NavigationView` with eager `NavigationLink`s.
  - The team page shows fake data (win streak, standings, leaders).
  - There is no game detail, play-by-play, clock or player box score.
- **Build:** Swift 5 mode with every type defaulting to the main actor (the 2,400 lines
  of DTO decoding run on it), no packages, XCTest. Presentation tests are mostly
  `XCTAssertNotNil(view)`.
- **Security:** a real Sportradar key in the git-ignored `Config.xcconfig` is copied into
  `Info.plist` and ships readable in the bundle. `URLSessionNetworkService` attaches it to
  requests on any host. The new app ships **no provider key**. If a build containing it
  was ever distributed, rotate that key.

**Worth keeping:**
- The domain value types and async repository style, as shapes to adapt.
- `GamesDisplayManager`.
- The `BoxScoreSheetState` pattern.
- A dozen components.
- The onboarding visuals.
- `PollingServiceImpl`'s backoff loop.
- `TeamsCache`'s in-flight coalescing.
- The bounded `TaskGroup` fan-out.
- The Data/Domain test suites, as a feature inventory.

The Courtside project (`~/Desktop/Development/Courtside`) already proves the target pattern:
- a local Swift 6 package;
- a closed `Sendable` event enum behind `AsyncStream`;
- a pure `apply(_:)` reducer;
- `@Observable` view models;
- Swift Testing under `swift test` with no simulator.

## Target layout

```
Wehoop/                    repo root
  project.yml              XcodeGen; Wehoop.xcodeproj is generated and git-ignored
  App/                     app target: WehoopApp, composition root, root navigation
  AppTests/  AppUITests/
  WehoopKit/               local SPM package (swift-tools-version 6.2)
    Package.swift
    Sources/
      Domain/ Contracts/ LiveEngine/ WehoopData/ DesignSystem/ TestSupport/
      FeatureScores/ FeatureGame/ FeaturePlayers/ FeatureTeams/
      FeatureStandings/ FeatureLeaders/ FeatureFavorites/
      FeatureOnboarding/ FeatureSettings/
    Tests/  (one Swift Testing target per module)
  Legacy/                  old Wehoop/, WehoopTests/, WehoopUITests/, Wehoop.xcodeproj (git mv)
  docs/  .claude/  .github/workflows/ci.yml  CLAUDE.md
```

## Modules and dependency rules

```
App ──► every Feature*, WehoopData, DesignSystem, Domain
Feature* ──► Domain, DesignSystem             (never WehoopData, never another Feature)
WehoopData ──► Domain, Contracts, LiveEngine, supabase-swift
LiveEngine ──► Domain, Contracts              (no networking, no UI)
Contracts ──► (nothing)
Domain ──► (nothing; Foundation only)
DesignSystem ──► (nothing; SwiftUI)
TestSupport ──► Domain, Contracts, LiveEngine
```

| Module | Responsibility |
|---|---|
| **Domain** | Entities, all `Sendable` value types:<ul><li>`League` (wnba/ncaawb/unrivaled)</li><li>`Season` (type PRE/REG/OOT/PST/CC)</li><li>`Team`</li><li>`Player` (canonical uuid + `ExternalId`s + `mergedIds`)</li><li>`Game`, with the full `GameStatus` set and `phase`</li><li>`Period` (quarter/overtime/elam, `sequence`)</li><li>`GameClock` (`clock`, `clockDecimal`, `running: Bool?`, `asOf`)</li><li>`Coverage` (full/extendedBoxscore)</li><li>`PlayEvent` (mirrors `LiveEvent`)</li><li>`TeamStatLine`, `PlayerStatLine` (provider-keyed, `played`, `onCourt`)</li><li>`Standing`, `PlayerSeasonLine`, `Tournament`</li></ul>Absent stats are `nil`, never 0. Repository protocols are `Sendable` and `async throws`. `LiveGameSource` is `func updates(gameId:) -> AsyncThrowingStream<LiveGameUpdate, Error>`. No formatting and no provider strings. |
| **Contracts** | Wire types generated by wehoop-api `pnpm gen:swift`: `GameChange`, the `LiveEvent` bodies, `Pulse`, `Snapshot`, the `/changes` page, `/v1/players/:id`, and rows of `v_schedule` / `v_boxscore` / `v_standings` / `v_player_seasons`. Codable, `Sendable`. Never edited by hand: CI fails when the generated output differs from what is committed. Golden JSON from the backend fixtures is decoded in tests. |
| **LiveEngine** | Two parts:<ul><li>**`LiveGameState`**: a pure reducer. `init(snapshot:)`, then `apply(_ change: GameChange)` (dedupes on `id`, rejects `seq != last+1` with `.gap`) and `apply(_ pulse: Pulse)` (newest `observedAt` wins; it touches only the clock and reports `latestSeq > lastSeq`).</li><li>**`GameSync`**: an actor implementing the reconnect contract of backend plan §4. Subscribe and buffer; snapshot; apply the buffered changes after `snapshot.seq`; on a gap or a pulse ahead, page `/changes?after=` until `hasMore=false`; `retainedFrom > last+1` → re-snapshot; on reconnect, foreground or network change → catch up; on `closed` → one final snapshot.</li></ul>Its transport, API and clock are injected protocols. **`ClockModel`** counts down only when `running == true`, from `asOf` corrected by the server offset (`serverTime`), and freezes when `nil`. Tests: macOS `swift test`. |
| **WehoopData** | <ul><li>`APIClient`: Hono `/v1/...`; typed endpoints; one configured decoder; retry with backoff on 5xx and timeouts; base URL host-scoped.</li><li>`PostgRESTReader` and `RealtimeTransport`: supabase-swift (exact version pinned); Realtime uses private channels `game:{id}` and `league:{code}:scores`.</li><li>`AuthSession`: anonymous sign-in, token refresh, `setAuth` on Realtime.</li><li>`Cache`: an actor; memory plus a disk tier for the schedule and teams; in-flight coalescing.</li><li>`FavoritesStore`: canonical player ids, with a one-time migration of the old `favorite_player_ids` (Sportradar ids, resolved through `/v1/players/<league>:<id>`).</li><li>The repository implementations.</li></ul> |
| **DesignSystem** | Tokens from the brand (wehoop-landing `globals.css`):<ul><li>colors: ink `#29183b`, paper `#fff8ed`, peach `#f7b497`, lime `#d9ed79`, muted `#685e70`, with dark-mode pairs;</li><li>type: Barlow Condensed for display, DM Sans for body, both bundled (OFL) and Dynamic Type-scaled;</li><li>spacing, radius and elevation;</li><li>semantic status colors (live, final, delayed);</li><li>team palettes keyed by `league:alias`;</li><li>the motion policy (Reduce Motion), as in `CourtsideTheme`.</li></ul>Components ported from the old app: `EmptyState`, `ErrorState`, `Loading`, `StatBox` (dark-mode fix), `CategoryPicker` (generic, honors its list), `TeamLogo`, `CardFeed`, `WeekStrip` (from `DatePickerViewV2`), `PlayerRow`/`FeaturedPlayerCard` (plain values), `ScoreDigits` (`.contentTransition(.numericText())`). |
| **Feature\*** | Each feature has:<ul><li>an `Actions` struct of `@MainActor` closures with no-op defaults, only for the hops it has (decision 7); no `Route` enum, no `NavigationStack`, no `navigationDestination`;</li><li>a `Dependencies` struct of Domain protocols;</li><li>id-based entry points (`GameView(gameId:dependencies:actions:)`) that load themselves;</li><li>`@MainActor @Observable` view models with one `State` enum (`loading / loaded / empty / failed`), loads as `async` methods driven by `.task`/`.refreshable`, cancellation on disappear;</li><li>previews backed by TestSupport fixtures.</li></ul> |
| **TestSupport** | Fixture snapshots and change streams generated from the backend's committed replay fixtures (WNBA `sim-93ee7c68`, NCAAWB `sim-d9b71fe0`, Unrivaled docs set, including Elam), `FakeTransport` with injectable drops and duplicates, a deterministic `ReplaySource` (Courtside's `GameSimulator` idea) for previews, UI tests and the `-WehoopFixtures` launch argument. |
| **App** | The composition root (live or fixture dependencies, chosen by launch argument and build configuration), the root `TabView` with one `NavigationStack` and one observable stack per tab, `AppRoute` / `AppSheet` / `AppNavigation` / `DeepLink` (decision 7; the only `navigationDestination(for: AppRoute.self)` in the app, one per tab root, never inside a lazy container), the deep link `wehoop://game/<id>` and the notification-tap parser with a pending slot for cold start and onboarding, and a scene-phase hook that tells `GameSync` about foreground and network changes. |

**Compiler and testing rules:**
- Swift 6 language mode with complete strict concurrency.
- `defaultIsolation(MainActor.self)` only for Feature\*, DesignSystem and App.
- Domain, Contracts, LiveEngine and WehoopData are nonisolated.
- No `@unchecked Sendable` without a comment saying why.
- Swift Testing everywhere except UI tests (XCUITest).
- SwiftLint (already installed) in CI.

## Screen to data source

| Screen | Old app | New source |
|---|---|---|
| Scores (date strip, live / upcoming / final per league) | GamesViewV2 (shows at most 3 games, layout bug) | `v_schedule` by league and date window. Live scores come from the `league:{code}:scores` channel (backend M4; running on the hosted demo): the list re-reads `v_schedule` on every join of the channel and on returning to the foreground, and every 60 s while any game in the list is live, because the backend's sender is best-effort (a failed publish is not resent). A day change re-reads only; the subscription follows the league. |
| Game: header, clock, line score, play-by-play, team and player box score, Elam target | box score sheet only | `GameSync` (snapshot + `/changes` + `game:{id}` + pulse). Closed games: the snapshot only. Coverage `extendedBoxscore` shows score, status and period, and says so. |
| Leaders (category picker, top players) | LeadersViewV2 | `v_player_seasons` ordered by the category average, filtered by league and season. Needs index support (backend B2). |
| Players (search, profile, favorite) | PlayersView, PlayerProfileViewV2 | Search: `players` fts through PostgREST. Profile: `/v1/players/:id` + `v_player_seasons` (career across leagues, one timeline ordered by season, grouped by league). Game log: `v_boxscore` filtered by `player_id`. Trend charts over the same rows are M6. |
| Teams (list, page: record, roster, leaders, schedule) | TeamsView, TeamPageViewV2 (fake data) | `teams`, `v_standings`, `player_team_seasons` roster, `v_player_seasons` filtered by team, `v_schedule` by team. |
| Standings | none (guessed from win%) | `v_standings` by league, season and conference. |
| Favorites | FavoritesView | `FavoritesStore` + players, live games of favorite players' teams. |
| Onboarding | IntroPage, carousel, title reveal | port: replace the 100 Hz timer with `TimelineView`, fix the always-true `\|\|`, remove global symbols, credit or rewrite the tutorial-derived code. |
| Settings | version hardcoded, debug flags | version from the bundle, data attribution (Sportradar), acknowledgements, debug-only fixture toggle. V1/V2 flags are gone. |

### Built for later: career, growth, overseas

These are not M5 features, but M5 lays the data shapes they will stand on, so they are decided now:

- **`League` is data, not a switch.** `Domain.League` is a value (`code`, `name`, `shortName`, colors) loaded from the `leagues` table, not a three-case enum that every feature switches on. A feature receives a `[League]` and never names one. Adding a league is then a backend migration and a `Domain` fixture, with no feature change. The one place that may switch on a code is `DesignSystem` for brand colors, with a default for unknown codes.
- **Career is one timeline.** `PlayerCareer` in `Domain` is an ordered list of `SeasonLine` (league, season year and type, team, games, totals, averages) from `v_player_seasons`, already across leagues. The profile in S6 renders it as a table grouped by league. M6 renders the same value as per-stat trend charts (Swift Charts) and a "then vs now" comparison, with no new data.
- **Game log is derived.** `v_boxscore` has one row per `(game, provider_player_id)` with `player_id`; filtered by player and ordered by `scheduled_at` it is the game log. S6 may show the last 10 as a list; the full log with filters is M6.
- **History depth is a backend question.** Season lines reach only as far back as the reference refresh (B3) ingests them; charts are shallow in year one unless past seasons are backfilled on purpose. `FeaturePlayers` must look right with one season and with ten.
- **Overseas lines will carry a different id system.** Sportradar's international competitions live in the Global Basketball API (`sr:player:` ids, mapping feeds to link them to WNBA and NCAAWB ids). `SeasonLine` therefore carries `league.code` plus an optional `competition` name and country, so a EuroLeague Women or WNBL line fits the same row type when M6 adds the source.

## Backend work M5 needs (wehoop-api, dev stack only)

| ID | Work | Hours |
|---|---|---|
| B1 | `pnpm gen:swift`: emit the Contracts Swift files from the Zod schemas (a small TS emitter: discriminated unions become enums with associated values; JSON Schema → quicktype handles unions poorly), plus `pnpm gen:swift --check` for CI on both repos. | 5 |
| B2 | `pnpm seed:dev`: load every committed fixture (three leagues: schedules, standings, profiles, seasonal stats, leaders, replay games) into the dev stack so every screen has data. An index or view for leaders ordering. | 4 |
| B3 | **Gap found 2026-10-23**: the production scheduler fetches only `daily_schedule`. Standings, team and player profiles, seasonal stats and league leaders are processable by `ReferenceIngester` but nothing schedules them. Add a reference refresh (standings daily, rosters and profiles weekly, season stats nightly) under the quota guard. Needed before TestFlight users see real Leaders, Standings or Team pages; it runs only once production keys exist. | 6 |
| B4 | A hosted backend for TestFlight (backend plan rev 4.15, owner decisions 2026-11-05/06). The M4 Fly deploy waits on a Fly payment card and the owner's go and, without production keys, ingests nothing. B4 is a **separate demo environment** (its own Supabase project and Fly app, demo configuration of the same code): the fake provider on loopback serves a rotation of the recorded fixtures (WNBA and NCAAWB Sportradar simulation recordings; the hand-assembled Unrivaled replay only with `--include-synthetic`), one replay every 3 h at real time, each a deterministic game whose timestamps are shifted to its slot, and the production scheduler runs against it with no Sportradar key and no Sportradar traffic. `replay` (`recorded` / `synthetic`) is in `v_schedule`, snapshots, pulses and scoreboard messages, and the app shows **Replay** on the score card and the game screen. The TestFlight build points at the demo environment; switching to production selects the production environment and never depends on a purge. It proves the hosted path and recovery, not real-provider push availability or latency. | 14 (+2 app) |

## Slices

Each slice runs implementer → reviewer → validator → devlog, as in wehoop-api. Evidence goes in `devlog/evidence/M5.md`: exact commands and captured output, test counts from `swift test` / `xcodebuild test`, and Simulator screen recordings for the UI rows.

| # | Slice | Acceptance evidence | Hours |
|---|---|---|---|
| S0 | **Skeleton.**<ul><li>`git mv` the old app to `Legacy/`.</li><li>XcodeGen `project.yml`; WehoopKit with every module as an empty target that builds; Swift 6 settings.</li><li>CI (`.github/workflows/ci.yml` on `macos-15` or later: `swift test` for the package, `xcodebuild build` for the app, SwiftLint).</li><li>CLAUDE.md, `.claude/agents/{implementer,reviewer,validator,devlog}.md`, `/milestone` skill.</li><li>DesignSystem tokens and fonts.</li></ul> | `xcodegen generate && xcodebuild build` green; `swift test` green; CI green on the PR; the dependency rules checked by a script (no Feature imports WehoopData). | 8 |
| S1 | **Contracts.** Generated types (B1) and golden decode tests for every change type, pulse, snapshot, `/changes` page and view row, in all three leagues. | Every fixture decodes; `gen:swift --check` clean. | 6 |
| S2 | **LiveEngine.** Reducer, `GameSync`, `ClockModel`. | Replaying the WNBA fixture stream through `FakeTransport` with injected drops, duplicates and reorders folds to the same state as the final snapshot (decoded-equal); gap → `/changes`; expired history → re-snapshot; pulse ahead → catch-up; clock frozen when `running == nil`. | 12 |
| S3 | **WehoopData.** APIClient, PostgREST, Realtime, anonymous auth, cache, favorites migration. | Integration tests against the dev stack + `pnpm dev:worker --replay-file …` + `pnpm dev:api`: a guest session receives `game:{id}`; a publish attempt is rejected; a snapshot matches `/changes`. | 10 |
| S4 | **Game screen.** Header with rolling score digits, clock, period and Elam target; play-by-play feed; team and player box score; coverage label. | Simulator recording of a replayed game live; 20 s of airplane mode, then a resync with no duplicate rows (the M5 row of backend plan §7). | 14 |
| S5 | **Scores.** Week strip, league switch, live, upcoming and final sections, live score updates. | UI test in fixture mode; recording of a score changing in the list. | 8 |
| S6 | **Parity.** Leaders, Players (search, profile, career), Teams (page, roster, schedule), Standings, Favorites (with migration), Settings. | View model behavior tests per screen (no not-nil view tests); UI tests per tab in fixture mode. | 16 |
| S7 | **Onboarding and polish.** Onboarding port; accessibility (VoiceOver labels, Dynamic Type at XXL, Reduce Motion); dark mode; haptics on score changes. | Accessibility Inspector audit with no warnings on each screen; screenshots in light, dark and XXL. | 6 |
| S8 | **Beta.** Delete `Legacy/`; App Store Connect record; TestFlight build against the hosted backend (B4); 3–5 testers from the wehoop-landing list; the **held-profiles decision checkpoint** (backend plan rev 4.5, from the M3 hold count). | TestFlight build number; tester count; the checkpoint decision recorded. | 6 |

**Hours and calendar:** the app slices total **86 h** (88 with B4's Replay label), and B1–B4 add **29 h**, about **117 h** in all (101 before rev 4.15 added B4; plan rev 4.9 budgeted 26 h for M5). At 20 h/week that is about 5 weeks.

S0–S7 need only the dev stack and simulation fixtures: no Sportradar quota and no trial stack. They can run alongside the Game 4 run (2026-10-24) and the NCAAWB live window (about 2026-11-03 to 11-15; the trial ends 2026-11-16). S8 waits for B4.

## Out of scope for M5

- Push notifications.
- Widgets and Live Activities (a natural M6: a Live Activity is a second `GameSync` consumer).
- iPad-specific layouts (it runs, unoptimized).
- Localization beyond English. Strings go through `String(localized:)` from day one.
- Provisional profiles (decided at the S8 checkpoint).
- Growth charts, "then vs now" comparisons and the full game log (M6; S6 ships the season table and the last 10 games).
- Overseas leagues and players' lines abroad (M6; a fourth provider product, see below).

## Queued for M6 (not required for the first version)

| Item | What it needs | Notes |
|---|---|---|
| Overseas leagues (EuroLeague Women, Turkey, Spain, France, Australia WNBL, China WCBA) | Backend: a Global Basketball API trial key (separate product and quota), an adapter over its `sr_id` system, the mapping feeds to link `sr:player:` ids to the WNBA and NCAAWB ids `identity.ts` already holds, and one `leagues` row per competition (`provider_product`, `provider_competition_id`). App: nothing beyond new `League` rows, if the rule above holds. | Sportradar publishes no list of which women's competitions the product covers; the trial confirms it. Lower-tier coverage: season lines and box scores, not play-by-play. Backend plan rev 4.11 (2026-10-27) decided the shape: each competition the app lists is a `leagues` row (no `competitions` table), `league_code` becomes open data in M6, and the generated contracts keep an `.unknown` case; team identity is decided at the M6 gate. |
| Growth over time | `FeaturePlayers`: per-stat trend charts over `PlayerCareer`, a season-vs-season comparison, the full game log with filters. Backend: a decision on backfilling past seasons through B3. | No new data shapes. |
| Live Activities and widgets | A second `GameSync` consumer in an extension target. | Already listed above. |
| Push notifications | Backend sender + APNs; favorites drive the subscriptions. | |
| Shared token source | A `tokens/base.json` owned by one repo, a generator that emits `BrandPalette` and the `:root` CSS variables, and a `--check` step in both CIs. | Trigger: the first brand change that has to be made by hand in two places. Until then the `ColorTokenTests` palette test is the drift guard (see Risks). |


## Risks

| Risk | Mitigation |
|---|---|
| Parity scope creep | Each slice ends at its acceptance row; anything new goes to an M6 list. |
| Token drift between the site and the app (found 2026-10-26: `surface` and `statusLive` were copied from raw hex values in CSS rules, and the site's live dot was a third red, `#bd5c3d`) | Primitives live only as `:root` variables in `wehoop-landing/app/globals.css` and as `BrandPalette`; the site now names `--cream` and `--rust`, and its live dot and focus ring use `--rust`; `ColorTokenTests` asserts every primitive and that shared semantic tokens resolve to a primitive. A generator is queued for M6. |
| Features hard-code the three leagues, so overseas lines later force a rewrite | `Domain.League` is data from the `leagues` table; features take `[League]` and never name one; `check-deps.sh` gains a grep that fails on a league literal (`"wnba"`, `.wnba`) inside `Feature*`. |
| `league:*:scores` is best-effort (a failed publish is not resent; the sender's watermark moves on) | **Closed in S5**: the app uses the channel, re-reads `v_schedule` on every join and foreground, and every 60 s while a game in the list is live, so a lost final status is bounded to a minute. |
| No production keys before beta | TestFlight testers watch simulation replays on the hosted worker; real data starts when keys exist. |
| Realtime private-channel behavior on cloud (a public channel still joined on 2026-10-21) | Recheck the dashboard toggle before S3; S3 evidence includes the reject test on cloud. **Closed 2026-11-02**: the cloud run refused public joins only after the setting was re-saved (dashboard showed it off before); guest publish refused, 0 forged heard (`devlog/evidence/M5.md` S3). |
| supabase-swift Swift 6 strictness | Wrap it inside WehoopData behind our protocols; pin an exact version. |
| No visual designs exist | Each feature slice starts with a quick mock in the Simulator for owner review before the build. |
