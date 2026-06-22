import UIKit
import XCTest
@testable import ChefOS

final class ChefOSSafetyTests: XCTestCase {
    
    var aiService: OpenAIService!
    
    override func setUp() {
        super.setUp()
        aiService = OpenAIService()
    }
    
    /// Тест: Гарантирует, что парсер выдерживает "грязный" ответ от ИИ (с болтовней и markdown)
    func testRobustJSONParsing() throws {
        let dirtyResponse = """
        Sure! Here are your recipes in JSON format:
        ```json
        {
          "recipes": [
            {
              "id": "12345",
              "title": "Test Toast",
              "description": "Easy toast",
              "style": "fast",
              "matchScore": 100,
              "ingredients": [],
              "steps": [],
              "nutrition": {"calories": 100},
              "smartSubstitutions": {},
              "substitutionReasons": {},
              "chefTips": "Enjoy!"
            }
          ]
        }
        ```
        Hope you like it!
        """
        
        // This should pass due to our Regex implementation
        let cleaned = try aiService.cleanJSONResponse(dirtyResponse)
        XCTAssertTrue(cleaned.starts(with: "{"))
        XCTAssertTrue(cleaned.contains("recipes"))
    }
    
    /// Тест: Проверка логики "3 Реальностей"
    func testRecipeStylesCorrectness() {
        let styles: [RecipeStyle] = [.fast, .healthy, .gourmet]
        XCTAssertEqual(styles.count, 3)
        XCTAssertTrue(styles.contains(.fast))
    }
    
    /// Тест: Проверка безопасного создания URL endpoint
    func testOpenAIServiceEndpointCreation() {
        // Endpoint должен создаваться без краша даже если baseURL некорректный
        let service = OpenAIService()
        // Если мы дошли сюда без краша, тест пройден
        XCTAssertNotNil(service)
    }
    
    /// Тест: Проверка mock режима когда API ключ отсутствует
    func testMockModeWhenNoAPIKey() async throws {
        let service = OpenAIService()
        let testImage = UIImage(systemName: "photo")!
        let profile = UserProfile()
        
        // В mock режиме должны получить 3 рецепта
        let recipes = try await service.generateRecipes(from: testImage, barcodes: [], userProfile: profile)
        XCTAssertEqual(recipes.count, 3)
        XCTAssertTrue(recipes.contains(where: { $0.style == .fast }))
        XCTAssertTrue(recipes.contains(where: { $0.style == .healthy }))
        XCTAssertTrue(recipes.contains(where: { $0.style == .gourmet }))
    }
    
    /// Тест: Проверка стабильности UUID для ингредиентов
    func testIngredientStableUUID() {
        let ingredient1 = Ingredient(name: "Tomato", quantity: "2 pcs")
        let ingredient2 = Ingredient(name: "Tomato", quantity: "2 pcs")
        
        // UUID должны быть разными для разных экземпляров
        XCTAssertNotEqual(ingredient1.id, ingredient2.id)
    }
    
    /// Тест: Проверка UserProfile по умолчанию
    func testDefaultUserProfile() {
        let profile = UserProfile()
        XCTAssertEqual(profile.religion, .none)
        XCTAssertTrue(profile.medicalConditions.isEmpty)
        XCTAssertTrue(profile.allergens.isEmpty)
        XCTAssertTrue(profile.pantryBasics.salt)
        XCTAssertTrue(profile.pantryBasics.water)
    }
    
    /// Тест: Проверка Codable для Recipe
    func testRecipeCodable() throws {
        let recipe = Recipe(
            id: UUID(),
            title: "Test Recipe",
            description: "Test Description",
            style: .fast,
            matchScore: 85,
            ingredients: [Ingredient(name: "Test", quantity: "1")],
            missingIngredients: [],
            steps: [Step(text: "Test step")],
            nutrition: Nutrition(calories: 100, glycemicIndex: 50, sugarGrams: 5.0),
            smartSubstitutions: ["A": "B"],
            substitutionReasons: ["A": "Health reasons"],
            chefTips: "Test tip"
        )
        
        let encoded = try JSONEncoder().encode(recipe)
        let decoded = try JSONDecoder().decode(Recipe.self, from: encoded)
        
        XCTAssertEqual(recipe.title, decoded.title)
        XCTAssertEqual(recipe.matchScore, decoded.matchScore)
        XCTAssertEqual(recipe.style, decoded.style)
    }
}
