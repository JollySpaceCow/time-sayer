import Foundation
import AVFoundation

@main
struct SiriNaturalTester {
    static func main() {
        let naturalIds = [
            "com.apple.siri.natural.Gordon",
            "com.apple.siri.natural.Lee",
            "com.apple.siri.Gordon",
            "com.apple.siri.Lee",
            "com.apple.voice.natural.en-AU.Gordon",
            "com.apple.voice.natural.en-AU.Lee"
        ]

        for id in naturalIds {
            if let voice = AVSpeechSynthesisVoice(identifier: id) {
                print("✅ Found: \(id) -> Name: '\(voice.name)', Lang: '\(voice.language)', Gender: \(voice.gender.rawValue), Quality: \(voice.quality.rawValue)")
            } else {
                print("❌ Not found: \(id)")
            }
        }
    }
}
