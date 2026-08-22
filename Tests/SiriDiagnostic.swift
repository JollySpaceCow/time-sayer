import Cocoa
import AVFoundation

@main
struct SiriVoiceDiagnostic {
    static func main() {
        print("🔍 Checking NSSpeechSynthesizer available voices:")
        for voiceId in NSSpeechSynthesizer.availableVoices {
            let attrs = NSSpeechSynthesizer.attributes(forVoice: voiceId)
            let name = attrs[.name] as? String ?? ""
            let locale = attrs[.localeIdentifier] as? String ?? ""
            let gender = attrs[.gender] as? String ?? ""
            if locale.contains("AU") || name.lowercased().contains("siri") || name.lowercased().contains("lee") || name.lowercased().contains("gordon") {
                print("  Voice: \(voiceId) -> Name: '\(name)', Locale: '\(locale)', Gender: '\(gender)'")
            }
        }

        print("\n🔍 Checking available voices in directories:")
        let paths = [
            "/System/Library/Speech/Voices",
            "/Library/Speech/Voices",
            NSHomeDirectory() + "/Library/Speech/Voices"
        ]
        for p in paths {
            if let items = try? FileManager.default.contentsOfDirectory(atPath: p) {
                print("Directory \(p): \(items)")
            }
        }
        
        print("\n🔍 Checking Siri system preferences:")
        let siriVoice = UserDefaults(suiteName: "com.apple.assistant.backedup")?.dictionaryRepresentation()
        print("Siri backedup keys count: \(siriVoice?.count ?? 0)")
    }
}
