import SwiftUI

enum MainTab {
    case home
    case scan
    case profile
}

struct MainTabView: View {
    let container: AppContainer
    let profile: UserProfile
    let onResetProfile: () -> Void

    @State private var selected: MainTab = .home
    @State private var showScan: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .home:
                    HomeView(viewModel: HomeViewModel(storage: container.storageService))
                case .profile:
                    ProfileView(profile: profile)
                case .scan:
                    HomeView(viewModel: HomeViewModel(storage: container.storageService)) // fallback; scan opens full screen cover
                }
            }
            customTabBar
        }
        .sheet(isPresented: $showScan) {
            DashboardView(container: container, profile: profile, onResetProfile: onResetProfile)
        }
    }

    private var customTabBar: some View {
        GlassCard(cornerRadius: 24) {
            HStack {
                tabButton(icon: "house.fill", tab: .home)
                Spacer()
                scanButton
                Spacer()
                tabButton(icon: "person.fill", tab: .profile)
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.clear.ignoresSafeArea(edges: .bottom))
    }

    private func tabButton(icon: String, tab: MainTab) -> some View {
        Button {
            selected = tab
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(selected == tab ? .neoAccent : .white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(selected == tab ? Color.white.opacity(0.08) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var scanButton: some View {
        Button {
            showScan = true
        } label: {
            Text("SCAN")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.neoAccent)
                .clipShape(Capsule())
                .shadow(color: Color.neoAccent.opacity(0.6), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

