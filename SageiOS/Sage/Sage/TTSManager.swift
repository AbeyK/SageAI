import Foundation
import AVFoundation

public class TTSManager: NSObject, AVAudioPlayerDelegate {
    private let openAIKey: String
    private var player: AVAudioPlayer?
    private var completion: (() -> Void)?

    public init(apiKey: String) {
        self.openAIKey = apiKey
    }

    public func speak(text: String, onComplete: (() -> Void)? = nil) {
        self.completion = onComplete

        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
            print("TTSManager ❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": "nova",
            "response_format": "mp3"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("TTSManager ❌ Failed to encode request: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                print("TTSManager ❌ Request error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("TTSManager ❌ No data received")
                return
            }

            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(
                        .playback,
                        mode: .default,
                        options: [.defaultToSpeaker, .allowBluetooth]
                    )
                    try AVAudioSession.sharedInstance().setActive(true)

                    self.player = try AVAudioPlayer(data: data)
                    self.player?.delegate = self
                    self.player?.prepareToPlay()
                    self.player?.play()
                    print("TTSManager 🔊 Playing speech")
                } catch {
                    print("TTSManager ❌ Audio playback error: \(error)")
                }
            }
        }

        task.resume()
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("TTSManager ✅ Playback finished")
        completion?()
    }
}
