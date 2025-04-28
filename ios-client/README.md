# SageAI iOS Client

This directory contains Swift code for the iOS client application that connects to the SageAI Meditation Backend.

## Files

- `SageAI.swift` - Core functionality for recording audio, communicating with the backend, and playing meditation audio
- `SwiftUIExample.swift` - Simple SwiftUI interface example

## Usage

1. Add these files to your Xcode project
2. Update the `backendURL` in `SageAI.swift` with your deployed backend URL
3. Make sure to add microphone usage description in your Info.plist:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need to access your microphone to record your voice for meditation guidance.</string>
```

## Implementation Details

The client implements a full voice-in → voice-out meditation chain:
1. Record audio from iPhone microphone
2. Send to backend for transcription
3. Generate personalized meditation content
4. Convert to speech and return audio to user 