import Foundation
import FirebaseAuth // Assuming Firebase Auth is imported

public class ConversationManager: SpeechManagerDelegate {
    private var speechManager: SpeechManager?
    private var ttsManager: TTSManager?
    private let session = URLSession.shared
    private var isSendingChat = false
    private var phaseTimers: [DispatchWorkItem] = []
    private var autoPromptTimer: DispatchWorkItem?
    private var lastUserInteractionTime = Date()
    private var lastAIResponseTime = Date()
    private var isAISpeaking = false
    private var lastContinuationPromptIndex = -1
    public var isSignedOut: Bool = false
    private var meditationProgress: Int = 0  // Track meditation progress as percentage
    private var timer: Timer?
    public var remainingSeconds = 300 // 5 minutes in seconds
    public var onTimerUpdate: ((Int, Int) -> Void)? // Callback for timer updates (minutes, seconds)

    // Make delegate weak to prevent retain cycles
    private weak var delegate: ConversationManagerDelegate?
    
    // MARK: - Phase Management
    public enum MeditationPhase: String, CaseIterable {
        case idle
        case initialDiscussion // User and AI discuss problems
        case meditating
        case retroDiscussion // Post-meditation chat
        case ended
    }

    public var currentPhase: MeditationPhase = .idle {
        didSet {
            log("testing -> Meditation phase changed from \(oldValue.rawValue) to: \(currentPhase.rawValue)")
        }
    }

    // 🔁 Store the conversation history
    private var conversationHistory: [[String: String]] = [] // Initialize as empty
    {
        didSet {
            if let lastMessageDict = conversationHistory.last,
               let role = lastMessageDict["role"],
               let content = lastMessageDict["content"] {
                // Don't show phase markers or excessively long system messages in UI directly via this simple delegate
                if !content.starts(with: "__PHASE") && !(role == "system" && content.count > 200) {
                    let chatMessage = ChatMessage(role: role, content: content)
                    DispatchQueue.main.async { // Dispatch to main thread for UI updates
                        // Assuming the delegate method is now: conversationManagerDidAddMessage(_ message: ChatMessage)
                        // You will need to ensure your actual delegate protocol matches this.
                        self.delegate?.conversationManagerDidAddMessage(chatMessage, isSentByUser: role == "user")
                    }
                }
            }
        }
    }

    public init(delegate: ConversationManagerDelegate) {
        self.delegate = delegate
        ttsManager = TTSManager()
    }

    public func startConversation() {
        // Ensure speechManager is re-initialized if called multiple times or if it can be nilled elsewhere
        if self.speechManager == nil {
            log("testing -> ConversationManager: Initializing SpeechManager")
            self.speechManager = SpeechManager(delegate: self)
        }
        log("testing -> ConversationManager: Starting conversation...")
        if self.speechManager != nil { // Check the instance property
            initiateConversationFlow()
        } else {
            log("testing -> ConversationManager: SpeechManager failed to initialize.", fields: ["error": true])
            // Handle error: speech manager couldn't be initialized
        }
    }
    
    private func initiateConversationFlow() {
        guard currentPhase == .idle else {
            log("testing -> ConversationManager: Conversation or meditation already in progress.")
            return
        }
        
        log("testing -> ConversationManager: Initiating conversation flow...")
        currentPhase = .initialDiscussion
        updateConversationStatus(to: .isInitializing)
        lastUserInteractionTime = Date()  // Initialize interaction time hassank - not sure if we even want to keep track of lastUserInteractionTime anymore

        // Add an initial user message to kick off the conversation but don't add it to conversation history
        // This prevents showing an empty message in the UI
        let initialMessage = ["role": "initializer", "content": ""]

        DispatchQueue.global(qos: .userInitiated).async {
            // Send the initial message to the backend without adding it to conversation history
            self.sendToBackend(withMessage: initialMessage)
        }
    }
    
