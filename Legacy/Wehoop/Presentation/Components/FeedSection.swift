//
//  FeedSection.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Model for a feed section with items, header, and card content
struct FeedSection<Item: Identifiable, Header: View> {
    let items: [Item]
    let header: Header
    let cardContent: (Item) -> AnyView
    
    init(
        items: [Item],
        @ViewBuilder header: () -> Header,
        @ViewBuilder cardContent: @escaping (Item) -> some View
    ) {
        self.items = items
        self.header = header()
        self.cardContent = { AnyView(cardContent($0)) }
    }
}

#Preview("FeedSection with Games") {
    let sampleGame = Game(
        id: "preview-game",
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
        status: .finished,
        boxScore: nil,
        venue: "Crypto.com Arena",
        league: "Unrivaled",
        broadcastNetwork: "TNT",
        timeZone: "EST"
    )
    
    let section = FeedSection(
        items: [sampleGame],
        header: {
            HStack {
                Text("Sample Section")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
        },
        cardContent: { game in
            GameCardView(game: game)
        }
    )
    
    return ScrollView {
        LazyVStack {
            Section {
                ForEach(section.items) { item in
                    section.cardContent(item)
                        .padding(.horizontal)
                }
            } header: {
                section.header
            }
        }
        .padding()
    }
}
