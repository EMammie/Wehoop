//
//  ViewModelFactory.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Factory for creating ViewModels with proper dependency injection
struct ViewModelFactory {
    let container: DependencyContainer
    
    func makeGamesViewModel() -> GamesViewModel {
        let useCase: GetGamesUseCase = container.resolve()
        // RealTimeUpdateService is optional - will be nil if not registered
        let realTimeService: RealTimeUpdateService?
        if container.isRegistered(RealTimeUpdateService.self) {
            realTimeService = container.resolve() as RealTimeUpdateService
        } else {
            realTimeService = nil
        }
        return GamesViewModel(getGamesUseCase: useCase, realTimeUpdateService: realTimeService)
    }
    
    func makeLeadersViewModel() -> LeadersViewModel {
        let useCase: GetStatLeadersUseCase = container.resolve()
        return LeadersViewModel(getStatLeadersUseCase: useCase)
    }
    
    func makePlayersViewModel() -> PlayersViewModel {
        let repository: PlayerRepository = container.resolve()
        return PlayersViewModel(playerRepository: repository)
    }
    
    func makeTeamsViewModel() -> TeamsViewModel {
        let repository: TeamRepository = container.resolve()
        return TeamsViewModel(teamRepository: repository)
    }
    
    func makeFavoritesViewModel() -> FavoritesViewModel {
        let manageFavoritesUseCase: ManageFavoritesUseCase = container.resolve()
        let playerRepository: PlayerRepository = container.resolve()
        return FavoritesViewModel(manageFavoritesUseCase: manageFavoritesUseCase, playerRepository: playerRepository)
    }
    
    func makePlayerProfileViewModel(playerId: String) -> PlayerProfileViewModel {
        let playerRepository: PlayerRepository = container.resolve()
        let useCase = GetPlayerProfileUseCase(playerRepository: playerRepository, playerId: playerId)
        return PlayerProfileViewModel(playerId: playerId, getPlayerProfileUseCase: useCase)
    }
    
    func makeTeamPageViewModel(teamId: String) -> TeamPageViewModel {
        let teamRepository: TeamRepository = container.resolve()
        let useCase = GetTeamPageUseCase(teamRepository: teamRepository, teamId: teamId)
        return TeamPageViewModel(teamId: teamId, getTeamPageUseCase: useCase)
    }
}
