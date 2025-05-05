import Foundation

public class ConversationManager: SpeechManagerDelegate {
    private let openAIKey: String
    private var speechManager: SpeechManager?
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
    }

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
            self.sendToChatGPT()
        }
    }

    private func sendToChatGPT() {
        guard !isSendingChat else {
            print("testing -> 🛑 Already sending request, ignoring duplicate.")
            return
        }
        isSendingChat = true
                
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            print("testing -> conversationManager ❌ Invalid URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": conversationHistory,
            "temperature": 0.7
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("testing -> conversationManager ❌ Failed to encode request: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error as? URLError {
                print("testing -> conversationManager ❌ ChatGPT error: \(error.localizedDescription) [code: \(error.code)] and \(error)")
                if error.code == .networkConnectionLost {
                    print("testing -> 🔁 Retrying after connection lost...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        self.sendToChatGPT()
                    }
                }
                self.isSendingChat = false
                return
            }

            guard let data = data else {
                print("testing -> conversationManager ❌ No data from OpenAI.")
                return
            }

            if let response = response {
                print("testing -> response: \(response)")
            }
            // 🧾 Debug raw response
            if let raw = String(data: data, encoding: .utf8) {
                print("testing -> conversationManager 🧾 Raw response: \(raw)")
                print("testing -> 🧾 Raw response (truncated): \(raw.prefix(500))")
            }
            
            do {
                let rawString = String(data: data, encoding: .utf8) ?? "N/A"
                print("testing -> 🧾 Full raw response:\n\(rawString)")

                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("testing -> ❌ Failed to cast JSON root object.")
                    return
                }

                if let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let message = first["message"] as? [String: Any],
                   let content = message["content"] as? String {

                    print("testing -> 💬 ChatGPT Response: \(content)")
                    self.conversationHistory.append(["role": "assistant", "content": content])
                    self.isSendingChat = false
                    DispatchQueue.main.async {
                        try? self.speechManager?.startSpeechRecognition()
                    }
                } else if let error = json["error"] as? [String: Any] {
                    self.isSendingChat = false
                    print("testing -> ❌ OpenAI Error Object: \(error)")
                } else {
                    self.isSendingChat = false
                    print("testing -> ⚠️ Unexpected JSON structure. Dumping:\n\(json)")
                }

            } catch {
                self.isSendingChat = false
                print("testing -> ❌ JSON parsing failed: \(error)")
            }
        }

        task.resume()
    }
}
