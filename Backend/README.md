# Sage AI Meditation Guide Backend

A FastAPI backend service that provides real-time meditation guidance using OpenAI's GPT-4 and Text-to-Speech APIs.

## Local Development Setup

### Prerequisites
- Python 3.10 or higher
- OpenAI API key
- iOS device for testing

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd Backend
```

2. Create and activate a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create a `.env` file in the root directory:
```
OPENAI_API_KEY=your_api_key_here
```

### Running the Server

1. Start the FastAPI server:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The server will be available at:
- Web interface: `http://localhost:8000`
- WebSocket endpoint: `ws://localhost:8000/ws`

## Connecting from iOS

### Local Network Setup

1. Find your computer's local IP address:
   - On macOS: Open Terminal and run `ifconfig | grep "inet " | grep -v 127.0.0.1`
   - On Windows: Open Command Prompt and run `ipconfig`
   - Look for an IP address like `192.168.x.x` or `10.0.x.x`

2. Ensure your iOS device is on the same WiFi network as your computer.

3. In your iOS app, use the following WebSocket URL:
```
ws://<your-local-ip>:8000/ws
```
For example: `ws://192.168.1.100:8000/ws`

### iOS Client Implementation

Here's a basic example using Swift and URLSessionWebSocketTask:

```swift
import Foundation

class WebSocketManager {
    private var webSocket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    
    func connect() {
        // Replace with your computer's local IP address
        let url = URL(string: "ws://192.168.1.100:8000/ws")!
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        receiveMessage()
    }
    
    func sendMessage(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocket?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    // Handle binary audio data
                    self?.playAudio(data)
                case .string(let text):
                    print("Received text: \(text)")
                @unknown default:
                    break
                }
                // Continue receiving messages
                self?.receiveMessage()
            case .failure(let error):
                print("Error receiving message: \(error)")
            }
        }
    }
    
    private func playAudio(_ data: Data) {
        // Implement audio playback using AVFoundation
        // Example:
        // let player = try? AVAudioPlayer(data: data)
        // player?.play()
    }
}
```

### Testing the Connection

1. Start the server on your computer:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

2. Run your iOS app and connect to the WebSocket.

3. Send a test message:
```swift
let manager = WebSocketManager()
manager.connect()
manager.sendMessage("Hello, can you guide me through a meditation?")
```

### Troubleshooting

1. **Connection Refused**
   - Ensure your computer's firewall allows incoming connections on port 8000
   - Verify both devices are on the same network
   - Double-check the IP address and port number

2. **No Audio Response**
   - Check the server logs for any errors
   - Verify the OpenAI API key is valid
   - Ensure the audio data is being properly decoded and played

3. **WebSocket Disconnects**
   - Implement reconnection logic in your iOS app
   - Check for network stability
   - Monitor server logs for any errors

## API Endpoints

- `GET /`: Web interface
- `WebSocket /ws`: Real-time communication endpoint
  - Send: Text messages
  - Receive: Audio data in WAV format

## Environment Variables

- `OPENAI_API_KEY`: Your OpenAI API key

## Dependencies

See `requirements.txt` for Python dependencies. 