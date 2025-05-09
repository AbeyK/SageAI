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

        guard let url = URL(string: "https://sanity.com") else {
            print("testing -> TTSManager ❌ Invalid URL")
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
            print("testing -> TTSManager ❌ Failed to encode request: \(error)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                print("testing -> TTSManager ❌ Request error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("testing -> TTSManager ❌ No data received")
                return
            }

            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(
                        .playAndRecord,
                        mode: .default,
                        options: [.mixWithOthers, .duckOthers, .defaultToSpeaker, .defaultToSpeaker, .allowBluetooth]
                    )
                    try AVAudioSession.sharedInstance().setActive(true)

                    self.player = try AVAudioPlayer(data: data)
                    self.player?.delegate = self
                    self.player?.prepareToPlay()
                    self.player?.play()
                    print("testing -> TTSManager 🔊 Playing speech")
                } catch {
                    print("testing -> TTSManager ❌ Audio playback error: \(error)")
                }
            }
        }

        task.resume()
    }

    public func playAudioData(_ data: Data, onComplete: (() -> Void)? = nil) {
        self.completion = onComplete
        DispatchQueue.main.async {
            do {
                try AVAudioSession.sharedInstance().setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.mixWithOthers, .duckOthers, .defaultToSpeaker, .allowBluetooth]
                )
                try AVAudioSession.sharedInstance().setActive(true)

                self.player = try AVAudioPlayer(data: data)
                self.player?.delegate = self
                self.player?.prepareToPlay()
                self.player?.play()
                print("testing -> TTSManager 🔊 Playing audio data")
            } catch {
                print("testing -> TTSManager ❌ Audio playback error from data: \(error)")
                self.completion?() // Call completion if playback fails to start
            }
        }
    }

    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("testing -> TTSManager ✅ Playback finished")
        completion?()
    }
}
