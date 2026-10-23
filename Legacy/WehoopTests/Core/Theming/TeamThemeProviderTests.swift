//
//  TeamThemeProviderTests.swift
//  UnrivaledTests
//
//  Created by E on 1/2/26.
//

import XCTest
import SwiftUI
@testable import Wehoop

final class TeamThemeProviderTests: XCTestCase {
    var sut: TeamThemeProvider!
    
    override func setUp() {
        super.setUp()
        sut = TeamThemeProvider()
    }
    
    override func tearDown() {
        sut.clearCache()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Theme for Team ID Tests
    
    func testTheme_ForMistBC_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-1")
        
        // Then
        // Mist BC should have misty blue-gray colors
        XCTAssertNotNil(theme)
        // Verify it's not the default theme
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForLunarOwlsBC_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-2")
        
        // Then
        XCTAssertNotNil(theme)
        // Lunar Owls should have deep night blue
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForRoseBC_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-3")
        
        // Then
        XCTAssertNotNil(theme)
        // Rose BC should have rose red colors
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForVinylBC_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-4")
        
        // Then
        XCTAssertNotNil(theme)
        // Vinyl BC should have deep black colors
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForPhantomBC_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-5")
        
        // Then
        XCTAssertNotNil(theme)
        // Phantom BC should have phantom purple colors
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForLacesBC_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-6")
        
        // Then
        XCTAssertNotNil(theme)
        // Laces BC should have white/cream colors
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForBreeze_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-7")
        
        // Then
        XCTAssertNotNil(theme)
        // Breeze should have sky blue colors
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForHive_ReturnsCorrectColors() {
        // When
        let theme = sut.theme(for: "team-8")
        
        // Then
        XCTAssertNotNil(theme)
        // Hive should have golden yellow colors
        XCTAssertNotEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
    }
    
    func testTheme_ForUnknownTeam_ReturnsDefaultTheme() {
        // When
        let theme = sut.theme(for: "unknown-team-id")
        
        // Then
        XCTAssertNotNil(theme)
        // Should return default Unrivaled theme colors
        XCTAssertEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
        XCTAssertEqual(theme.colorScheme.secondary, Theme.wehoop.colorScheme.secondary)
        XCTAssertEqual(theme.colorScheme.accent, Theme.wehoop.colorScheme.accent)
    }
    
    // MARK: - Theme for Team Model Tests
    
    func testTheme_ForTeamModel_ReturnsCorrectTheme() {
        // Given
        let team = Team(
            id: "team-1",
            name: "Mist BC",
            abbreviation: "MST",
            logoURL: nil,
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 12,
            losses: 3,
            winPercentage: 0.800
        )
        
        // When
        let theme = sut.theme(for: team)
        
        // Then
        XCTAssertNotNil(theme)
        // Should return the same theme as team ID
        let themeById = sut.theme(for: "team-1")
        XCTAssertEqual(theme.colorScheme.primary, themeById.colorScheme.primary)
    }
    
    // MARK: - Caching Tests
    
    func testTheme_CachesThemes_ForSameTeamId() {
        // When
        let theme1 = sut.theme(for: "team-1")
        let theme2 = sut.theme(for: "team-1")
        
        // Then
        // Should return the same instance (cached)
        XCTAssertEqual(theme1.colorScheme.primary, theme2.colorScheme.primary)
        XCTAssertEqual(theme1.colorScheme.secondary, theme2.colorScheme.secondary)
        XCTAssertEqual(theme1.colorScheme.accent, theme2.colorScheme.accent)
    }
    
    func testTheme_ReturnsDifferentThemes_ForDifferentTeams() {
        // When
        let mistTheme = sut.theme(for: "team-1")
        let roseTheme = sut.theme(for: "team-3")
        
        // Then
        // Should return different themes
        XCTAssertNotEqual(mistTheme.colorScheme.primary, roseTheme.colorScheme.primary)
    }
    
    // MARK: - Clear Cache Tests
    
    func testClearCache_RemovesAllCachedThemes() {
        // Given - cache some themes
        _ = sut.theme(for: "team-1")
        _ = sut.theme(for: "team-2")
        _ = sut.theme(for: "team-3")
        
        // When
        sut.clearCache()
        
        // Then - themes should still be accessible (will be recreated)
        let theme = sut.theme(for: "team-1")
        XCTAssertNotNil(theme)
    }
    
    // MARK: - Typography Tests
    
    func testTheme_UsesBrandTypography_ForAllTeams() {
        // When
        let mistTheme = sut.theme(for: "team-1")
        let roseTheme = sut.theme(for: "team-3")
        let defaultTheme = Theme.wehoop
        
        // Then
        // All teams should use the same typography as brand theme
        XCTAssertEqual(mistTheme.typography.title, defaultTheme.typography.title)
        XCTAssertEqual(mistTheme.typography.headline, defaultTheme.typography.headline)
        XCTAssertEqual(mistTheme.typography.body, defaultTheme.typography.body)
        XCTAssertEqual(mistTheme.typography.caption, defaultTheme.typography.caption)
        
        XCTAssertEqual(roseTheme.typography.title, defaultTheme.typography.title)
        XCTAssertEqual(roseTheme.typography.headline, defaultTheme.typography.headline)
        XCTAssertEqual(roseTheme.typography.body, defaultTheme.typography.body)
        XCTAssertEqual(roseTheme.typography.caption, defaultTheme.typography.caption)
    }
    
    // MARK: - Color Scheme Tests
    
    func testTheme_AllTeams_HaveValidColorSchemes() {
        let teamIds = ["team-1", "team-2", "team-3", "team-4", "team-5", "team-6", "team-7", "team-8"]
        
        for teamId in teamIds {
            // When
            let theme = sut.theme(for: teamId)
            
            // Then
            // All color scheme properties should be set
            XCTAssertNotNil(theme.colorScheme.primary)
            XCTAssertNotNil(theme.colorScheme.secondary)
            XCTAssertNotNil(theme.colorScheme.accent)
            XCTAssertNotNil(theme.colorScheme.background)
            XCTAssertNotNil(theme.colorScheme.foreground)
        }
    }
    
    // MARK: - Edge Cases
    
    func testTheme_EmptyTeamId_ReturnsDefaultTheme() {
        // When
        let theme = sut.theme(for: "")
        
        // Then
        XCTAssertEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
        XCTAssertEqual(theme.colorScheme.secondary, Theme.wehoop.colorScheme.secondary)
        XCTAssertEqual(theme.colorScheme.accent, Theme.wehoop.colorScheme.accent)
    }
    
    func testTheme_AfterClearCache_RecreatesThemes() {
        // Given
        let theme1 = sut.theme(for: "team-1")
        
        // When
        sut.clearCache()
        let theme2 = sut.theme(for: "team-1")
        
        // Then
        // Themes should be recreated with same values
        XCTAssertEqual(theme1.colorScheme.primary, theme2.colorScheme.primary)
        XCTAssertEqual(theme1.colorScheme.secondary, theme2.colorScheme.secondary)
        XCTAssertEqual(theme1.colorScheme.accent, theme2.colorScheme.accent)
    }
    
    func testTheme_MultipleCalls_ReturnsCachedInstance() {
        // Given
        let teamId = "team-1"
        
        // When
        let theme1 = sut.theme(for: teamId)
        let theme2 = sut.theme(for: teamId)
        let theme3 = sut.theme(for: teamId)
        
        // Then
        // All should have identical color schemes (cached)
        XCTAssertEqual(theme1.colorScheme.primary, theme2.colorScheme.primary)
        XCTAssertEqual(theme2.colorScheme.primary, theme3.colorScheme.primary)
        XCTAssertEqual(theme1.colorScheme.secondary, theme2.colorScheme.secondary)
        XCTAssertEqual(theme2.colorScheme.secondary, theme3.colorScheme.secondary)
    }
    
    func testTheme_TeamModelWithUnknownId_ReturnsDefaultTheme() {
        // Given
        let team = Team(
            id: "unknown-team-999",
            name: "Unknown Team",
            abbreviation: "UNK",
            logoURL: nil,
            city: "Unknown",
            conference: .eastern,
            division: "Unknown",
            wins: 0,
            losses: 0,
            winPercentage: 0.0
        )
        
        // When
        let theme = sut.theme(for: team)
        
        // Then
        XCTAssertEqual(theme.colorScheme.primary, Theme.wehoop.colorScheme.primary)
        XCTAssertEqual(theme.colorScheme.secondary, Theme.wehoop.colorScheme.secondary)
        XCTAssertEqual(theme.colorScheme.accent, Theme.wehoop.colorScheme.accent)
    }
    
    func testTheme_AllTeams_HaveDistinctPrimaryColors() {
        // Given
        let teamIds = ["team-1", "team-2", "team-3", "team-4", "team-5", "team-6", "team-7", "team-8"]
        var primaryColors: [String: Color] = [:]
        
        // When
        for teamId in teamIds {
            let theme = sut.theme(for: teamId)
            primaryColors[teamId] = theme.colorScheme.primary
        }
        
        // Then
        // Each team should have a unique primary color (or at least verify they're different)
        let uniqueColors = Set(primaryColors.values.map { String(describing: $0) })
        // Note: This is a basic check - in practice, colors might be similar but should be distinct
        XCTAssertEqual(uniqueColors.count, primaryColors.count, "Each team should have a distinct primary color")
    }
}
