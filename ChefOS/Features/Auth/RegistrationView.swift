import SwiftUI
import AuthenticationServices

struct RegistrationView: View {
    @StateObject private var viewModel = AuthViewModel()
    let onRegistered: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()
            VStack(spacing: 24) {
                header
                GlassCard(cornerRadius: 24) {
                    VStack(spacing: 16) {
                        NeoTextField(title: String(localized: "full_name"), text: $viewModel.name, icon: "person")
                        NeoTextField(title: "Email", text: $viewModel.email, icon: "envelope")
                        NeoTextField(title: String(localized: "password"), text: $viewModel.password, icon: "lock", isSecure: true)
                    }
                }
                NeoButton(title: viewModel.isLoading ? String(localized: "creating") : String(localized: "create_account")) {
                    Task {
                        if await viewModel.register() {
                            onRegistered()
                        }
                    }
                }
                SignInWithAppleButton(.signUp) { _ in
                    Task {
                        do {
                            let manager = AppleSignInManager()
                            _ = try await manager.startSignIn()
                            onRegistered()
                        } catch { }
                    }
                } onCompletion: { _ in }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("create_your_profile"))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(L("create_profile_subtitle"))
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

