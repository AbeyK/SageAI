import Foundation
import FirebaseAuth // Assuming Firebase Auth is imported

public class ConversationManager: SpeechManagerDelegate {
    private var speechManager: SpeechManager?
    private var ttsManager: TTSManager?
    private let session = URLSession.shared
    private var isSendingChat = false
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
        static let discussionBeforeMeditationStart: TimeInterval = 90.0 // Approx time for AI to chat and suggest meditation before PHASE2 is auto-sent
        static let phase2Duration: TimeInterval = 120.0 // Duration for AI guidance in Phase 2
        static let phase3Duration: TimeInterval = 120.0 // Duration for AI guidance in Phase 3
        static let phase4Duration: TimeInterval = 120.0 // Duration for AI guidance in Phase 4
        // Phase 5 is the conclusion, no specific duration *after* it for another phase marker.
        
        // Auto-prompting timings
        static let userInactivityThreshold: TimeInterval = 30.0 // If no user input for this duration, consider auto-prompt
        static let aiResponseTimeout: TimeInterval = 15.0 // If AI doesn't respond within this time, consider re-prompting
    }
    
    // Auto-prompting messages
    private let continuationPrompts = [
        "Please continue.",
        "I'm ready for the next step.",
        "What's next in our practice?",
        "Continue with the meditation.",
        "I'm still here, please continue."
    ]

    public private(set) var currentPhase: MeditationPhase = .idle {
        didSet {
            print("testing -> Meditation phase changed from \(oldValue.rawValue) to: \(currentPhase.rawValue)")
            if currentPhase == .guidedPractice_Phase2 && oldValue != .guidedPractice_Phase2 {
                print("testing -> Meditation practice (Phase 2) has officially started.")
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
    
    private var phaseTimers: [DispatchWorkItem] = []
    private var autoPromptTimer: DispatchWorkItem?
    private var lastUserInteractionTime = Date()
    private var lastAIResponseTime = Date()
    private var isAISpeaking = false
    private var lastContinuationPromptIndex = -1

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
                        self.delegate?.conversationManagerDidAddMessage(chatMessage)
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
        print("testing -> conversationManager 🎙️ Starting conversation...")
        if self.speechManager != nil { // Check the instance property
            initiateConversationFlow()
        } else {
            print("testing -> conversationManager ❌ SpeechManager failed to initialize.")
            // Handle error: speech manager couldn't be initialized
        }
    }
    
    private func initiateConversationFlow() {
        guard currentPhase == .idle else {
            print("testing -> Conversation or meditation already in progress.")
            return
        }
        print("testing -> Initiating conversation flow...")
        currentPhase = .initialDiscussion
        lastUserInteractionTime = Date()  // Initialize interaction time

        // Add an initial user message to kick off the conversation
        conversationHistory.append(["role": "user", "content": "Hello Sage, I'm ready to begin."])

        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend() // AI will respond with its greeting and start STAGE 1 of prompt.
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
            print("testing -> conversationManager calling speechManagerTranscriptCompleted \(transcript)")
            lastUserInteractionTime = Date() // Update user interaction time
            handleTranscript(transcript)
        }
    }

    private func handleTranscript(_ transcript: String) {
        print("testing -> conversationManager 📨 User said: \(transcript)")
        // Ignore phase markers in user transcripts (shouldn't happen, but safety check)
        if transcript.starts(with: "__PHASE") {
            print("testing -> Ignoring phase marker in user transcript: \(transcript)")
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
                print("testing -> Delaying auto-prompt because AI is speaking")
                self.scheduleAutoPromptCheck() // Check again later
                return
            }
            
            // Auto-prompt if user has been inactive for the threshold period
            if timeSinceUserInteraction >= MeditationTimings.userInactivityThreshold {
                print("testing -> Auto-prompting due to user inactivity (\(timeSinceUserInteraction) seconds)")
                self.sendContinuationPrompt()
                return
            }
            
            // If AI hasn't responded for a while and we've sent a message, consider re-prompting
            if timeSinceAIResponse >= MeditationTimings.aiResponseTimeout && self.isSendingChat {
                print("testing -> Auto-prompting due to AI response timeout (\(timeSinceAIResponse) seconds)")
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
            print("testing -> Skipping continuation prompt due to phase or AI speaking state")
            return
        }
        
        // Select a random prompt, but avoid repeating the last one
        var promptIndex = Int.random(in: 0..<continuationPrompts.count)
        if promptIndex == lastContinuationPromptIndex && continuationPrompts.count > 1 {
            promptIndex = (promptIndex + 1) % continuationPrompts.count
        }
        lastContinuationPromptIndex = promptIndex
        
        let prompt = continuationPrompts[promptIndex]
        print("testing -> Sending auto-continuation prompt: \"\(prompt)\"")
        
        // Send the continuation prompt to the backend
        conversationHistory.append(["role": "user", "content": prompt])
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend()
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
                print("testing -> Prerequisite phase \(prerequisitePhase.rawValue) not met (current: \(self.currentPhase.rawValue)) or meditation inactive. Cancelling transition to \(targetPhase.rawValue).")
                return
            }

            print("testing -> Timer elapsed for phase: \(targetPhase.rawValue). Sending marker: \(marker)")
            self.currentPhase = targetPhase
            
            // Cancel any pending auto-prompt since we're sending a phase marker
            self.cancelAutoPrompt()
            
            self.sendPhaseMarkerToBackend(marker)

            // Schedule the *next* marker based on the one just sent
            switch marker {
            case PhaseMarker.meditationStart: // __PHASE2__ was sent
                self.currentPhase = .guidedPractice_Phase2
                self.scheduleNextPhase(
                    marker: PhaseMarker.growthReflection,
                    delay: MeditationTimings.phase2Duration,
                    fromPhase: .guidedPractice_Phase2,
                    toPhase: .guidedPractice_Phase3
                )
            case PhaseMarker.growthReflection: // __PHASE3__ was sent
                self.currentPhase = .guidedPractice_Phase3
                self.scheduleNextPhase(
                    marker: PhaseMarker.continuedBreathing,
                    delay: MeditationTimings.phase3Duration,
                    fromPhase: .guidedPractice_Phase3,
                    toPhase: .guidedPractice_Phase4
                )
            case PhaseMarker.continuedBreathing: // __PHASE4__ was sent
                self.currentPhase = .guidedPractice_Phase4
                self.scheduleNextPhase(
                    marker: PhaseMarker.conclusion,
                    delay: MeditationTimings.phase4Duration,
                    fromPhase: .guidedPractice_Phase4,
                    toPhase: .concludingMeditation_Phase5
                )
            case PhaseMarker.conclusion: // __PHASE5__ was sent
                self.currentPhase = .concludingMeditation_Phase5
                print("testing -> Conclusion marker sent. AI will wrap up. Meditation sequence finished from client perspective.")
                // Transition to retroDiscussion after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Give AI time to respond to __PHASE5__
                    if self.currentPhase == .concludingMeditation_Phase5 {
                         self.currentPhase = .retroDiscussion
                        print("testing -> Transitioned to retroDiscussion phase, awaiting user or AI.")
                        // Reset auto-prompt check for the retro discussion
                        self.scheduleAutoPromptCheck()
                    }
                }
            default:
                print("testing -> Unknown marker for scheduling next phase: \(marker)")
            }
            
            // After sending any phase marker, reset auto-prompt scheduling
            self.scheduleAutoPromptCheck()
        }
        
        phaseTimers.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        print("testing -> Scheduled marker '\(marker)' for phase \(targetPhase.rawValue) in \(delay)s. Prerequisite: \(prerequisitePhase.rawValue)")
    }

    private func sendPhaseMarkerToBackend(_ marker: String) {
        print("testing -> Client sending phase marker to backend: \(marker)")
        conversationHistory.append(["role": "user", "content": marker])
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend()
        }
    }

    public func stopConversationAndMeditation() {
        print("testing -> Stopping conversation and meditation explicitly.")
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
        print("testing -> All phase timers cancelled.")
    }

    // Placeholder for Firebase ID Token - Replace with your actual implementation
    private func getCurrentUserIDToken(completion: @escaping (String?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            currentUser.getIDToken { token, error in
                if let error = error {
                    print("testing -> conversationManager ❌ Error fetching ID token: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(token)
            }
        } else {
            print("testing -> conversationManager ❌ No current user for ID token.")
            completion(nil)
        }
    }

    private func sendToBackend() {
        guard !isSendingChat else {
            print("testing -> 🛑 Already sending request, ignoring duplicate.")
            return
        }
        isSendingChat = true

        getCurrentUserIDToken { [weak self] idToken in
            guard let self = self else { return }
            guard let token = idToken else {
                print("testing -> conversationManager ❌ Failed to get ID Token.")
                self.isSendingChat = false
                return
            }
            
            guard let url = URL(string: "https://sage-ai-backend.fly.dev/api/v1/chat") else {
                print("testing -> conversationManager ❌ Invalid URL.")
                self.isSendingChat = false
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let messagesPayload = self.conversationHistory.map { ChatMessage(role: $0["role"]!, content: $0["content"]!) }

            do {
                let jsonData = try JSONEncoder().encode(["messages": messagesPayload])
                request.httpBody = jsonData
            } catch {
                print("testing -> conversationManager ❌ Failed to encode request: \(error)")
                self.isSendingChat = false
                return
            }
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                defer { self.isSendingChat = false }

                if let error = error as? URLError {
                    print("testing -> conversationManager ❌ Backend error: \(error.localizedDescription) [code: \(error.code)] and \(error)")
                    if error.code == .networkConnectionLost {
                        print("testing -> 🔁 Retrying after connection lost...")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            self.sendToBackend()
                        }
                    }
                    return
                }

                guard let data = data else {
                    print("testing -> conversationManager ❌ No data from backend.")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("testing -> Backend HTTP status code: \(httpResponse.statusCode)")
                }
                
                if let raw = String(data: data, encoding: .utf8) {
                    print("testing -> conversationManager 🧾 Raw backend response: \(raw.prefix(1000))")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let chatResponse = try decoder.decode(ChatResponse.self, from: data)

                    print("testing -> 💬 Backend Response (text): \(chatResponse.text_response)")
                    if let caption = chatResponse.caption {
                        print("testing -> <caption> Backend Response (caption): \(caption)")
                    }
                    
                    self.lastAIResponseTime = Date()
                    
                    self.conversationHistory.append(["role": "assistant", "content": chatResponse.text_response])
                
                    if !chatResponse.audio_base64.isEmpty,
                       let audioData = Data(base64Encoded: chatResponse.audio_base64) {
                        print("testing -> 🔊 Decoded audio data (size: \(audioData.count) bytes). Attempting to play.")
                        
                        self.isAISpeaking = true
                        
                        self.ttsManager?.playAudioData(audioData) {
                            DispatchQueue.main.async {
                                self.isAISpeaking = false
                                if self.currentPhase != .ended {
                                    self.speechManager?.startSpeechRecognition()
                                    self.scheduleAutoPromptCheck()
                                }
                            }
                        }
                    } else {
                        if chatResponse.audio_base64.isEmpty {
                            print("testing -> 🔊 No audio data received from backend. Speech recognition will be restarted.")
                        } else {
                            print("testing -> ⚠️ Failed to decode base64 audio string from backend. Speech recognition will be restarted.")
                        }
                        DispatchQueue.main.async {
                            if self.currentPhase != .ended {
                                self.speechManager?.startSpeechRecognition()
                                self.scheduleAutoPromptCheck()
                            }
                        }
                    }

                } catch {
                    print("testing -> ❌ Backend JSON parsing failed: \(error)")
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("testing -> 🧾 Failed to parse raw response string for debugging:\n\(rawString)")
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
