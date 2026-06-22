import SwiftUI
import SwiftData
import UserNotifications

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct ChefOSApp: App {
    private let container: AppContainer
    @State private var hasProfile: Bool
    @StateObject private var languageManager = LanguageManager()

    init() {
        let storageService: StorageService = MainActor.assumeIsolated {
            if let modelContainer = try? ModelContainer(for: StoredUserProfile.self, StoredCache.self) {
                return SwiftDataStorageService(container: modelContainer)
            }
            return InMemoryStorageService()
        }

        self.container = AppContainer.makeDefault(storageService: storageService)
        self._hasProfile = State(initialValue: storageService.loadUserProfile() != nil)
        configureFirebaseIfAvailable()
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                container: container,
                hasProfile: $hasProfile
            )
            .environmentObject(languageManager)
            .environment(\.locale, Locale(identifier: languageManager.currentLanguage.localeIdentifier))
            .preferredColorScheme(.dark)
        }
    }
}

private extension ChefOSApp {
    func configureFirebaseIfAvailable() {
#if canImport(FirebaseCore)
        // Configure Firebase only if GoogleService-Info.plist exists to allow simulator build without keys
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        } else {
            print("Firebase skipped: GoogleService-Info.plist not found.")
        }
#else
        print("FirebaseCore not available in this build; using mock services.")
#endif
    }
}

