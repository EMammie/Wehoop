//
//  TeamRepositoryImpl.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation

/// Implementation of TeamRepository
class TeamRepositoryImpl: TeamRepository {
    private let remoteDataSource: RemoteDataSource
    private let localDataSource: LocalDataSource
    private let cacheService: CacheService
    
    /// Cache staleness threshold: 30 minutes (teams change less frequently)
    private let cacheStalenessThreshold: TimeInterval = 30 * 60
    
    init(remoteDataSource: RemoteDataSource, localDataSource: LocalDataSource, cacheService: CacheService) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.cacheService = cacheService
    }
    
    func getTeams() async throws -> [Team] {
        let cacheKey = "teams_all"
        
        // Check cache first - return if fresh
        if let cachedTeams: [Team] = cacheService.get([Team].self, forKey: cacheKey),
           !cacheService.isStale(forKey: cacheKey, maxAge: cacheStalenessThreshold) {
            return cachedTeams
        }
        
        // Cache is stale or empty - try remote first
        var teams: [Team] = []
        
        do {
            let remoteData = try await remoteDataSource.fetchTeams()
            let decoder = JSONDecoder()
            let teamDTOs = try decoder.decode([TeamDTO].self, from: remoteData)
            teams = try teamDTOs.map { try $0.toDomain() }
            
            // Persist to cache
            if !teams.isEmpty {
                cacheService.set(teams, forKey: cacheKey, expiration: 1800) // 30 minutes cache
            }
            
            // Persist to writable local data source if available
            if let writableDataSource = localDataSource as? WritableLocalDataSource {
                try writableDataSource.saveTeams(remoteData)
            }
            
            return teams
        } catch {
            // Remote failed - fall back to local data source
            if let localData = try localDataSource.loadTeams() {
                let decoder = JSONDecoder()
                let teamDTOs = try decoder.decode([TeamDTO].self, from: localData)
                teams = try teamDTOs.map { try $0.toDomain() }
                
                // Cache the local data
                if !teams.isEmpty {
                    cacheService.set(teams, forKey: cacheKey, expiration: 1800)
                }
                
                return teams
            }
            
            // Both remote and local failed - throw error
            throw error
        }
    }
    
    func getTeam(id: String) async throws -> Team {
        let cacheKey = "team_\(id)"
        
        // Check cache first - return if fresh
        if let cachedTeam: Team = cacheService.get(Team.self, forKey: cacheKey),
           !cacheService.isStale(forKey: cacheKey, maxAge: cacheStalenessThreshold) {
            return cachedTeam
        }
        
        // If data source supports team profiles, try fetching directly (more efficient)
        if let profileDataSource = remoteDataSource as? TeamProfileDataSource {
            do {
                let remoteData = try await profileDataSource.fetchTeamProfile(teamId: id)
                let decoder = JSONDecoder()
                let teamDTO = try decoder.decode(TeamDTO.self, from: remoteData)
                let team = try teamDTO.toDomain()
                cacheService.set(team, forKey: cacheKey, expiration: 1800)
                
                // Persist to writable local data source if available
                if let writableDataSource = localDataSource as? WritableLocalDataSource {
                    try writableDataSource.saveTeams(remoteData)
                }
                
                return team
            } catch {
                // Profile fetch failed, fall through to other methods
            }
        }
        
        // Try to get from all teams first
        let allTeams = try await getTeams()
        if let team = allTeams.first(where: { $0.id == id }) {
            cacheService.set(team, forKey: cacheKey, expiration: 1800)
            return team
        }
        
        // If not found in teams list, try fetching directly from data sources
        // Try local data source
        if let localData = try localDataSource.loadTeams() {
            let decoder = JSONDecoder()
            let teamDTOs = try decoder.decode([TeamDTO].self, from: localData)
            if let teamDTO = teamDTOs.first(where: { $0.id == id }) {
                let team = try teamDTO.toDomain()
                cacheService.set(team, forKey: cacheKey, expiration: 1800)
                return team
            }
        }
        
        // Try remote data source (fallback to fetching all teams)
        do {
            let remoteData = try await remoteDataSource.fetchTeams()
            let decoder = JSONDecoder()
            let teamDTOs = try decoder.decode([TeamDTO].self, from: remoteData)
            if let teamDTO = teamDTOs.first(where: { $0.id == id }) {
                let team = try teamDTO.toDomain()
                cacheService.set(team, forKey: cacheKey, expiration: 1800)
                return team
            }
        } catch {
            // Remote fetch failed
        }
        
        throw NSError(domain: "TeamRepositoryError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Team not found: \(id)"])
    }
}
