import Foundation
import AVFoundation

class SageAI: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?

    let backendURL = "https://YOUR-FLY-APP.fly.dev"

    // 1. Start Recording
    func startRecording() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    // 2. Stop Recording and Upload Audio
    func stopRecordingAndSend() {
        audioRecorder?.stop()

        guard let audioURL = audioRecorder?.url else { return }
        uploadAudioForTranscription(audioURL: audioURL)
    }

    private func uploadAudioForTranscription(audioURL: URL) {
        var request = URLRequest(url: URL(string: "\(backendURL)/transcribe")!)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        data.append(try! Data(contentsOf: audioURL))
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        URLSession.shared.uploadTask(with: request, from: data) { responseData, response, error in
            if let data = responseData {
                if let decoded = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) {
                    print("Transcribed Text: \(decoded.text)")
                    self.generateMeditation(from: decoded.text)
                }
            }
        }.resume()
    }

    // 3. Send Transcribed Text to GPT-4o to Generate Meditation
    private func generateMeditation(from text: String) {
        var request = URLRequest(url: URL(string: "\(backendURL)/generate")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["text": text]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { responseData, response, error in
            if let data = responseData {
                if let decoded = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) {
                    print("Generated Meditation: \(decoded.text)")
                    self.textToSpeech(meditationText: decoded.text)
                }
            }
        }.resume()
    }

    // 4. Send Meditation Text to TTS and Play Audio
    private func textToSpeech(meditationText: String) {
        var request = URLRequest(url: URL(string: "\(backendURL)/speak")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["text": meditationText]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { responseData, response, error in
            if let audioData = responseData {
                DispatchQueue.main.async {
                    self.playMeditationAudio(audioData: audioData)
                }
            }
        }.resume()
    }

    private func playMeditationAudio(audioData: Data) {
        do {
            self.audioPlayer = try AVAudioPlayer(data: audioData)
            self.audioPlayer?.delegate = self
            self.audioPlayer?.play()
        } catch {
            print("Failed to play meditation audio: \(error.localizedDescription)")
        }
    }
}

// MARK: - Data Models
struct TranscriptionResponse: Codable {
    let text: String
} 