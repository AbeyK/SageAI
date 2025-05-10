import Foundation

public class SpeechManager: SpeechRecognizerDelegate {
    private let recognizer = SpeechRecognizer()
    private var lastTranscript: String = ""
    private var silenceTimer: Timer?
    private var delegate: SpeechManagerDelegate?

    public init(delegate: SpeechManagerDelegate? = nil) {
        self.delegate = delegate
    }

    public func startSpeechRecognition() {
        recognizer.delegate = self
        recognizer.onTranscriptUpdate = { newTranscript in
            self.handleTranscriptUpdate(newTranscript)
        }
        
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
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            print("testing -> SpeechManager 🛑 No transcript change in 2 seconds. Stopping recognition.")
            if let recognizer = self?.recognizer, recognizer.isRunning() {
                recognizer.stopRecognition()
            }
        }
    }

    public func speechRecognizerRecognitionStopped(_ transcript: String) {
        if (transcript != "") {
            self.delegate?.speechManagerTranscriptCompleted(transcript)
        }
    }

}
