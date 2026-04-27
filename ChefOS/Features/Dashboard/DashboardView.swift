import SwiftUI
import PhotosUI
import UIKit

struct DashboardView: View {
    let container: AppContainer
    let profile: UserProfile
    let onResetProfile: () -> Void

    @StateObject private var viewModel: DashboardViewModel
    @StateObject private var camera = CameraController()
    @State private var showRecipes: Bool = false
    @State private var errorMessage: String?

    init(container: AppContainer, profile: UserProfile, onResetProfile: @escaping () -> Void) {
        self.container = container
        self.profile = profile
        self.onResetProfile = onResetProfile
        _viewModel = StateObject(wrappedValue: DashboardViewModel(
            aiService: container.aiService,
            storage: container.storageService,
            profileProvider: {
                container.storageService.loadUserProfile() ?? profile
            }
        ))
    }

    var body: some View {
        ZStack {
            CameraPreview(controller: camera)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                topBar
                Spacer()
                reticle
                Spacer()
                bottomBar
            }
            .padding()

            if viewModel.state == .analyzing {
                analyzingOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.state)
        .sheet(isPresented: $showRecipes) {
            if case .results(let recipes) = viewModel.state {
                RecipeChoiceView(recipes: recipes)
            }
        }
        .alert(L("error_title"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { _ in errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .onChange(of: viewModel.state) { _, newState in
            switch newState {
            case .results:
                showRecipes = true
            case .error(let message):
                errorMessage = message
            default:
                break
            }
        }
    }
}

// MARK: - Layers
private extension DashboardView {
    var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color.neoBackground.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let previewImage {
                previewImage
                    .resizable()
                    .scaledToFill()
                    .opacity(0.35)
                    .ignoresSafeArea()
            } else {
                Color.black.opacity(0.4).ignoresSafeArea()
            }
        }
    }

    var topBar: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L("chefos_active"))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(role: .destructive) {
                        onResetProfile()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                statusChips
            }
        }
    }

    var statusChips: some View {
        Wrap(alignment: .leading, spacing: 8) {
            if !profile.medicalConditions.isEmpty {
                ForEach(profile.medicalConditions, id: \.self) { condition in
                    StatusChip(icon: "heart.text.square", text: condition.localizedName)
                }
            }
            if profile.religion != .none {
                StatusChip(icon: "moon.stars", text: profile.religion.localizedName)
            }
            if !profile.equipment.isEmpty {
                StatusChip(icon: "fork.knife", text: String(format: String(localized: "tools_count"), profile.equipment.count))
            }
            if profile.pantryBasics.salt == false {
                StatusChip(icon: "exclamationmark.triangle", text: L("no_salt"))
            }
        }
    }

    var reticle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
                .frame(width: 260, height: 260)
            reticleCorners
        }
        .padding()
    }

    var analyzingOverlay: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.neoAccent.opacity(0.3), lineWidth: 12)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(Color.neoAccent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(Date().timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1) * 360))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.state)
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.neoAccent)
            }
            Text(L("analyzing_status"))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(.white)
                .padding(.top, 12)
        }
        .padding()
    }

    var reticleCorners: some View {
        let size: CGFloat = 260
        let corner: CGFloat = 28
        return ZStack {
            cornerShape
                .offset(x: -(size / 2) + corner, y: -(size / 2) + corner)
            cornerShape
                .rotationEffect(.degrees(90))
                .offset(x: (size / 2) - corner, y: -(size / 2) + corner)
            cornerShape
                .rotationEffect(.degrees(180))
                .offset(x: (size / 2) - corner, y: (size / 2) - corner)
            cornerShape
                .rotationEffect(.degrees(270))
                .offset(x: -(size / 2) + corner, y: (size / 2) - corner)
        }
        .frame(width: size, height: size)
    }

    var cornerShape: some View {
        RoundedRectangle(cornerRadius: 8)
            .trim(from: 0, to: 0.25)
            .stroke(Color.neoAccent, lineWidth: 4)
            .frame(width: 50, height: 50)
    }

    var bottomBar: some View {
        GlassCard {
            HStack(spacing: 16) {
                iconButton(system: "waveform") {
                    // Voice placeholder
                }
                Button {
                    HapticManager.shared.play(.heavy)
                    camera.takePhoto { image in
                        guard let image else { return }
                        DispatchQueue.main.async {
                            let barcodes = Array(camera.scannedBarcodes)
                            viewModel.state = .analyzing
                            viewModel.analyze(image: image, barcodes: barcodes)
                            camera.scannedBarcodes.removeAll()
                        }
                    }
                } label: {
                    scanButton
                }
                .buttonStyle(.plain)
                iconButton(system: "basket") {
                    // Pantry placeholder
                }
            }
        }
    }

    func iconButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    var scanButton: some View {
        Text(L("scan_ai_button"))
            .font(.system(.title2, design: .rounded).weight(.bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color.neoAccent, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.neoAccent.opacity(0.6), radius: 12, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}

// MARK: - Chips
private struct StatusChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .font(.system(.footnote, design: .rounded).weight(.medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.neoGlassBorder, lineWidth: 1)
        )
    }
}

