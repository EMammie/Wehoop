//
//  SectionedCardFeedView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Card feed with sections support
struct SectionedCardFeedView<Item: Identifiable, SectionHeader: View>: View {
    let sections: [FeedSection<Item, SectionHeader>]
    let spacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let onRefresh: (() -> Void)?
    
    init(
        sections: [FeedSection<Item, SectionHeader>],
        spacing: CGFloat = 12,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16,
        onRefresh: (() -> Void)? = nil
    ) {
        self.sections = sections
        self.spacing = spacing
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    Section {
                        ForEach(section.items) { item in
                            section.cardContent(item)
                                .padding(.horizontal, horizontalPadding)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    } header: {
                        section.header
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, index > 0 ? 16 : 8)
                    }
                }
            }
            .padding(.vertical, verticalPadding)
            .animation(.easeInOut(duration: 0.3), value: sections.count)
        }
        .refreshable {
            onRefresh?()
        }
    }
}

#Preview("Sectioned Feed with Games") {
    let sampleGame1 = Game(
        id: "preview-game-1",
        homeTeam: Team(
            id: "team-1",
            name: "Lakers",
            abbreviation: "LAL",
            logoURL: nil,
            city: "Los Angeles",
            conference: .western,
            division: "Pacific",
            wins: 45,
            losses: 25,
            winPercentage: 0.643
        ),
        awayTeam: Team(
            id: "team-2",
            name: "Celtics",
            abbreviation: "BOS",
            logoURL: nil,
            city: "Boston",
            conference: .eastern,
            division: "Atlantic",
            wins: 48,
            losses: 22,
            winPercentage: 0.686
        ),
        date: Date(),
        status: .live,
        boxScore: BoxScore(
            homeScore: 85,
            awayScore: 92,
            homeStats: TeamStats(
                points: 85,
                rebounds: 38,
                assists: 18,
                steals: 5,
                blocks: 4,
                turnovers: 10,
                fieldGoalPercentage: 44.2,
                threePointPercentage: 36.5,
                freeThrowPercentage: 80.0,
                fouls: 12
            ),
            awayStats: TeamStats(
                points: 92,
                rebounds: 41,
                assists: 20,
                steals: 7,
                blocks: 6,
                turnovers: 8,
                fieldGoalPercentage: 50.8,
                threePointPercentage: 42.1,
                freeThrowPercentage: 85.7,
                fouls: 14
            ),
            quarters: nil,
            lastUpdated: Date()
        ),
        venue: "Crypto.com Arena",
        league: "Unrivaled",
        broadcastNetwork: "TNT",
        timeZone: "EST"
    )
    
    let sampleGame2 = Game(
        id: "preview-game-2",
        homeTeam: Team(
            id: "team-3",
            name: "Warriors",
            abbreviation: "GSW",
            logoURL: nil,
            city: "Golden State",
            conference: .western,
            division: "Pacific",
            wins: 42,
            losses: 28,
            winPercentage: 0.600
        ),
        awayTeam: Team(
            id: "team-4",
            name: "Heat",
            abbreviation: "MIA",
            logoURL: nil,
            city: "Miami",
            conference: .eastern,
            division: "Southeast",
            wins: 40,
            losses: 30,
            winPercentage: 0.571
        ),
        date: Date().addingTimeInterval(86400),
        status: .scheduled,
        boxScore: nil,
        venue: "Chase Center",
        league: "Unrivaled",
        broadcastNetwork: "TNT",
        timeZone: "EST"
    )
    
    SectionedCardFeedView(
        sections: [
            FeedSection(
                items: [sampleGame1],
                header: { LiveGamesHeader() },
                cardContent: { game in
                    GameCardView(game: game)
                }
            ),
            FeedSection(
                items: [sampleGame2],
                header: {
                  LiveGamesHeader() },
                  //AllGamesHeader(hasLiveGames: true) },
                cardContent: { game in
                    GameCardView(game: game)
                }
            )
        ],
        spacing: 16
    )
}
