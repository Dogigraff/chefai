import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    private let storage: StorageService

    init(storage: StorageService) {
        self.storage = storage
        load()
    }

    func load() {
        let stored = storage.loadRecipes()
        if stored.isEmpty {
            recipes = Recipe.mockPreviews
        } else {
            recipes = stored
        }
    }
}

