import Foundation

enum AppConfig {
    enum KeychainKeys {
        static let openAIKey = "com.chefos.openai.apikey"
    }
    
    static var openAIKey: String {
        // 1. Try to get from ProcessInfo (for development/CI)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 2. Here we would typically fetch from Keychain or a secure remote Config
        // For now, providing a centralized place for the placeholder
        return "YOUR_KEY_HERE"
    }
    
    static let apiBaseURL = "https://api.openai.com/v1"
    
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
}
