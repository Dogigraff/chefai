import Foundation
import Speech
import AVFoundation

enum VoiceCommand {
    case nextStep
    case previousStep
    case repeatStep
    case startTimer
}

@MainActor
final class VoiceManager: NSObject, ObservableObject {
    @Published var isListening: Bool = false
    @Published var isAuthorized: Bool = false

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let synthesizer = AVSpeechSynthesizer()

    // Supported locales: English, Russian, Spanish
    private let supportedLocales: [Locale] = [
        Locale(identifier: "en-US"),
        Locale(identifier: "ru-RU"),
        Locale(identifier: "es-ES")
    ]

    private var speechRecognizer: SFSpeechRecognizer? {
        guard let preferred = Locale.preferredLanguages.first else {
            // Safe fallback to English if supportedLocales is somehow empty
            let fallbackLocale = supportedLocales.first ?? Locale(identifier: "en-US")
            return SFSpeechRecognizer(locale: fallbackLocale)
        }
        if let match = supportedLocales.first(where: { preferred.starts(with: $0.identifier.prefix(2)) }) {
            return SFSpeechRecognizer(locale: match)
        }
        // Safe fallback to first supported locale or English
        let fallbackLocale = supportedLocales.first ?? Locale(identifier: "en-US")
        return SFSpeechRecognizer(locale: fallbackLocale)
    }

    func requestAuthorization() async {
        let status = await SFSpeechRecognizer.requestAuthorization()
        isAuthorized = status == .authorized
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            break
        case .denied:
            isAuthorized = false
        case .undetermined:
            do {
                try await AVAudioSession.sharedInstance().requestRecordPermission()
            } catch {
                isAuthorized = false
            }
        @unknown default:
            isAuthorized = false
        }
    }

    func speak(_ text: String) {
        configureAudioSessionForPlayback()
        let utterance = AVSpeechUtterance(string: text)
        
        // Use the same locale logic as the recognizer (preferred match or default)
        let localeID = speechRecognizer?.locale.identifier ?? "en-US"
        utterance.voice = AVSpeechSynthesisVoice(language: localeID)
        
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        synthesizer.speak(utterance)
    }

    func startListening(onCommand: @escaping (VoiceCommand) -> Void) {
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }
        configureAudioSessionForRecord()

        recognitionTask?.cancel()
        recognitionTask = nil
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isListening = true
        } catch {
            isListening = false
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                if let command = self.detectCommand(from: text) {
                    onCommand(command)
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                self.restartListening(onCommand: onCommand)
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        request?.endAudio()
        recognitionTask?.cancel()
        isListening = false
    }

    private func restartListening(onCommand: @escaping (VoiceCommand) -> Void) {
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.startListening(onCommand: onCommand)
        }
    }

    private func detectCommand(from text: String) -> VoiceCommand? {
        let lower = text.lowercased()
        if lower.contains("next") || lower.contains("дальше") || lower.contains("siguiente") {
            return .nextStep
        }
        if lower.contains("back") || lower.contains("назад") || lower.contains("atrás") {
            return .previousStep
        }
        if lower.contains("repeat") || lower.contains("повтори") || lower.contains("repite") {
            return .repeatStep
        }
        if lower.contains("timer") || lower.contains("таймер") || lower.contains("temporizador") {
            return .startTimer
        }
        return nil
    }

    private func configureAudioSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func configureAudioSessionForRecord() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

