/// Domain: the app's entities as `Sendable` value types and the `Sendable`, `async throws`
/// repository protocols the features depend on (docs/M5-PLAN.md, "Modules").
/// Foundation only: no formatting, no provider strings, no networking. Absent stats are
/// `nil`, never 0. Nothing here names a league: `League` is data from the `leagues` table.
///
/// S3 adds what WehoopData maps into first: typed ids, `League`, `Game` and its status,
/// coverage, period and clock, `PlayerSummary`, and the repository protocols for the
/// schedule, leagues, players, favorites and live games. Stat lines, standings, season
/// lines and tournaments arrive with the screens that read them (S4, S6).
