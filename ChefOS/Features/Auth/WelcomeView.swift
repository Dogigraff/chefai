import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            Image("welcome_background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 24) {
                Spacer()
                GlassCard(cornerRadius: 28) {
                    VStack(spacing: 14) {
                        Text(L("welcome_title"))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        Text("ChefOS")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(L("welcome_subtitle"))
                            .font(.system(.body, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 6)
                }

                VStack(spacing: 14) {
                    NeoButton(title: String(localized: "get_started")) {
                        onGetStarted()
                    }
                    NeoButton(title: String(localized: "log_in"), style: .secondary) {
                        onLogin()
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

