import Foundation

public class SpeechManager {
    private let recognizer = SpeechRecognizer()
    private var lastTranscript: String = ""
    private var silenceTimer: Timer?

    public init() {
        recognizer.onTranscriptUpdate = { newTranscript in
            self.handleTranscriptUpdate(newTranscript)
        }
    }

    public func startSpeechRecognition() {
        do {
            try recognizer.startRecognition()
        } catch {
            print("testing -> SpeechManager ❌ Failed to start recognition: \(error)")
        }
    }

    private func handleTranscriptUpdate(_ newTranscript: String) {
        if newTranscript != lastTranscript {
            lastTranscript = newTranscript
            startSilenceTimer()
        }
    }

    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            print("testing -> SpeechManager 🛑 No transcript change in 2 seconds. Stopping recognition.")
            if let recognizer = self?.recognizer, recognizer.isRunning() {
                recognizer.stopRecognition()
            }
        }
    }
}
