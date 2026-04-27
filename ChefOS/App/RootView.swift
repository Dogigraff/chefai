import SwiftUI

struct RootView: View {
    let container: AppContainer
    @Binding var hasProfile: Bool

    var body: some View {
        if hasProfile, let profile = container.storageService.loadUserProfile() {
            DashboardView(container: container, profile: profile) {
                hasProfile = false
            }
        } else {
            OnboardingView(container: container) {
                hasProfile = true
            }
        }
    }
}

