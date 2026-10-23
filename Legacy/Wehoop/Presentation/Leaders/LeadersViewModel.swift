//
//  LeadersViewModel.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import Foundation
import Combine

/// ViewModel for LeadersView
@MainActor
class LeadersViewModel: ObservableObject {
    @Published var leaders: [Player] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedCategory: StatCategory = .scoring
    
    private let getStatLeadersUseCase: GetStatLeadersUseCase
    
    init(getStatLeadersUseCase: GetStatLeadersUseCase) {
        self.getStatLeadersUseCase = getStatLeadersUseCase
    }
    
    func loadLeaders(category: StatCategory) {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        selectedCategory = category
        
        Task {
            do {
                let loadedLeaders = try await getStatLeadersUseCase.execute(category: category)
                self.leaders = loadedLeaders
                self.isLoading = false
            } catch {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    func refreshLeaders() {
        loadLeaders(category: selectedCategory)
    }
    
    var hasLeaders: Bool {
        !leaders.isEmpty
    }
}
