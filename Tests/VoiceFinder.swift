import Foundation
import AVFoundation

@main
struct VoiceFinder {
    static func main() {
        print("🔍 Searching for all installed voices...")
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for v in voices {
            let desc = "Name: '\(v.name)' | ID: '\(v.identifier)' | Lang: '\(v.language)' | Gender: \(v.gender.rawValue) | Quality: \(v.quality.rawValue)"
            if v.language.contains("AU") || v.name.lowercased().contains("siri") || v.identifier.lowercased().contains("siri") || v.identifier.lowercased().contains("gordon") || v.identifier.lowercased().contains("lee") || v.name.lowercased().contains("lee") || v.name.lowercased().contains("russell") {
                print("⭐️ MATCH: \(desc)")
            }
        }

        print("\nAll English Voices:")
        for v in voices.filter({ $0.language.starts(with: "en") }) {
            print("  [\(v.language)] \(v.name) (ID: \(v.identifier), Gender: \(v.gender == .male ? "Male" : (v.gender == .female ? "Female" : "Unspecified")))")
        }
    }
}
