import Foundation

enum MedicalCondition: String, CaseIterable, Identifiable, Codable {
    case diabetesType1 = "Diabetes Type 1"
    case diabetesType2 = "Diabetes Type 2"
    case hypertension = "Hypertension"
    case gastritis = "Gastritis"
    case lactoseIntolerance = "Lactose Intolerance"
    case glutenSensitivity = "Gluten Sensitivity"
    case nutAllergy = "Nut Allergy"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .diabetesType1: return String(localized: "cond_diabetes_1")
        case .diabetesType2: return String(localized: "cond_diabetes_2")
        case .hypertension: return String(localized: "cond_hypertension")
        case .gastritis: return String(localized: "cond_gastritis")
        case .lactoseIntolerance: return String(localized: "cond_lactose")
        case .glutenSensitivity: return String(localized: "cond_gluten")
        case .nutAllergy: return String(localized: "cond_nut_allergy")
        }
    }
}

enum Religion: String, CaseIterable, Identifiable, Codable {
    case halal = "Halal"
    case kosher = "Kosher"
    case none = "None"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .halal: return String(localized: "rel_halal")
        case .kosher: return String(localized: "rel_kosher")
        case .none: return String(localized: "rel_none")
        }
    }
}

enum Equipment: String, CaseIterable, Identifiable, Codable {
    case oven = "Oven"
    case blender = "Blender"
    case multicooker = "Multicooker"
    case microwave = "Microwave"
    case stove = "Stove"
    case airFryer = "Air Fryer"
    case knife = "Chef Knife"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .oven: return String(localized: "eq_oven")
        case .blender: return String(localized: "eq_blender")
        case .multicooker: return String(localized: "eq_multicooker")
        case .microwave: return String(localized: "eq_microwave")
        case .stove: return String(localized: "eq_stove")
        case .airFryer: return String(localized: "eq_airfryer")
        case .knife: return String(localized: "eq_knife")
        }
    }
}

enum TasteOption: String, CaseIterable, Identifiable, Codable {
    case spicy = "Spicy"
    case sweet = "Sweet"
    case meat = "Meat"
    case veg = "Vegetarian"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .spicy: return String(localized: "taste_spicy")
        case .sweet: return String(localized: "taste_sweet")
        case .meat: return String(localized: "taste_meat")
        case .veg: return String(localized: "taste_veg")
        }
    }
}

struct TasteProfile: Codable, Equatable {
    var likes: Set<TasteOption> = []
    var dislikes: Set<TasteOption> = []
}

struct PantryBasics: Codable, Equatable {
    var salt: Bool = true
    var sugarSubstitute: Bool = true
    var oil: Bool = true
    var water: Bool = true
}

struct UserProfile: Codable, Equatable {
    var medicalConditions: [MedicalCondition] = []
    var religion: Religion = .none
    var allergens: [String] = []
    var equipment: [Equipment] = []
    var tasteProfile: TasteProfile = .init()
    var pantryBasics: PantryBasics = .init()
}

enum RecipeStyle: String, Codable, Identifiable {
    case fast
    case healthy
    case gourmet

    var id: String { rawValue }
}

struct Ingredient: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let quantity: String

    init(id: UUID = UUID(), name: String, quantity: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
}

struct Step: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let timerSeconds: Int?
    let warning: String?

    init(id: UUID = UUID(), text: String, timerSeconds: Int? = nil, warning: String? = nil) {
        self.id = id
        self.text = text
        self.timerSeconds = timerSeconds
        self.warning = warning
    }
}

struct Nutrition: Codable, Equatable {
    let calories: Int
    let glycemicIndex: Int?
    let sugarGrams: Double?
}

struct Recipe: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let style: RecipeStyle
    let matchScore: Int

    let ingredients: [Ingredient]
    let missingIngredients: [Ingredient]

    let steps: [Step]
    let nutrition: Nutrition

    let smartSubstitutions: [String: String]
    let substitutionReasons: [String: String]
    let chefTips: String
}

extension Recipe {
    static let mockPreviews: [Recipe] = {
        let ingredient = Ingredient(name: "Tomato", quantity: "2 pcs")
        let step = Step(text: "Slice and cook.", timerSeconds: 300, warning: nil)
        let nutrition = Nutrition(calories: 320, glycemicIndex: 40, sugarGrams: 8)
        return [
            Recipe(
                id: UUID(),
                title: "Truffle Mushroom Pasta",
                description: "Creamy pasta with truffle aroma.",
                style: .gourmet,
                matchScore: 96,
                ingredients: [ingredient],
                missingIngredients: [],
                steps: [step],
                nutrition: nutrition,
                smartSubstitutions: [:],
                substitutionReasons: [:],
                chefTips: "Garnish with fresh parsley for extra color."
            ),
            Recipe(
                id: UUID(),
                title: "Avocado & Mint Salad",
                description: "Fresh greens with lemon dressing.",
                style: .healthy,
                matchScore: 90,
                ingredients: [ingredient],
                missingIngredients: [],
                steps: [step],
                nutrition: nutrition,
                smartSubstitutions: [:],
                substitutionReasons: [:],
                chefTips: "Chill the avocado before slicing."
            ),
            Recipe(
                id: UUID(),
                title: "Artisan Basil Pizza",
                description: "Crispy base with basil pesto.",
                style: .fast,
                matchScore: 88,
                ingredients: [ingredient],
                missingIngredients: [],
                steps: [step],
                nutrition: nutrition,
                smartSubstitutions: [:],
                substitutionReasons: [:],
                chefTips: "Use high heat for a crispy crust."
            )
        ]
    }()
}
