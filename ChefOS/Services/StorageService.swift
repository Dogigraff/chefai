import Foundation
import SwiftData

protocol StorageService {
    func saveUserProfile(_ profile: UserProfile)
    func loadUserProfile() -> UserProfile?
    func saveIngredientsCache(_ ingredients: [String])
    func loadIngredientsCache() -> [String]
    func saveRecipes(_ recipes: [Recipe])
    func loadRecipes() -> [Recipe]
}

final class InMemoryStorageService: StorageService {
    private var profile: UserProfile?
    private var ingredients: [String] = []
    private var recipes: [Recipe] = []

    func saveUserProfile(_ profile: UserProfile) {
        self.profile = profile
    }

    func loadUserProfile() -> UserProfile? {
        profile
    }

    func saveIngredientsCache(_ ingredients: [String]) {
        self.ingredients = ingredients
    }

    func loadIngredientsCache() -> [String] {
        ingredients
    }

    func saveRecipes(_ recipes: [Recipe]) {
        self.recipes = recipes
    }

    func loadRecipes() -> [Recipe] {
        recipes
    }
}

// MARK: - SwiftData-backed Storage

@MainActor
final class SwiftDataStorageService: StorageService {
    let modelContainer: ModelContainer

    init(container: ModelContainer) {
        self.modelContainer = container
    }

    private var context: ModelContext { modelContainer.mainContext }

    func saveUserProfile(_ profile: UserProfile) {
        // Replace existing profile with new one
        if let existing = try? context.fetch(FetchDescriptor<StoredUserProfile>()).first {
            context.delete(existing)
        }
        context.insert(StoredUserProfile(from: profile))
        try? context.save()
    }

    func loadUserProfile() -> UserProfile? {
        guard let stored = try? context.fetch(FetchDescriptor<StoredUserProfile>()).first else {
            return nil
        }
        return stored.toDomain()
    }

    func saveIngredientsCache(_ ingredients: [String]) {
        saveCache(type: .ingredients, payload: ingredients)
    }

    func loadIngredientsCache() -> [String] {
        loadCache(type: .ingredients, as: [String].self) ?? []
    }

    func saveRecipes(_ recipes: [Recipe]) {
        saveCache(type: .recipes, payload: recipes)
    }

    func loadRecipes() -> [Recipe] {
        loadCache(type: .recipes, as: [Recipe].self) ?? []
    }

    // MARK: - Cache Helpers

    private func saveCache<T: Codable>(type: StoredCache.CacheType, payload: T) {
        if let existing = try? context.fetch(FetchDescriptor<StoredCache>(predicate: #Predicate { $0.type == type.rawValue })).first {
            context.delete(existing)
        }
        guard let data = try? JSONEncoder().encode(payload) else { return }
        context.insert(StoredCache(type: type.rawValue, payload: data))
        try? context.save()
    }

    private func loadCache<T: Codable>(type: StoredCache.CacheType, as _: T.Type) -> T? {
        guard
            let cache = try? context.fetch(FetchDescriptor<StoredCache>(predicate: #Predicate { $0.type == type.rawValue })).first,
            let decoded = try? JSONDecoder().decode(T.self, from: cache.payload)
        else {
            return nil
        }
        return decoded
    }
}

// MARK: - SwiftData Models

@Model
final class StoredUserProfile {
    var id: UUID
    var medicalConditions: [String]
    var religion: String
    var allergens: [String]
    var equipment: [String]
    var likes: [String]
    var dislikes: [String]
    var pantrySalt: Bool
    var pantrySugarSubstitute: Bool
    var pantryOil: Bool
    var pantryWater: Bool

    init(from profile: UserProfile) {
        self.id = UUID()
        self.medicalConditions = profile.medicalConditions.map { $0.rawValue }
        self.religion = profile.religion.rawValue
        self.allergens = profile.allergens
        self.equipment = profile.equipment.map { $0.rawValue }
        self.likes = Array(profile.tasteProfile.likes.map(\.rawValue))
        self.dislikes = Array(profile.tasteProfile.dislikes.map(\.rawValue))
        self.pantrySalt = profile.pantryBasics.salt
        self.pantrySugarSubstitute = profile.pantryBasics.sugarSubstitute
        self.pantryOil = profile.pantryBasics.oil
        self.pantryWater = profile.pantryBasics.water
    }

    func toDomain() -> UserProfile {
        var taste = TasteProfile()
        taste.likes = Set(likes.compactMap { TasteOption(rawValue: $0) })
        taste.dislikes = Set(dislikes.compactMap { TasteOption(rawValue: $0) })

        return UserProfile(
            medicalConditions: medicalConditions.compactMap { MedicalCondition(rawValue: $0) },
            religion: Religion(rawValue: religion) ?? .none,
            allergens: allergens,
            equipment: equipment.compactMap { Equipment(rawValue: $0) },
            tasteProfile: taste,
            pantryBasics: PantryBasics(
                salt: pantrySalt,
                sugarSubstitute: pantrySugarSubstitute,
                oil: pantryOil,
                water: pantryWater
            )
        )
    }
}

@Model
final class StoredCache {
    enum CacheType: String {
        case ingredients
        case recipes
    }

    var id: UUID
    var type: String
    var payload: Data

    init(type: String, payload: Data) {
        self.id = UUID()
        self.type = type
        self.payload = payload
    }
}

