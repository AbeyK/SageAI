import Foundation
import AVFoundation

public class TTSManager: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var completion: (() -> Void)?

    public var isPlaying: Bool {
        return player?.isPlaying ?? false
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