    public func speechManagerTranscriptCompleted(_ transcript: String) {
        // Check for interruption: if AI is speaking (TTS active) and a transcript comes in.
        if self.isAISpeaking {
            log("testing -> ConversationManager: User interrupted AI. Stopping TTS.")
            self.ttsManager?.stopPlayback() // Stop the TTS
            self.isAISpeaking = false      // Mark AI as no longer speaking
            
            // Since TTS is stopped, ensure we transition to a listening state if needed,
            // and cancel any auto-prompts that were scheduled assuming TTS would finish.
            self.updateConversationStatus(to: .isListening)
            self.cancelAutoPrompt()
        }

        // Proceed with handling the transcript.
        // The !isSendingChat check was originally to avoid processing a new transcript
        // if a backend request for a *previous* turn was still in flight.
        // For an interruption, we generally want to process it.
        // Consider if this 'isSendingChat' check is still perfectly applicable or needs refinement for barge-in.
        // For now, we'll assume if a transcript arrives, it should be handled.
        log("testing -> ConversationManager: User transcript completed (isSendingChat: \(isSendingChat))", fields: ["transcript": transcript])
        lastUserInteractionTime = Date() // Update user interaction time
        handleTranscript(transcript) // Process the transcript (sends to backend)
    }

    private func handleTranscript(_ transcript: String) {
        log("testing -> ConversationManager: User said", fields: ["transcript": transcript])
        
        // Cancel any pending auto-prompt since user has spoken
        cancelAutoPrompt()
        
        conversationHistory.append(["role": "user", "content": transcript])
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend()
        }
    }

    // MARK: - Auto-Prompting Logic
    
    private func scheduleAutoPromptCheck() {
        // Cancel any existing auto-prompt timer
        cancelAutoPrompt()
        
        // Create a new timer to check for inactivity
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.currentPhase != .idle && self.currentPhase != .ended else { return }

            // Don't auto-prompt if AI is currently speaking
            if self.isAISpeaking {
              //  log("Delaying auto-prompt because AI is speaking")
                self.scheduleAutoPromptCheck() // Check again later
                return
            }
            
            self.sendContinuationPrompt()
        }
        
        autoPromptTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: workItem)
    }
    
    private func cancelAutoPrompt() {
        autoPromptTimer?.cancel()
        autoPromptTimer = nil
    }
    
    private func sendContinuationPrompt() {
        DispatchQueue.global(qos: .background).async {
            self.sendToBackend()
        }
        
        // Reset the interaction time
        lastUserInteractionTime = Date()
    }

    public func stopConversationAndMeditation() {
        log("testing -> ConversationManager: Stopping conversation and meditation explicitly.")
        cancelAutoPrompt()
        if speechManager != nil {
            // Optionally stop speech recognition if it's continuously running
            speechManager?.stopSpeechRecognition()
        }

        if ttsManager != nil {
            ttsManager?.stopPlayback()
        }

        currentPhase = .ended
    }

    // Placeholder for Firebase ID Token - Replace with your actual implementation
    private func getCurrentUserIDToken(completion: @escaping (String?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            currentUser.getIDToken { [weak self] token, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.log("testing -> ConversationManager: Error fetching ID token", fields: ["error": error.localizedDescription])
                    completion(nil)
                    return
                }
                completion(token)
            }
        } else {
            log("testing -> ConversationManager: No current user for ID token.")
            completion(nil)
        }
    }
    
    // Backend requests

    public func sendToBackend() {
        guard !isSignedOut else { log("testing -> ConversationManager: SendToBackend - User is signed out, aborting."); return }
        guard !isSendingChat else {
            log("testing -> ConversationManager: Already sending request, ignoring duplicate.")
            return
        }
        log("testing -> ConversationManager: sendToBackend called with history")
        // Use the conversation history for regular sends
        let messagesPayload = self.conversationHistory.map { ChatMessage(role: $0["role"]!, content: $0["content"]!) }
        sendToBackend(withMessages: messagesPayload)
    }
    
    private func sendToBackend(withMessage message: [String: String]) {
        guard !isSignedOut else { log("testing -> ConversationManager: sendToBackend(withMessage:) - User is signed out, aborting."); return }
        guard !isSendingChat else {
            log("testing -> ConversationManager: Already sending request, ignoring duplicate.")
            return
        }
        log("testing -> ConversationManager: sendToBackend(withMessage:) called with: \(message)")
        // Create a single message payload without affecting conversation history
        let messagePayload = [ChatMessage(role: message["role"]!, content: message["content"]!)]
        sendToBackend(withMessages: messagePayload)
    }
    
    private func sendToBackend(withMessages messages: [ChatMessage]) {
        guard !isSignedOut else { log("testing -> ConversationManager: sendToBackend(withMessages:) - User is signed out, aborting."); return }
        guard !isSendingChat else {
            log("testing -> ConversationManager: Already sending request, ignoring duplicate.")
            return
        }
        log("testing -> ConversationManager: sendToBackend(withMessages:) sending \(messages.count) messages. First: \(messages.first?.content ?? "N/A")")

        isSendingChat = true
        log("testing -> ConversationManager: isSendingChat = true")

        // Check if this is the initial message.
        // The initial message is [ChatMessage(role: "initializer", content: "")]
        let isInitialMessage = messages.count == 1 && messages.first?.role == "initializer"

        if !isInitialMessage { // Only set to .isThinking if it's not the special initial message
            self.updateConversationStatus(to: .isThinking)
        }
        // If it *is* the initial message, the status would have been set to .isInitializing
        // by initiateConversationFlow(), and we keep it that way until the first response.

        getCurrentUserIDToken { [weak self] idToken in
            guard let self = self else { return }
            guard let token = idToken else {
                self.log("testing -> ConversationManager: Failed to get ID Token. Aborting send.")
                self.isSendingChat = false
                return
            }
            
            guard let url = currentPhase == .initialDiscussion ? URL(string: "https://sage-ai-backend.fly.dev/api/v1/chat") : URL(string: "https://sage-ai-backend.fly.dev/api/v1/meditate") else {
                self.log("testing -> ConversationManager: Invalid URL. Aborting send.")
                self.isSendingChat = false
                return
            }
            log("testing -> ConversationManager: Preparing URLRequest to \(url)")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                // Convert ChatMessage objects to dictionaries
                let messageDictionaries = messages.map { [
                    "role": $0.role,
                    "content": $0.content
                ] }
                log("testing -> meditationProgress: \(self.meditationProgress)")
                
                let requestBody: [String: Any] = [
                    "messages": messageDictionaries,
                    "percent_complete": self.meditationProgress
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
                request.httpBody = jsonData
            } catch {
                self.log("testing -> ConversationManager: Failed to encode request", fields: ["error": error])
                self.isSendingChat = false
                log("testing -> ConversationManager: isSendingChat = false (json encoding error)")
                return
            }
            
            log("testing -> ConversationManager: Starting URLSession data task.")
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                defer {
                    self.isSendingChat = false
                    self.log("testing -> ConversationManager: isSendingChat = false (in defer after data task completion)")
                }

                if let error = error as? URLError {
                    self.log("testing -> ConversationManager: Backend error", fields: ["error": error.localizedDescription, "code": error.code])
                    if error.code == .networkConnectionLost {
                        self.log("testing -> ConversationManager: Retrying after connection lost...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            self.sendToBackend(withMessages: messages)
                        }
                    }
                    return
                }

                guard let data = data else {
                    self.log("testing -> ConversationManager: No data from backend.")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    self.log("testing -> ConversationManager: Backend HTTP status code", fields: ["code": httpResponse.statusCode])
                }
                
                if let raw = String(data: data, encoding: .utf8) {
                    self.log("testing -> ConversationManager: Raw backend response", fields: ["response": raw.prefix(1000)])
                }
                
                do {
                    let decoder = JSONDecoder()
                    let chatResponse = try decoder.decode(ChatResponse.self, from: data)

                    self.log("testing -> ConversationManager: Backend Response (text)", fields: ["response": chatResponse.text_response])
                    if let caption = chatResponse.caption {
                        self.log("testing -> ConversationManager: Backend Response (caption)", fields: ["caption": caption])
                    }
                    
                    self.lastAIResponseTime = Date()
                    
                    self.conversationHistory.append(["role": "assistant", "content": chatResponse.text_response])
                
                    if !chatResponse.audio_base64.isEmpty,
                       let audioData = Data(base64Encoded: chatResponse.audio_base64) {
                        self.log("testing -> ConversationManager: Decoded audio data (size: \(audioData.count) bytes). Attempting to play.")
                        
                        guard !self.isSignedOut else {
                            self.log("testing -> ConversationManager: Not playing audio because user is signed out.")
                            return
                        }
                        self.isAISpeaking = true
                        self.log("testing -> ConversationManager: isAISpeaking = true (before TTS play)")
                       
                        self.updateConversationStatus(to: .isTalking)

                        // Attempt to start speech recognition for barge-in before TTS starts
                        if self.currentPhase == .initialDiscussion { // Or any other phase where barge-in is desired
                            self.log("testing -> ConversationManager: Starting speech recognition for barge-in capability.")
                            self.startSpeechRecognition()
                        }
                         
                        self.ttsManager?.playAudioData(audioData) {
                            DispatchQueue.main.async {
                                self.log("testing -> ConversationManager: TTS Audio playback completed (or was interrupted).")
                                // Only set isAISpeaking to false if it wasn't already cleared by an interruption.
                                if self.isAISpeaking {
                                    self.isAISpeaking = false
                                    self.log("testing -> ConversationManager: isAISpeaking = false (after TTS completion, no prior interruption)")
                                }
                                
                                if self.currentPhase != .ended {
                                    self.log("testing -> ConversationManager: TTS completed/stopped, current phase not .ended.")
                                    
                                    // If TTS completed normally (wasn't interrupted) and we need to ensure SR is running.
                                    // If an interruption happened, SR should already be active.
                                    // The startSpeechRecognition method should ideally be idempotent or handle being called if already running.
                                    if self.currentPhase == .initialDiscussion { // Check if SR is needed
                                         // We already attempted to start SR for barge-in.
                                         // If it stopped or didn't start, this is a fallback.
                                         // Or, if TTS completed fully, ensure SR is active for the next turn.
                                        self.log("testing -> ConversationManager: Ensuring speech recognition is active post-TTS for initialDiscussion.")
                                        self.startSpeechRecognition()
                                    } else if self.currentPhase == .meditating {
                                        // Auto-prompt logic for meditation phase
                                        self.log("testing -----> scheduleAutoPromptCheck (TTS completion - meditating)")
                                        self.scheduleAutoPromptCheck()
                                    }
                                    // If not meditating and not initialDiscussion, consider if other phases need SR or auto-prompt here.
                                    // General auto-prompt if not meditating.
                                    if self.currentPhase != .meditating {
                                       self.log("testing -----> scheduleAutoPromptCheck (TTS completion - non-meditating)")
                                       self.scheduleAutoPromptCheck()
                                    }

                                } else {
                                    self.log("testing -> ConversationManager: TTS completed, but current phase is .ended. Not starting speech recognition or auto-prompt.")
                                }
                            }
                        }
                    } else {
                        // No audio data received from backend
                        if chatResponse.audio_base64.isEmpty {
                            self.log("testing -> ConversationManager: No audio data received from backend. Will attempt to restart speech recognition.")
                        } else {
                            self.log("testing -> ConversationManager: Failed to decode base64 audio string from backend. Will attempt to restart speech recognition.")
                        }
                        // If no audio, AI is not speaking. Start recognition and auto-prompt immediately.
                        DispatchQueue.main.async {
                            if self.currentPhase != .ended {
                                self.log("testing -> ConversationManager: No audio from backend, current phase not .ended. Setting isAISpeaking=false, starting speech rec, scheduling auto-prompt.")
                                self.isAISpeaking = false
                                 self.log("testing -> ConversationManager: isAISpeaking = false (no audio from backend)")
                                self.startSpeechRecognition()
                                self.scheduleAutoPromptCheck()
                            } else {
                                 self.log("testing -> ConversationManager: No audio from backend, but current phase is .ended. Not starting SR or auto-prompt.")
                            }
                        }
                    }

                } catch {
                    self.log("testing -> ConversationManager: Backend JSON parsing failed", fields: ["error": error])
                    if let rawString = String(data: data, encoding: .utf8) {
                        self.log("testing -> ConversationManager: Failed to parse raw response string for debugging", fields: ["response": rawString])
                    }
                    
                    // self.isSendingChat = false // Already handled by defer
                    // log("testing -> ConversationManager: isSendingChat = false (json parsing error)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        if self.currentPhase != .ended {
                            self.log("testing -> ConversationManager: After JSON parsing error, scheduling auto-prompt check as phase is not .ended")
                            self.log("testing -----> scheduleAutoPromptCheck 556")
                            self.scheduleAutoPromptCheck()
                        }
                    }
                }
            }
            task.resume()
            log("testing -> ConversationManager: URLSession data task resumed.")
        }
    }

    
    // Utility for timestamped logs
    
    private func log(_ message: String, fields: [String: Any] = [:]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var allFields = fields
        allFields["phase"] = (self as? ConversationManager)?.currentPhase.rawValue ?? "N/A_CM"
        allFields["isAISpeaking"] = (self as? ConversationManager)?.isAISpeaking ?? false
        
        let fieldsString = allFields.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        if fieldsString.isEmpty {
            print("testing -> [LOG] [\(timestamp)] \(message)")
        } else {
            print("testing -> [LOG] [\(timestamp)] \(message) | \(fieldsString)")
        }
    }
    
    // speech recognition

    private func startSpeechRecognition() {
        log("testing -> ConversationManager: Attempting to start speech recognition.")
        if currentPhase == .meditating {
            log("testing -> ConversationManager: Not starting speech recognition because user is meditating.")
            return
        }
            
        // REMOVED: The check `if isAISpeaking || ttsManager?.isPlaying ?? false`
        // This removal is to allow SpeechManager to attempt recognition even during TTS playback (for barge-in).
        // The effectiveness of this relies heavily on Acoustic Echo Cancellation (AEC)
        // being properly implemented and effective within SpeechManager.swift.
        // If speechManager.startSpeechRecognition() is called while already recognizing,
        // it should ideally handle this gracefully (e.g., be a no-op or restart cleanly).

        log("testing -> ConversationManager: Requesting SpeechManager to start recognition. Current isAISpeaking: \(isAISpeaking), TTS playing: \(ttsManager?.isPlaying ?? false)")
        self.speechManager?.startSpeechRecognition()
        
        // Only update status to .isListening if AI is NOT currently speaking.
        // If AI is speaking, status should remain .isTalking while SR runs in background for barge-in.
        if !self.isAISpeaking {
            self.updateConversationStatus(to: .isListening)
        } else {
            log("testing -> ConversationManager: Speech recognition started for barge-in, but status remains .isTalking as AI is speaking.")
        }
    }
    
    
    private func updateConversationStatus(to status: ConversationStatus) {
        self.delegate?.conversationManagerStatus(status: status)
    }

    public func stopAllAudioAndRecording() {
        log("testing -> ConversationManager: stopAllAudioAndRecording called.")
        ttsManager?.stopPlayback()
        speechManager?.stopSpeechRecognition()
    }

    public func startMeditationTimer() {
        remainingSeconds = 300 // Reset to 5 minutes
        meditationProgress = 0
        
        sendToBackend()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.updateMeditationProgress()
                
                // Notify delegate of timer update
                let minutes = self.remainingSeconds / 60
                let seconds = self.remainingSeconds % 60
                self.onTimerUpdate?(minutes, seconds)
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.endMeditation()
            }
        }
    }
    
    private func updateMeditationProgress() {
        if remainingSeconds < 30 {
            meditationProgress = 100
        } else {
            meditationProgress = Int((Double(300 - remainingSeconds) / 300.0) * 100)
        }
    }
    
    private func endMeditation() {
        currentPhase = .initialDiscussion
        sendToBackend()
    }
    
    public func stopMeditationTimer() {
        timer?.invalidate()
        timer = nil
        remainingSeconds = 300
        meditationProgress = 0
    }
}

// Helper to convert [ChatMessage] to [[String: Any]] if needed by backend,
// though JSONEncoder should handle [ChatMessage] directly.
// This extension might not be strictly necessary if the backend expects an array of objects.
extension Encodable {
    func asDictionaryArray() throws -> [[String: Any]] {
        let data = try JSONEncoder().encode(self)
        guard let array = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] else {
            throw NSError()
        }
        return array
    }
}

// Define the structs for chat messages and responses
public struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let text_response: String
    let audio_base64: String
    let caption: String?
}

public enum ConversationStatus {
    case isListening
    case isTalking
    case isThinking
    case isInitializing
}

