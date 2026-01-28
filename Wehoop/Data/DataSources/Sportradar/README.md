# Sportradar API Client

Client for building Sportradar Unrivaled API endpoint URLs following the official URL pattern.

## URL Pattern

```
{base}/{access}/{version}/{language}/{resource}/{path}/{endpoint}
```

**Example:**
```
https://api.sportradar.com/unrivaled/trial/v8/en/league/2026/01/16/changes.json
```

### Components

- **base**: `https://api.sportradar.com/unrivaled` (from APIConfiguration)
- **access**: `trial` or `production` (defaults to `trial`)
- **version**: `v8` (from APIConfiguration)
- **language**: `en` (defaults to English)
- **resource**: `league`, `teams`, `players`, `games`, `tournaments`, `series`
- **path**: Additional path components (dates, IDs, etc.)
- **endpoint**: JSON file name (e.g., `changes.json`, `teams.json`)

## Usage

```swift
// Initialize client
let config = try APIConfiguration()
let client = SportradarAPIClient(
    apiConfiguration: config,
    accessLevel: .trial,  // or .production
    language: .english
)

// Build URLs
let teamsURL = client.teams()
let dailyChangesURL = client.dailyChanges(date: Date())
let gameBoxscoreURL = client.gameBoxscore(gameId: "game-123")
```

## Available Endpoints

### Daily Endpoints
- `dailyChanges(date:)` - Daily change log
- `dailyInjuries(date:)` - Daily injuries
- `dailySchedule(date:)` - Daily schedule
- `dailyTransfers(date:)` - Daily transfers

### Game Endpoints
- `gameBoxscore(gameId:)` - Game boxscore
- `gameSummary(gameId:)` - Game summary
- `gamePlayByPlay(gameId:)` - Play-by-play

### Team Endpoints
- `teams()` - Complete list of teams
- `teamProfile(teamId:)` - Team profile
- `teamRoster(teamId:)` - Team roster

### Player Endpoints
- `playerProfile(playerId:)` - Player profile

### League Endpoints
- `leagueHierarchy()` - League hierarchy
- `leagueLeaders(seasonYear:seasonType:)` - League leaders for a specific season (e.g., `leagueLeaders(seasonYear: "2026", seasonType: "REG")`)
- `standings()` - Standings
- `rankings()` - Rankings
- `seasonalStatistics(seasonId:seasonType:)` - Seasonal statistics
- `seasons()` - Available seasons
- `schedule(seasonId:)` - Full season schedule
- `injuries()` - Active injuries

### Series Endpoints
- `seriesSchedule(seriesId:)` - Series schedule
- `seriesStatistics(seriesId:)` - Series statistics

### Tournament Endpoints
- `tournamentList(seasonId:)` - Tournament list
- `tournamentSchedule(tournamentId:)` - Tournament schedule
- `tournamentSummary(tournamentId:)` - Tournament summary

## Examples

```swift
// Daily changes for January 16, 2026
let date = DateComponents(calendar: .current, year: 2026, month: 1, day: 16).date!
let url = client.dailyChanges(date: date)
// Result: https://api.sportradar.com/unrivaled/trial/v8/en/league/2026/01/16/changes.json

// Team profile
let url = client.teamProfile(teamId: "team-123")
// Result: https://api.sportradar.com/unrivaled/trial/v8/en/teams/team-123/profile.json

// Game boxscore
let url = client.gameBoxscore(gameId: "game-456")
// Result: https://api.sportradar.com/unrivaled/trial/v8/en/games/game-456/boxscore.json

// League leaders for 2026 regular season
let url = client.leagueLeaders(seasonYear: "2026", seasonType: "REG")
// Result: https://api.sportradar.com/unrivaled/trial/v8/en/seasons/2026/REG/leaders.json
```

## Configuration

The client uses `APIConfiguration` for:
- Base URL
- API version (v8)
- API key (passed to NetworkService for headers)

Access level and language can be customized per client instance.

## Testing

See `SportradarAPIClientTests.swift` for comprehensive test coverage of all endpoints.
