public protocol SpeechManagerDelegate: AnyObject {
    func speechManagerTranscriptCompleted(_ transcript: String)
}
