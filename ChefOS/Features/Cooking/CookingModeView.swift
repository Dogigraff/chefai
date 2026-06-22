import SwiftUI
import UIKit

struct CookingModeView: View {
    let recipe: Recipe
    @State private var currentStepIndex: Int = 0
    @State private var timerRemaining: Int?
    @State private var timerActive: Bool = false
    @State private var timerTask: Task<Void, Never>?
    @StateObject private var voiceManager = VoiceManager()
    @State private var voiceError: String?

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()
            VStack(spacing: 16) {
                progressBar
                TabView(selection: $currentStepIndex) {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        stepCard(step: step, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page)
                bottomControls
            }
            .padding(.bottom, 10)
            .overlay(alignment: .topTrailing) {
                micIndicator
                    .padding()
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            Task {
                await voiceManager.requestAuthorization()
                if voiceManager.isAuthorized {
                    startVoice()
                    speakCurrentStep()
                } else {
                    voiceError = "Voice permission denied"
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timerTask?.cancel()
            voiceManager.stopListening()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension CookingModeView {
    var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<recipe.steps.count, id: \.self) { idx in
                Rectangle()
                    .fill(idx <= currentStepIndex ? Color.neoAccent : Color.white.opacity(0.1))
                    .frame(height: 6)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
    }

    func stepCard(step: Step, index: Int) -> some View {
        VStack(spacing: 28) {
            Text(String(format: String(localized: "step_of"), index + 1, recipe.steps.count))
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
            Text(step.text)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let timerSeconds = step.timerSeconds ?? extractTimer(text: step.text) {
                timerButton(seconds: timerSeconds)
            }
            if let warning = step.warning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.yellow)
                    .font(.system(.body, design: .rounded))
            }
            Spacer()
        }
        .padding(.top, 40)
    }

    var micIndicator: some View {
        let color: Color = voiceManager.isListening ? .green : .red
        return Circle()
            .fill(color.opacity(0.8))
            .frame(width: 16, height: 16)
            .overlay(
                Image(systemName: "mic.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
    }

    var bottomControls: some View {
        HStack(spacing: 12) {
            NeoButton(title: String(localized: "prev"), style: .secondary) {
                currentStepIndex = max(0, currentStepIndex - 1)
                speakCurrentStep()
            }
            if let timerSeconds = recipe.steps[currentStepIndex].timerSeconds ?? extractTimer(text: recipe.steps[currentStepIndex].text) {
                timerButton(seconds: timerSeconds)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
            NeoButton(title: currentStepIndex == recipe.steps.count - 1 ? String(localized: "finish") : String(localized: "next")) {
                currentStepIndex = min(recipe.steps.count - 1, currentStepIndex + 1)
                speakCurrentStep()
            }
        }
        .padding(.horizontal)
    }

    func timerButton(seconds: Int) -> some View {
        VStack(spacing: 8) {
            if timerActive, let remaining = timerRemaining {
                Text(timeString(from: remaining))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.neoAccent)
            }
            Button {
                startTimer(seconds: seconds)
            } label: {
                Text(timerActive ? String(localized: "restart_timer") : String(format: String(localized: "start_timer"), timeString(from: seconds)))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.08))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.neoAccent, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    func startTimer(seconds: Int) {
        timerTask?.cancel()
        timerRemaining = seconds
        timerActive = true
        HapticManager.shared.notify(.success)
        timerTask = Task {
            while let remaining = timerRemaining, remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    timerRemaining = remaining - 1
                }
            }
            await MainActor.run {
                timerActive = false
                HapticManager.shared.notify(.warning)
                NotificationManager.shared.scheduleStepComplete()
                voiceManager.speak(String(localized: "timer_finished"))
            }
        }
    }

    func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    func extractTimer(text: String) -> Int? {
        let components = text.lowercased().split(separator: " ")
        if let idx = components.firstIndex(of: "min"), idx > 0, let minutes = Int(components[idx - 1]) {
            return minutes * 60
        }
        return nil
    }

    func startVoice() {
        voiceManager.startListening { command in
            switch command {
            case .nextStep:
                currentStepIndex = min(recipe.steps.count - 1, currentStepIndex + 1)
                speakCurrentStep()
            case .previousStep:
                currentStepIndex = max(0, currentStepIndex - 1)
                speakCurrentStep()
            case .repeatStep:
                speakCurrentStep()
            case .startTimer:
                if let seconds = recipe.steps[currentStepIndex].timerSeconds ?? extractTimer(text: recipe.steps[currentStepIndex].text) {
                    startTimer(seconds: seconds)
                }
            }
        }
    }

    func speakCurrentStep() {
        let step = recipe.steps[currentStepIndex]
        voiceManager.speak(step.text)
    }
}
