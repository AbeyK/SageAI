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

    // Make delegate weak to prevent retain cycles
    private weak var delegate: ConversationManagerDelegate?
    
    // MARK: - Phase Management
    public enum MeditationPhase: String, CaseIterable {
        case idle
        case initialDiscussion // User and AI discuss problems
        case meditationStarting // AI has confirmed meditation, __PHASE2__ is about to be/has been sent
        case guidedPractice_Phase2 // Active meditation, guided by AI reacting to __PHASE2__
        case guidedPractice_Phase3 // Active meditation, guided by AI reacting to __PHASE3__
        case guidedPractice_Phase4 // Active meditation, guided by AI reacting to __PHASE4__
        case concludingMeditation_Phase5 // Active meditation, guided by AI reacting to __PHASE5__
        case retroDiscussion // Post-meditation chat
        case ended
    }

    private struct PhaseMarker {
        static let meditationStart = "__PHASE2__" // Formal start of guided practice
        static let growthReflection = "__PHASE3__"
        static let continuedBreathing = "__PHASE4__"
        static let conclusion = "__PHASE5__"
    }

    // Timings for the *structured part* of the meditation, once it begins
    private struct MeditationTimings {
        // Total meditation time: approx 5 minutes (300 seconds)
        // Allow 30-40 seconds for initial discussion
        static let discussionBeforeMeditationStart: TimeInterval = 40.0 // Reduced from 90s
        
        // Phase durations need to account for AI speech time
        static let phase2Duration: TimeInterval = 90.0 // Increased from 60s to account for audio playback
        static let phase3Duration: TimeInterval = 90.0 // Increased from 60s
        static let phase4Duration: TimeInterval = 80.0 // Increased from 60s
        // Phase 5 is the conclusion, no specific duration *after* it for another phase marker.
        
        // Auto-prompting timings
        static let userInactivityThreshold: TimeInterval = 90.0
        static let aiResponseTimeout: TimeInterval = 15.0
    }
    
    // Auto-prompting messages
    private let continuationPrompts = [
        "__CONTINUE__",
    ]

    public private(set) var currentPhase: MeditationPhase = .idle {
        didSet {
            log("Meditation phase changed from \(oldValue.rawValue) to: \(currentPhase.rawValue)")
            if currentPhase == .guidedPractice_Phase2 && oldValue != .guidedPractice_Phase2 {
                log("Meditation practice (Phase 2) has officially started.")
                // delegate?.meditationDidStart() // Uncomment if you add this delegate method
            }
            // delegate?.meditationPhaseDidChange(to: currentPhase) // Uncomment if you add this delegate method
        }
    }
    
    public var isMeditationActive: Bool {
        switch currentPhase {
        case .meditationStarting, .guidedPractice_Phase2, .guidedPractice_Phase3, .guidedPractice_Phase4, .concludingMeditation_Phase5:
            return true
        default:
            return false
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
            self.speechManager = SpeechManager(delegate: self)
        }
        log("Starting conversation...")
        if self.speechManager != nil { // Check the instance property
            initiateConversationFlow()
        } else {
            log("SpeechManager failed to initialize.", fields: ["error": true])
            // Handle error: speech manager couldn't be initialized
        }
    }
    
    private func initiateConversationFlow() {
        guard currentPhase == .idle else {
            log("Conversation or meditation already in progress.")
            return
        }
        log("Initiating conversation flow...")
        currentPhase = .initialDiscussion
        lastUserInteractionTime = Date()  // Initialize interaction time

        // Add an initial user message to kick off the conversation but don't add it to conversation history
        // This prevents showing an empty message in the UI
        let initialMessage = ["role": "user", "content": ""]

        DispatchQueue.global(qos: .userInitiated).async {
            // Send the initial message to the backend without adding it to conversation history
            self.sendToBackend(withMessage: initialMessage)
        }
        
        // Schedule the *start* of the formal meditation (__PHASE2__)
        // This timer represents the period for initial discussion. The AI is expected
        // to have guided the user towards agreeing to meditate within this time.
        scheduleNextPhase(
            marker: PhaseMarker.meditationStart,
            delay: MeditationTimings.discussionBeforeMeditationStart,
            fromPhase: .initialDiscussion, // Prerequisite phase
            toPhase: .meditationStarting // Target state before AI acts on marker
        )
        
        // Start monitoring for auto-prompting
        scheduleAutoPromptCheck()
    }
    
    public func speechManagerTranscriptCompleted(_ transcript: String) {
        if !isSendingChat {
            log("User transcript completed", fields: ["transcript": transcript])
            lastUserInteractionTime = Date() // Update user interaction time
            handleTranscript(transcript)
        }
    }

    private func handleTranscript(_ transcript: String) {
        log("User said", fields: ["transcript": transcript])
        // Ignore phase markers in user transcripts (shouldn't happen, but safety check)
        if transcript.starts(with: "__PHASE") {
            log("Ignoring phase marker in user transcript", fields: ["transcript": transcript])
            return
        }
        
        // Cancel any pending auto-prompt since user has spoken
        cancelAutoPrompt()
        
        conversationHistory.append(["role": "user", "content": transcript])
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend()
        }
        
        // Reset auto-prompt scheduling after user speaks
        scheduleAutoPromptCheck()
    }

    // MARK: - Auto-Prompting Logic
    
    private func scheduleAutoPromptCheck() {
        // Cancel any existing auto-prompt timer
        cancelAutoPrompt()
        
        // Create a new timer to check for inactivity
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.currentPhase != .idle && self.currentPhase != .ended else { return }
            
            let now = Date()
            let timeSinceUserInteraction = now.timeIntervalSince(self.lastUserInteractionTime)
            let timeSinceAIResponse = now.timeIntervalSince(self.lastAIResponseTime)
            
            // Don't auto-prompt if AI is currently speaking
            if self.isAISpeaking {
                log("Delaying auto-prompt because AI is speaking")
                self.scheduleAutoPromptCheck() // Check again later
                return
            }
            
            // Auto-prompt if user has been inactive for the threshold period
            if timeSinceUserInteraction >= MeditationTimings.userInactivityThreshold {
                log("Auto-prompting due to user inactivity (\(timeSinceUserInteraction) seconds)")
                self.sendContinuationPrompt()
                return
            }
            
            // If AI hasn't responded for a while and we've sent a message, consider re-prompting
            if timeSinceAIResponse >= MeditationTimings.aiResponseTimeout && self.isSendingChat {
                log("Auto-prompting due to AI response timeout (\(timeSinceAIResponse) seconds)")
                self.sendContinuationPrompt()
                return
            }
            
            // Otherwise, schedule another check
            self.scheduleAutoPromptCheck()
        }
        
        autoPromptTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: workItem) // Check every 10 seconds
    }
    
    private func cancelAutoPrompt() {
        autoPromptTimer?.cancel()
        autoPromptTimer = nil
    }
    
    private func sendContinuationPrompt() {
        guard currentPhase != .idle && currentPhase != .ended && !isAISpeaking else {
            log("Skipping continuation prompt due to phase or AI speaking state")
            return
        }
        
        // Select a random prompt, but avoid repeating the last one
        var promptIndex = Int.random(in: 0..<continuationPrompts.count)
        if promptIndex == lastContinuationPromptIndex && continuationPrompts.count > 1 {
            promptIndex = (promptIndex + 1) % continuationPrompts.count
        }
        lastContinuationPromptIndex = promptIndex
        
        let prompt = continuationPrompts[promptIndex]
        log("Sending auto-continuation prompt: \"\(prompt)\"")
        
        // Send the continuation prompt directly to the backend without adding to conversation history
        let continuationMessage = ["role": "user", "content": prompt]
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend(withMessage: continuationMessage)
        }
        
        // Reset the interaction time
        lastUserInteractionTime = Date()
        
        // Schedule the next auto-prompt check
        scheduleAutoPromptCheck()
    }

    // MARK: - Meditation Sequence Logic
    
    private func scheduleNextPhase(marker: String, delay: TimeInterval, fromPhase prerequisitePhase: MeditationPhase, toPhase targetPhase: MeditationPhase) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            // Ensure we are in the correct prerequisite phase or that the session is still active for meditation
            guard self.currentPhase == prerequisitePhase || (self.isMeditationActive && self.currentPhase != .ended && self.currentPhase != .idle) else {
                log("Prerequisite phase \(prerequisitePhase.rawValue) not met (current: \(self.currentPhase.rawValue)) or meditation inactive. Cancelling transition to \(targetPhase.rawValue).", fields: ["current_phase": self.currentPhase.rawValue, "marker": marker])
                return
            }
            
            // Check if AI is currently speaking, if so delay the phase transition
            if self.isAISpeaking {
                log("Delaying phase transition to \(targetPhase.rawValue) because AI is speaking", fields: ["current_phase": self.currentPhase.rawValue, "marker": marker])
                // Reschedule the phase transition after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.scheduleNextPhase(
                        marker: marker,
                        delay: 0.1, // Small delay since we're just checking again
                        fromPhase: prerequisitePhase,
                        toPhase: targetPhase
                    )
                }
                return
            }

            log("Timer elapsed for phase: \(targetPhase.rawValue). Sending marker: \(marker)", fields: ["elapsed_time": delay])
            self.currentPhase = targetPhase
            
            // Cancel any pending auto-prompt since we're sending a phase marker
            self.cancelAutoPrompt()
            
            self.sendPhaseMarkerToBackend(marker)

            // Schedule the *next* marker based on the one just sent
            switch marker {
            case PhaseMarker.meditationStart: // __PHASE2__ was sent
                self.currentPhase = .guidedPractice_Phase2
                // Tracking time actually spent in this phase
                let phaseStartTime = Date()
                log("Phase 2 started", fields: ["start_time": phaseStartTime])
                
                self.scheduleNextPhase(
                    marker: PhaseMarker.growthReflection,
                    delay: MeditationTimings.phase2Duration,
                    fromPhase: .guidedPractice_Phase2,
                    toPhase: .guidedPractice_Phase3
                )
            case PhaseMarker.growthReflection: // __PHASE3__ was sent
                self.currentPhase = .guidedPractice_Phase3
                // Tracking time actually spent in this phase
                let phaseStartTime = Date()
                log("Phase 3 started", fields: ["start_time": phaseStartTime])
                
                self.scheduleNextPhase(
                    marker: PhaseMarker.continuedBreathing,
                    delay: MeditationTimings.phase3Duration,
                    fromPhase: .guidedPractice_Phase3,
                    toPhase: .guidedPractice_Phase4
                )
            case PhaseMarker.continuedBreathing: // __PHASE4__ was sent
                self.currentPhase = .guidedPractice_Phase4
                // Tracking time actually spent in this phase
                let phaseStartTime = Date()
                log("Phase 4 started", fields: ["start_time": phaseStartTime])
                
                self.scheduleNextPhase(
                    marker: PhaseMarker.conclusion,
                    delay: MeditationTimings.phase4Duration,
                    fromPhase: .guidedPractice_Phase4,
                    toPhase: .concludingMeditation_Phase5
                )
            case PhaseMarker.conclusion: // __PHASE5__ was sent
                self.currentPhase = .concludingMeditation_Phase5
                log("Conclusion marker sent. AI will wrap up. Meditation sequence finished from client perspective.")
                // Transition to retroDiscussion after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Give AI time to respond to __PHASE5__
                    if self.currentPhase == .concludingMeditation_Phase5 {
                         self.currentPhase = .retroDiscussion
                        self.log("Transitioned to retroDiscussion phase, awaiting user or AI.")
                        // Reset auto-prompt check for the retro discussion
                        self.scheduleAutoPromptCheck()
                    }
                }
            default:
                log("Unknown marker for scheduling next phase: \(marker)")
            }
            
            // After sending any phase marker, reset auto-prompt scheduling
            self.scheduleAutoPromptCheck()
        }
        
        phaseTimers.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        log("Scheduled marker '\(marker)' for phase \(targetPhase.rawValue) in \(delay)s. Prerequisite: \(prerequisitePhase.rawValue)")
    }

    private func sendPhaseMarkerToBackend(_ marker: String) {
        // If the AI is currently speaking, delay sending the phase marker
        if isAISpeaking {
            log("Delaying sending phase marker: \(marker) because AI is speaking")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.sendPhaseMarkerToBackend(marker)
            }
            return
        }
        
        log("Client sending phase marker to backend: \(marker)")
        
        // Send phase marker directly to backend without adding to conversation history
        let phaseMarkerMessage = ["role": "user", "content": marker]
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend(withMessage: phaseMarkerMessage)
        }
    }

    public func stopConversationAndMeditation() {
        log("Stopping conversation and meditation explicitly.")
        cancelAllPhaseTimers()
        cancelAutoPrompt()
        if speechManager != nil {
            // Optionally stop speech recognition if it's continuously running
            // speechManager?.stopSpeechRecognition()
        }
        currentPhase = .ended
    }

    private func cancelAllPhaseTimers() {
        phaseTimers.forEach { $0.cancel() }
        phaseTimers.removeAll()
        log("All phase timers cancelled.")
    }

    // Placeholder for Firebase ID Token - Replace with your actual implementation
    private func getCurrentUserIDToken(completion: @escaping (String?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            currentUser.getIDToken { [weak self] token, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.log("Error fetching ID token", fields: ["error": error.localizedDescription])
                    completion(nil)
                    return
                }
                completion(token)
            }
        } else {
            log("No current user for ID token.")
            completion(nil)
        }
    }

    private func sendToBackend() {
        guard !isSendingChat else {
            log("Already sending request, ignoring duplicate.")
            return
        }
        
        // Use the conversation history for regular sends
        let messagesPayload = self.conversationHistory.map { ChatMessage(role: $0["role"]!, content: $0["content"]!) }
        sendToBackend(withMessages: messagesPayload)
    }
    
    private func sendToBackend(withMessage message: [String: String]) {
        // Create a single message payload without affecting conversation history
        let messagePayload = [ChatMessage(role: message["role"]!, content: message["content"]!)]
        sendToBackend(withMessages: messagePayload)
    }
    
    private func sendToBackend(withMessages messages: [ChatMessage]) {
        guard !isSendingChat else {
            log("Already sending request, ignoring duplicate.")
            return
        }

        isSendingChat = true
        self.updateConversationStatus(to: .isThinking)

        getCurrentUserIDToken { [weak self] idToken in
            guard let self = self else { return }
            guard let token = idToken else {
                self.log("Failed to get ID Token.")
                self.isSendingChat = false
                return
            }
            
            guard let url = URL(string: "https://sage-ai-backend.fly.dev/api/v1/chat") else {
                self.log("Invalid URL.")
                self.isSendingChat = false
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                let jsonData = try JSONEncoder().encode(["messages": messages])
                request.httpBody = jsonData
            } catch {
                self.log("Failed to encode request", fields: ["error": error])
                self.isSendingChat = false
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                defer { self.isSendingChat = false }

                if let error = error as? URLError {
                    self.log("Backend error", fields: ["error": error.localizedDescription, "code": error.code])
                    if error.code == .networkConnectionLost {
                        self.log("Retrying after connection lost...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            self.sendToBackend(withMessages: messages)
                        }
                    }
                    return
                }

                guard let data = data else {
                    self.log("No data from backend.")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    self.log("Backend HTTP status code", fields: ["code": httpResponse.statusCode])
                }
                
                if let raw = String(data: data, encoding: .utf8) {
                    self.log("Raw backend response", fields: ["response": raw.prefix(1000)])
                }
                
                do {
                    let decoder = JSONDecoder()
                    let chatResponse = try decoder.decode(ChatResponse.self, from: data)

                    self.log("Backend Response (text)", fields: ["response": chatResponse.text_response])
                    if let caption = chatResponse.caption {
                        self.log("Backend Response (caption)", fields: ["caption": caption])
                    }
                    
                    self.lastAIResponseTime = Date()
                    
                    self.conversationHistory.append(["role": "assistant", "content": chatResponse.text_response])
                
                    if !chatResponse.audio_base64.isEmpty,
                       let audioData = Data(base64Encoded: chatResponse.audio_base64) {
                        self.log("Decoded audio data (size: \(audioData.count) bytes). Attempting to play.")
                        
                        self.isAISpeaking = true
                       
                        self.updateConversationStatus(to: .isTalking)
                         
                        self.ttsManager?.playAudioData(audioData) {
                            DispatchQueue.main.async {
                                self.log("Audio playback completed")
                                self.isAISpeaking = false
                                
                                // Ensure that we check if any phases were missed or interrupted
                                if self.currentPhase != .ended {
                                    self.startSpeechRecognition()
                                    
                                    // Note: This reschedules auto-prompt but doesn't immediately send one
                                    self.scheduleAutoPromptCheck()
                                }
                            }
                        }
                    } else {
                        if chatResponse.audio_base64.isEmpty {
                            self.log("No audio data received from backend. Speech recognition will be restarted.")
                        } else {
                            self.log("Failed to decode base64 audio string from backend. Speech recognition will be restarted.")
                        }
                        DispatchQueue.main.async {
                            if self.currentPhase != .ended {
                                self.startSpeechRecognition()
                                self.scheduleAutoPromptCheck()
                            }
                        }
                    }

                } catch {
                    self.log("Backend JSON parsing failed", fields: ["error": error])
                    if let rawString = String(data: data, encoding: .utf8) {
                        self.log("Failed to parse raw response string for debugging", fields: ["response": rawString])
                    }
                    
                    self.isSendingChat = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        if self.currentPhase != .ended {
                            self.scheduleAutoPromptCheck()
                        }
                    }
                }
            }
            task.resume()
        }
    }

    // Utility for timestamped logs
    private func log(_ message: String, fields: [String: Any] = [:]) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var allFields = fields
        allFields["phase"] = currentPhase.rawValue
        allFields["isAISpeaking"] = isAISpeaking
        
        let fieldsString = allFields.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        if fieldsString.isEmpty {
            print("[LOG] [\(timestamp)] \(message)")
        } else {
            print("[LOG] [\(timestamp)] \(message) | \(fieldsString)")
        }
    }

    private func startSpeechRecognition() {
        if  currentPhase == .guidedPractice_Phase3 || currentPhase == .guidedPractice_Phase4 {
            return 
        }

        if !(ttsManager?.isPlaying ?? false) {
            self.speechManager?.startSpeechRecognition()
            self.updateConversationStatus(to: .isListening)
        }
    }

    private func updateConversationStatus(to status: ConversationStatus) {
        self.delegate?.conversationManagerStatus(status: status)
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
}
