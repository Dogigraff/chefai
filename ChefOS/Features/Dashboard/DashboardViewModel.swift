import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case analyzing
        case results([Recipe])
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.analyzing, .analyzing):
                return true
            case (.results(let l), .results(let r)):
                return l == r
            case (.error(let l), .error(let r)):
                return l == r
            default:
                return false
            }
        }
    }

    @Published private(set) var state: State = .idle

    private let aiService: OpenAIServiceProtocol
    private let storage: StorageService
    private let profileProvider: () -> UserProfile?

    init(aiService: OpenAIServiceProtocol, storage: StorageService, profileProvider: @escaping () -> UserProfile?) {
        self.aiService = aiService
        self.storage = storage
        self.profileProvider = profileProvider
    }

    func analyze(image: UIImage, barcodes: [String]) {
        state = .analyzing
        Task {
            do {
                guard let profile = profileProvider() else {
                    await MainActor.run { state = .error(String(localized: "error_profile_not_found")) }
                    return
                }
                let recipes = try await aiService.generateRecipes(from: image, barcodes: barcodes, userProfile: profile)
                storage.saveRecipes(recipes)
                await MainActor.run {
                    state = .results(recipes)
                }
            } catch {
                let cached = storage.loadRecipes()
                if !cached.isEmpty {
                    await MainActor.run {
                        state = .results(cached)
                    }
                    return
                }
                await MainActor.run {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    func reset() {
        state = .idle
    }
}

