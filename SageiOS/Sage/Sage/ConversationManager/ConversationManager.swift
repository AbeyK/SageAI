import Foundation
import FirebaseAuth // Assuming Firebase Auth is imported

public class ConversationManager: SpeechManagerDelegate {
    private let openAIKey: String
    private var speechManager: SpeechManager?
    private var ttsManager: TTSManager?
    private let session = URLSession.shared
    private var isSendingChat = false
    private var delegate: ConversationManagerDelegate?

    // 🔁 Store the conversation history
    private var conversationHistory: [[String: String]] = [
        ["role": "system", "content": "You are a helpful, voice-based assistant."]
    ] {
        didSet {
            if let last = conversationHistory.last,
               let content = last["content"] {
                delegate?.conversationManagerAddingMessage(content)
            }
        }
    }

    public init(apiKey: String, delegate: ConversationManagerDelegate) {
        self.delegate = delegate
        openAIKey = apiKey
        ttsManager = TTSManager(apiKey: "")

    public func startConversation() {
        speechManager = SpeechManager(delegate: self)
        print("testing -> conversationManager 🎙️ Starting conversation...")
        if let speechManager = speechManager {
            try? speechManager.startSpeechRecognition()
        }
        
    }
    
    public func speechManagerTranscriptCompleted(_ transcript: String) {
        if !isSendingChat {
            print("testing -> conversationManager calling speechManagerTranscriptCompleted \(transcript)")
            handleTranscript(transcript)
        }
    }

    private func handleTranscript(_ transcript: String) {
        print("testing -> conversationManager 📨 User said: \(transcript)")
        conversationHistory.append(["role": "user", "content": transcript])
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.sendToBackend()
        }
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
                // Optionally, inform the user or retry
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

            // Convert conversationHistory to array of ChatMessage objects for encoding
            let messagesPayload = self.conversationHistory.map { ChatMessage(role: $0["role"]!, content: $0["content"]!) }

            let payload: [String: Any] = [
                "messages": try? messagesPayload.asDictionaryArray()
            ]

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
                    self.conversationHistory.append(["role": "assistant", "content": chatResponse.text_response])
                
                    if !chatResponse.audio_base64.isEmpty,
                       let audioData = Data(base64Encoded: chatResponse.audio_base64) {
                        print("testing -> 🔊 Decoded audio data (size: \(audioData.count) bytes). Attempting to play.")
                        self.ttsManager?.playAudioData(audioData) {
                            DispatchQueue.main.async {
                                try? self.speechManager?.startSpeechRecognition()
                            }
                        }
                    } else {
                        if chatResponse.audio_base64.isEmpty {
                            print("testing -> 🔊 No audio data received. Using TTS for text response.")
                        } else {
                            print("testing -> ⚠️ Failed to decode base64 audio string. Using TTS for text response.")
                        }
                        // Fallback to TTS if no audio data or decoding fails
                        self.ttsManager?.speak(text: chatResponse.text_response) {
                            DispatchQueue.main.async {
                                try? self.speechManager?.startSpeechRecognition()
                            }
                        }
                    }

                } catch {
                    print("testing -> ❌ Backend JSON parsing failed: \(error)")
                    if let rawString = String(data: data, encoding: .utf8) {
                        print("testing -> 🧾 Failed to parse raw response string for debugging:\n\(rawString)")
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
struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let text_response: String
    let audio_base64: String
    let caption: String?
}
