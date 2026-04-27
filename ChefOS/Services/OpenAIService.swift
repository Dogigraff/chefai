import Foundation
import UIKit
import CryptoKit

protocol OpenAIServiceProtocol {
    func generateRecipes(from image: UIImage, barcodes: [String], userProfile: UserProfile) async throws -> [Recipe]
}

struct OpenAIService: OpenAIServiceProtocol {
    private var apiKey: String { AppConfig.openAIKey }
    private var endpoint: URL {
        guard let url = URL(string: "\(AppConfig.apiBaseURL)/chat/completions") else {
            // Fallback to hardcoded URL if construction fails
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        }
        return url
    }

    func generateRecipes(from image: UIImage, barcodes: [String], userProfile: UserProfile) async throws -> [Recipe] {
        // Mock mode when key missing
        if apiKey.isEmpty || apiKey == "YOUR_KEY_HERE" {
            try await Task.sleep(nanoseconds: 2_500_000_000)
            return mockRecipes()
        }

        guard let jpegData = image.jpegData(compressionQuality: 0.5) else {
            throw OpenAIServiceError.encodingFailed
        }
        let base64Image = jpegData.base64EncodedString()

        let systemPrompt = OpenAIService.systemPrompt
        let userText = makeUserText(profile: userProfile, barcodes: barcodes)

        let payload = ChatCompletionRequest(
            model: "gpt-4o",
            messages: [
                .init(role: "system", content: [.text(systemPrompt)]),
                .init(
                    role: "user",
                    content: [
                        .text(userText),
                        .image(type: "image_url", imageURL: .init(url: "data:image/jpeg;base64,\(base64Image)"))
                    ]
                )
            ],
            temperature: 0.7
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? "No body"
            throw OpenAIServiceError.network("Status \( (response as? HTTPURLResponse)?.statusCode ?? -1 ): \(body)")
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content.first?.text else {
            throw OpenAIServiceError.emptyResponse
        }
        let cleaned = try cleanJSONResponse(content)
        let recipesResponse = try JSONDecoder().decode(RecipeResponse.self, from: cleaned.data(using: .utf8) ?? Data())
        return recipesResponse.recipes.map { $0.toDomain() }
    }
}

// MARK: - DTOs

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double

    struct Message: Codable {
        let role: String
        let content: [Content]
    }

    enum Content: Codable {
        case text(String)
        case image(type: String, imageURL: ImageURL)

        enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageURL = "image_url"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let value):
                try container.encode("text", forKey: .type)
                try container.encode(value, forKey: .text)
            case .image(let type, let imageURL):
                try container.encode(type, forKey: .type)
                try container.encode(imageURL, forKey: .imageURL)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            if type == "text" {
                let text = try container.decode(String.self, forKey: .text)
                self = .text(text)
            } else {
                let url = try container.decode(ImageURL.self, forKey: .imageURL)
                self = .image(type: type, imageURL: url)
            }
        }
    }

    struct ImageURL: Codable {
        let url: String
    }
}

private struct ChatCompletionResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            struct Piece: Codable {
                let type: String
                let text: String?
            }
            let role: String
            let content: [Piece]
        }
        let index: Int
        let message: Message
    }
    let choices: [Choice]
}

private struct RecipeResponse: Codable {
    let recipes: [APIRecipe]
}

private struct APIRecipe: Codable {
    let id: String
    let title: String
    let description: String
    let style: String
    let matchScore: Int
    let ingredients: [APIIngredient]
    let missingIngredients: [APIIngredient]?
    let steps: [APIStep]
    let nutrition: APINutrition
    let smartSubstitutions: [String: String]?
    let substitutionReasons: [String: String]?
    let chefTips: String

    func toDomain() -> Recipe {
        Recipe(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            description: description,
            style: RecipeStyle(rawValue: style) ?? .fast,
            matchScore: matchScore,
            ingredients: ingredients.map { $0.toDomain() },
            missingIngredients: (missingIngredients ?? []).map { $0.toDomain() },
            steps: steps.map { $0.toDomain() },
            nutrition: nutrition.toDomain(),
            smartSubstitutions: smartSubstitutions ?? [:],
            substitutionReasons: substitutionReasons ?? [:],
            chefTips: chefTips
        )
    }
}

private struct APIIngredient: Codable {
    let id: String?
    let name: String
    let quantity: String

    func toDomain() -> Ingredient {
        Ingredient(id: stableUUID(), name: name, quantity: quantity)
    }

    private func stableUUID() -> UUID {
        if let id, let uuid = UUID(uuidString: id) {
            return uuid
        }
        let base = "\(name.lowercased())|\(quantity.lowercased())"
        let hash = SHA256.hash(data: Data(base.utf8))
        let bytes = Array(hash.prefix(16))
        let uuid = UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3],
                               bytes[4], bytes[5], bytes[6], bytes[7],
                               bytes[8], bytes[9], bytes[10], bytes[11],
                               bytes[12], bytes[13], bytes[14], bytes[15]))
        return uuid
    }
}

private struct APIStep: Codable {
    let id: String?
    let text: String
    let timerSeconds: Int?
    let warning: String?

    func toDomain() -> Step {
        Step(
            id: UUID(uuidString: id ?? "") ?? UUID(),
            text: text,
            timerSeconds: timerSeconds,
            warning: warning
        )
    }
}

private struct APINutrition: Codable {
    let calories: Int
    let glycemicIndex: Int?
    let sugarGrams: Double?

    func toDomain() -> Nutrition {
        Nutrition(calories: calories, glycemicIndex: glycemicIndex, sugarGrams: sugarGrams)
    }
}

