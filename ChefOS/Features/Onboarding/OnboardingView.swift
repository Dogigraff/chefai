import SwiftUI

struct OnboardingView: View {
    let container: AppContainer
    let onFinished: () -> Void

    @State private var step: OnboardingStep = .safety
    @State private var profile = UserProfile()
    @State private var authCompleted: Bool = false

    var body: some View {
        ZStack {
            Color.neoBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                header
                StepIndicator(current: step)

                Group {
                    switch step {
                    case .safety:
                        SafetyStepView(profile: $profile)
                    case .equipment:
                        EquipmentStepView(profile: $profile)
                    case .taste:
                        TasteStepView(profile: $profile)
                    }
                }
                .animation(.easeInOut, value: step)

                footerButtons
            }
            .padding()
        }
        .task {
            if !authCompleted {
                authCompleted = await container.authService.signInAnonymously()
            }
        }
    }
}

private extension OnboardingView {
    var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ChefOS")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(.white)
            Text(step.subtitle)
                .font(.system(.title3, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var footerButtons: some View {
        HStack(spacing: 12) {
            if step != .safety {
                NeoButton(title: "Back") {
                    step = step.previous
                }
                .tint(.white.opacity(0.2))
            }
            NeoButton(title: step == .taste ? "Finish" : "Next") {
                if step == .taste {
                    container.storageService.saveUserProfile(profile)
                    onFinished()
                } else {
                    step = step.next
                }
            }
        }
    }
}

// MARK: - Steps

private struct SafetyStepView: View {
    @Binding var profile: UserProfile

    var body: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Medical & Dietary")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    Wrap(alignment: .leading, spacing: 10) {
                        ForEach(MedicalCondition.allCases) { condition in
                            let isSelected = profile.medicalConditions.contains(condition)
                            NeoTag(text: condition.rawValue, isSelected: isSelected) {
                                if isSelected {
                                    profile.medicalConditions.removeAll { $0 == condition }
                                } else {
                                    profile.medicalConditions.append(condition)
                                }
                            }
                        }
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Religion")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    HStack {
                        ForEach(Religion.allCases) { religion in
                            NeoTag(text: religion.rawValue, isSelected: profile.religion == religion) {
                                profile.religion = religion
                            }
                        }
                    }
                }
            }

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pantry Basics")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    PantryToggle(title: "Salt", isOn: $profile.pantryBasics.salt)
                    PantryToggle(title: "Sugar Substitute", isOn: $profile.pantryBasics.sugarSubstitute)
                    PantryToggle(title: "Oil", isOn: $profile.pantryBasics.oil)
                    PantryToggle(title: "Water", isOn: $profile.pantryBasics.water)
                }
            }
        }
    }
}

private struct EquipmentStepView: View {
    @Binding var profile: UserProfile

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Equipment Arsenal")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundColor(.white)
                Wrap(alignment: .leading, spacing: 10) {
                    ForEach(Equipment.allCases) { item in
                        let isSelected = profile.equipment.contains(item)
                        NeoTag(text: item.rawValue, isSelected: isSelected) {
                            if isSelected {
                                profile.equipment.removeAll { $0 == item }
                            } else {
                                profile.equipment.append(item)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct TasteStepView: View {
    @Binding var profile: UserProfile

    var body: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Taste Swipe")
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                    Text("Лайк/дизлайк ключевые вкусы — влияет на промпт.")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(.body, design: .rounded))
                    VStack(spacing: 10) {
                        ForEach(TasteOption.allCases) { option in
                            TasteRow(
                                option: option,
                                isLiked: profile.tasteProfile.likes.contains(option),
                                isDisliked: profile.tasteProfile.dislikes.contains(option)
                            ) { newState in
                                updateTaste(option: option, state: newState)
                            }
                        }
                    }
                }
            }
        }
    }

    private func updateTaste(option: TasteOption, state: TasteState) {
        profile.tasteProfile.likes.remove(option)
        profile.tasteProfile.dislikes.remove(option)
        switch state {
        case .liked:
            profile.tasteProfile.likes.insert(option)
        case .disliked:
            profile.tasteProfile.dislikes.insert(option)
        case .neutral:
            break
        }
    }
}

// MARK: - Components

private struct StepIndicator: View {
    let current: OnboardingStep

    var body: some View {
        HStack {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step == current ? Color.neoAccent : Color.white.opacity(0.2))
                    .frame(width: 10, height: 10)
            }
        }
    }
}

private struct PantryToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .foregroundColor(.white)
                .font(.system(.body, design: .rounded))
        }
        .toggleStyle(SwitchToggleStyle(tint: .neoAccent))
    }
}

private struct TasteRow: View {
    let option: TasteOption
    let isLiked: Bool
    let isDisliked: Bool
    let update: (TasteState) -> Void

    var body: some View {
        HStack {
            Text(option.rawValue)
                .font(.system(.title3, design: .rounded).weight(.medium))
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 8) {
                tasteButton(title: "👎", isActive: isDisliked) {
                    update(isDisliked ? .neutral : .disliked)
                }
                tasteButton(title: "👍", isActive: isLiked) {
                    update(isLiked ? .neutral : .liked)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func tasteButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(.title2, design: .rounded))
                .frame(width: 44, height: 44)
                .background(isActive ? Color.neoAccent : Color.white.opacity(0.08))
                .foregroundColor(isActive ? .black : .white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

private enum TasteState {
    case liked, disliked, neutral
}

private enum OnboardingStep: Int, CaseIterable {
    case safety, equipment, taste

    var subtitle: String {
        switch self {
        case .safety:
            return "Безопасность и базовые настройки"
        case .equipment:
            return "Твоя кухонная арсеналка"
        case .taste:
            return "Вкусовые предпочтения"
        }
    }

    var next: OnboardingStep {
        OnboardingStep(rawValue: rawValue + 1) ?? self
    }

    var previous: OnboardingStep {
        OnboardingStep(rawValue: rawValue - 1) ?? self
    }
}

// Simple wrap layout for tags
