import SwiftUI

struct ContentView: View {
    let sageAI = SageAI()

    var body: some View {
        VStack(spacing: 20) {
            Button("Start Recording") {
                sageAI.startRecording()
            }
            Button("Stop & Meditate") {
                sageAI.stopRecordingAndSend()
            }
        }
        .padding()
    }
} 