import Foundation

struct AppContainer {
    let authService: AuthService
    let storageService: StorageService
    let aiService: OpenAIServiceProtocol

    static func makeDefault(
        authService: AuthService = Self.defaultAuthService(),
        storageService: StorageService = InMemoryStorageService(),
        aiService: OpenAIServiceProtocol = OpenAIService()
    ) -> AppContainer {
        AppContainer(
            authService: authService,
            storageService: storageService,
            aiService: aiService
        )
    }

    private static func defaultAuthService() -> AuthService {
        #if canImport(FirebaseAuth)
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            return FirebaseAuthService()
        }
        #endif
        return MockAuthService()
    }
}