// MARK: - Helpers & Mock

extension OpenAIService {
    enum OpenAIServiceError: Error {
        case encodingFailed
        case network(String)
        case emptyResponse
    }

    static let systemPrompt: String = """
    ROLE: You are ChefOS, an elite culinary AI.
    INPUT: An image of ingredients + User Profile Constraints.
    TASK: Analyze the image. Identify ingredients. IGNORE non-food items.
    OUTPUT: Generate EXACTLY 3 distinct recipe variants based on these ingredients:
    1. "Fast" (Quick, minimum cleanup).
    2. "Healthy" (Strict adherence to profile constraints, focus on macros).
    3. "Gourmet" (High-end techniques, plating focus).

    CRITICAL RULES:
    - Return ONLY valid JSON. No markdown formatting.
    - If User has medical constraints (e.g. Diabetes), strictly obey them (e.g. Low GI).
    - If User has no equipment (e.g. no oven), do not suggest baking.
    
    JSON STRUCTURE:
    {
      "recipes": [
        {
          "id": "UUID string",
          "title": "Name",
          "description": "Short appetizing description",
          "style": "fast" (or "healthy", "gourmet"),
          "matchScore": 85,
          "ingredients": [...],
          "steps": [...],
          "nutrition": { ... },
          "smartSubstitutions": { "Ingredient": "Sub" },
          "substitutionReasons": { "Ingredient": "Reason based on user's health/diet" }
        }
      ]
    }
    """

    private func makeUserText(profile: UserProfile, barcodes: [String]) -> String {
        let constraints = profile.medicalConditions.map(\.rawValue).joined(separator: ", ")
        let allergens = profile.allergens.joined(separator: ", ")
        let religion = profile.religion.rawValue
        let equipment = profile.equipment.map(\.rawValue).joined(separator: ", ")
        let likes = profile.tasteProfile.likes.map(\.rawValue).joined(separator: ", ")
        let dislikes = profile.tasteProfile.dislikes.map(\.rawValue).joined(separator: ", ")
        let pantry = [
            profile.pantryBasics.salt ? "Salt" : nil,
            profile.pantryBasics.sugarSubstitute ? "Sugar Substitute" : nil,
            profile.pantryBasics.oil ? "Oil" : nil,
            profile.pantryBasics.water ? "Water" : nil
        ].compactMap { $0 }.joined(separator: ", ")

        let bcText = barcodes.isEmpty ? "None detected" : barcodes.joined(separator: ", ")

        return """
        USER PROFILE:
        - Medical: \(constraints)
        - Allergens: \(allergens)
        - Religion: \(religion)
        - Equipment: \(equipment)
        - Likes: \(likes)
        - Dislikes: \(dislikes)
        - Pantry: \(pantry)
        
        DETECTED BARCODES (Exact products):
        \(bcText)
        """
    }

    private func mockRecipes() -> [Recipe] {
        let ingredient = Ingredient(name: "Tomato", quantity: "2 pcs")
        let step = Step(text: "Slice and assemble.", timerSeconds: 300, warning: nil)
        let nutrition = Nutrition(calories: 320, glycemicIndex: 40, sugarGrams: 8)
        return [
            Recipe(
                id: UUID(),
                title: "Lazy Pan Tomato Toast",
                description: "One-pan crispy toast with herby tomatoes.",
                style: .fast,
                matchScore: 88,
                ingredients: [ingredient],
                missingIngredients: [],
                steps: [step],
                nutrition: nutrition,
                smartSubstitutions: ["Butter": "Olive oil"],
                chefTips: "Toast bread directly in the pan for crunch."
            ),
            Recipe(
                id: UUID(),
                title: "Low-GI Tomato Quinoa Bowl",
                description: "Protein-rich bowl with fresh tomatoes and greens.",
                style: .healthy,
                matchScore: 92,
                ingredients: [ingredient],
                missingIngredients: [],
                steps: [step],
                nutrition: nutrition,
                smartSubstitutions: ["Quinoa": "Buckwheat"],
                chefTips: "Rinse quinoa to remove bitterness."
            ),
            Recipe(
                id: UUID(),
                title: "Gourmet Confit Tomato Tartare",
                description: "Slow-confit tomatoes with balsamic pearls.",
                style: .gourmet,
                matchScore: 95,
                ingredients: [ingredient],
                missingIngredients: [],
                steps: [step],
                nutrition: nutrition,
                smartSubstitutions: ["Balsamic pearls": "Balsamic reduction"],
                chefTips: "Shock confit tomatoes in ice bath for clean peel."
            )
        ]
    }

    private func cleanJSONResponse(_ text: String) throws -> String {
        // 1. Log the raw text for debugging (internal only)
        print("DEBUG: OpenAI Raw Response Length: \(text.count)")

        // 2. Define Regex to extract content between first { and last }
        // This handles cases where OpenAI includes markdown fences (```json) or conversational text.
        let pattern = "\\{(?:[^{}]|(?R))*\\}"
        
        // Simpler fallback regex if the above complex recursive one isn't supported in standard NSRegularExpression
        let fallbackPattern = #"\{[\s\S]*\}"#

        guard let regex = try? NSRegularExpression(pattern: fallbackPattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            throw OpenAIServiceError.emptyResponse
        }

        let nsRange = match.range
        guard let range = Range(nsRange, in: text) else {
            throw OpenAIServiceError.emptyResponse
        }

        let cleaned = String(text[range])
        
        // Basic validation
        guard cleaned.hasPrefix("{") && cleaned.hasSuffix("}") else {
            throw OpenAIServiceError.emptyResponse
        }
        
        return cleaned
    }
}
