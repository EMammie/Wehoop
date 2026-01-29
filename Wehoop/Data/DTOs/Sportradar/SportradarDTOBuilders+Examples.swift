//
//  SportradarDTOBuilders+Examples.swift
//  WehoopTests
//
//  Example usage of the builder pattern for Sportradar DTOs
//

import Foundation
@testable import Wehoop

/*
 MARK: - Example Usage in Tests
 
 Below are examples showing how to refactor your existing tests to use the builder pattern.
 This makes tests more readable, maintainable, and less error-prone.
 
 ## Before (Old Approach - Verbose and Error-Prone):
 
 ```swift
 func testFetchLeagueLeaders_Success() async throws {
     let leadersResponse = SportradarLeagueLeadersDTO(
         category: "points",
         leaders: [
             SportradarLeagueLeadersDTO.SportradarLeaderDTO(
                 player: SportradarPlayerDTO(
                     id: "player-1",
                     fullName: "Top Scorer",
                     firstName: "Top",
                     lastName: "Scorer",
                     position: "G",
                     jerseyNumber: "1",
                     height: "72",
                     weight: "180",
                     age: 25,
                     birthDate: nil,
                     birthPlace: nil,
                     college: nil,
                     photo: nil,
                     team: SportradarTeamReferenceDTO(id: "team-1", name: "Team One", alias: "T1"),
                     teamId: "team-1",
                     statistics: nil,
                     averages: nil
                 ),
                 playerId: "player-1",
                 value: 25.5,
                 rank: 1
             )
         ]
     )
     // ... rest of test
 }
 ```
 
 ## After (Builder Pattern - Clean and Expressive):
 
 ```swift
 @MainActor
 func testFetchLeagueLeaders_Success() async throws {
     let leadersResponse = SportradarLeagueLeadersBuilder()
         .addCategory("points") { category in
             category.addLeader(rank: 1, score: 25.5) { leader in
                 leader
                     .withPlayer(id: "player-1", fullName: "Top Scorer", position: "G", jerseyNumber: "1")
                     .addTeam(id: "team-1", name: "Team One")
             }
         }
         .build()
     
     // ... rest of test
 }
 ```
 
 Or even simpler using the convenience method:
 
 ```swift
 @MainActor
 func testFetchLeagueLeaders_Success() async throws {
     let leadersResponse = SportradarLeagueLeadersBuilder.simplePointsLeader(
         playerId: "player-1",
         playerName: "Top Scorer",
         score: 25.5
     )
     
     // ... rest of test
 }
 ```
 
 ## More Examples:
 
 ### Example 1: Multiple Leaders
 ```swift
 @MainActor
 let leadersResponse = SportradarLeagueLeadersBuilder()
     .withSeason(year: 2025, type: "REG")
     .addCategory("points") { category in
         category
             .addLeader(rank: 1, score: 25.5) { leader in
                 leader.withPlayer(id: "player-1", fullName: "Top Scorer")
             }
             .addLeader(rank: 2, score: 24.3) { leader in
                 leader.withPlayer(id: "player-2", fullName: "Second Scorer")
             }
     }
     .build()
 ```
 
 ### Example 2: Multiple Categories
 ```swift
 @MainActor
 let leadersResponse = SportradarLeagueLeadersBuilder()
     .addCategory("points") { category in
         category.addLeader(rank: 1, score: 25.5) { leader in
             leader.withPlayer(id: "player-1", fullName: "Top Scorer")
         }
     }
     .addCategory("rebounds") { category in
         category.addLeader(rank: 1, score: 12.5) { leader in
             leader.withPlayer(id: "player-2", fullName: "Top Rebounder", position: "F")
         }
     }
     .addCategory("assists") { category in
         category.addLeader(rank: 1, score: 8.5) { leader in
             leader.withPlayer(id: "player-3", fullName: "Top Passer", position: "G")
         }
     }
     .build()
 ```
 
 ### Example 3: Empty Response
 ```swift
 @MainActor
 let emptyResponse = SportradarLeagueLeadersBuilder.empty()
 ```
 
 ### Example 4: Empty Categories (No Leaders)
 ```swift
 @MainActor
 let emptyCategories = SportradarLeagueLeadersBuilder()
     .addCategory("points")  // Category exists but has no leaders
     .build()
 ```
 
 ### Example 5: Leader with Statistics
 ```swift
 @MainActor
 let leadersWithStats = SportradarLeagueLeadersBuilder()
     .addCategory("points") { category in
         category.addLeader(rank: 1, score: 25.5) { leader in
             leader
                 .withPlayer(id: "player-1", fullName: "Top Scorer")
                 .withStatistics(gamesPlayed: 10, points: 255, rebounds: 80, assists: 50)
                 .withAverages(points: 25.5, rebounds: 8.0, assists: 5.0)
         }
     }
     .build()
 ```
 
 ### Example 6: Leader without Player (for testing edge cases)
 ```swift
 @MainActor
 let leadersResponse = SportradarLeagueLeadersBuilder()
     .addCategory("assists") { category in
         category.addLeader(rank: 1, score: 8.5) { leader in
             // Don't call withPlayer - tests the nil player case
             leader  // leader has no player set
         }
     }
     .build()
 ```
 
 ### Example 7: Teams Response Builder
 ```swift
 @MainActor
 let teamsResponse = SportradarTeamsResponseBuilder()
     .addTeam(id: "team-1", name: "Team One", alias: "T1", market: "City One", wins: 10, losses: 5)
     .addTeam(id: "team-2", name: "Team Two", alias: "T2", market: "City Two", wins: 8, losses: 7)
     .build()
 ```
 
 ## Benefits of This Approach:
 
 1. **Readability**: Tests read like documentation
 2. **Maintainability**: When API changes, update builder once, not every test
 3. **Type Safety**: Compiler catches errors at build time
 4. **Flexibility**: Easy to create variations for edge cases
 5. **Reusability**: Common scenarios can be extracted to static methods
 6. **Less Boilerplate**: No need to specify all optional parameters as nil
 7. **Clear Intent**: The test clearly shows what matters for that specific test case
 
 ## Refactoring Guide:
 
 To refactor existing tests:
 
 1. Find the test that creates SportradarLeagueLeadersDTO
 2. Replace with builder pattern
 3. Add @MainActor to the test function if needed (for Swift 6 concurrency)
 4. Keep the rest of the test logic the same
 
 Example refactor:
 
 ```swift
 // OLD
 func testFetchLeagueLeaders_EmptyLeaders() async throws {
     let emptyLeadersResponse = SportradarLeagueLeadersDTO(
         category: "points",
         leaders: []
     )
     // ... rest
 }
 
 // NEW
 @MainActor
 func testFetchLeagueLeaders_EmptyLeaders() async throws {
     let emptyLeadersResponse = SportradarLeagueLeadersBuilder()
         .addCategory("points")  // No leaders added
         .build()
     // ... rest
 }
 ```
 */
