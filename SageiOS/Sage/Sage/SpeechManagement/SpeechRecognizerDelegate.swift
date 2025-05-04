public protocol SpeechRecognizerDelegate: AnyObject {
    func speechRecognizerRecognitionStopped(_ transcript: String)
}
