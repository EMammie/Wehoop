//
//  MainTabView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Main tab bar view with 5 tabs
struct MainTabView: View {
    @Environment(\.viewModelFactory) private var factory
    @Environment(\.theme) private var theme
    @State private var showBurgerMenu = false
    
    var body: some View {
        ZStack {
            TabView {
                GamesView(viewModel: factory.makeGamesViewModel())
                    .tabItem {
                        Label("Games", systemImage: "sportscourt")
                    }
                
                LeadersView(viewModel: factory.makeLeadersViewModel())
                    .tabItem {
                        Label("Leaders", systemImage: "trophy")
                    }
                
                PlayersView(viewModel: factory.makePlayersViewModel())
                    .tabItem {
                        Label("Players", systemImage: "person.3")
                    }
                
                TeamsView(viewModel: factory.makeTeamsViewModel())
                    .tabItem {
                        Label("Teams", systemImage: "shield")
                    }
                
                FavoritesView(viewModel: factory.makeFavoritesViewModel())
                    .tabItem {
                        Label("Favorites", systemImage: "star")
                    }
            }
            .tint(theme.colorScheme.accent) // Apply theme accent color to tab bar
            
            // Burger menu button (top trailing)
            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            showBurgerMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(theme.colorScheme.foreground)
                            .padding(12)
                            .background(theme.colorScheme.background.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                Spacer()
            }
            .zIndex(1)
            
            // Burger menu overlay
            BurgerMenuView(isPresented: $showBurgerMenu)
                .zIndex(2)
            #endif
        }
        .onShake {
            #if DEBUG
            withAnimation {
                showBurgerMenu.toggle()
            }
            #endif
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.theme, Theme.wehoop)
        .environment(\.dependencyContainer, configureDependencyContainer())
}
