import Speech
import AVFoundation

class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    public var onTranscriptUpdate: ((String) -> Void)?

    func startRecognition() throws {
        // Ensure previous tasks are canceled
        recognitionTask?.cancel()
        self.recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Initialize recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("testing ->  Unable to create a recognition request")
        }
        recognitionRequest.shouldReportPartialResults = true

        // Set up audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {
            (buffer, _) in
            recognitionRequest.append(buffer)
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcript = result.bestTranscription.formattedString
                print("testing -> Transcription: \(transcript)")

                self.onTranscriptUpdate?(transcript)

                if result.isFinal { // Check if the recognition is final
                    print("testing -> User has finished speaking.")
                    self.stopRecognition()
                }
            }

            if let error = error {
                print("testing -> Recognition error: \(error.localizedDescription)")
                self.stopRecognition()
            }
        }
    }

    func stopRecognition() {
        print("testing -> stopRecognition")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    
    // Public functions
    
    public func status() -> Bool {
        return audioEngine.isRunning
    }
}
