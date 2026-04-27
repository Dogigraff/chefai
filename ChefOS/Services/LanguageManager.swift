import Foundation
import Combine

@MainActor
final class LanguageManager: ObservableObject {
    enum AppLanguage: String, CaseIterable, Identifiable {
        case system
        case en
        case ru
        case es

        var id: String { rawValue }

        var localeIdentifier: String {
            switch self {
            case .system:
                return Locale.preferredLanguages.first ?? "en"
            case .en: return "en"
            case .ru: return "ru"
            case .es: return "es"
            }
        }

        var displayName: String {
            switch self {
            case .system: return String(localized: "language_system")
            case .en: return String(localized: "language_english")
            case .ru: return String(localized: "language_russian")
            case .es: return String(localized: "language_spanish")
            }
        }
    }

    @Published private(set) var currentLanguage: AppLanguage

    private let storageKey = "selectedLanguage"

    init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        } else {
            currentLanguage = .system
        }
    }

    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: storageKey)
    }
}

