import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    let onAuthenticated: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()
            VStack(spacing: 24) {
                header
                GlassCard(cornerRadius: 24) {
                    VStack(spacing: 16) {
                        NeoTextField(title: String(localized: "email_username"), text: $viewModel.email, icon: "envelope")
                        NeoTextField(title: String(localized: "password"), text: $viewModel.password, icon: "lock", isSecure: true)
                        HStack {
                            Spacer()
                            Text(L("forgot_password"))
                                .font(.system(.footnote, design: .rounded).weight(.medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                NeoButton(title: viewModel.isLoading ? String(localized: "logging_in") : String(localized: "log_in")) {
                    Task {
                        if await viewModel.login() {
                            onAuthenticated()
                        }
                    }
                }
                appleButton
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("welcome_back"))
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(L("login_subtitle"))
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { _ in
            Task {
                do {
                    let manager = AppleSignInManager()
                    _ = try await manager.startSignIn()
                    onAuthenticated()
                } catch {
                    // ignore for now or show toast
                }
            }
        } onCompletion: { _ in }
        .signInWithAppleButtonStyle(.white)
        .frame(height: 50)
        .padding(.top, 4)
    }
}

