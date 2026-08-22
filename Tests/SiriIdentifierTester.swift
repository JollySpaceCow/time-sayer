import Foundation
import AVFoundation

@main
struct SiriIdentifierTester {
    static func main() {
        let testIds = [
            "com.apple.ttsbundle.siri_Gordon_en-AU_compact",
            "com.apple.ttsbundle.siri_Gordon_en-AU_premium",
            "com.apple.voice.compact.en-AU.Gordon",
            "com.apple.voice.premium.en-AU.Gordon",
            "com.apple.ttsbundle.siri_male_en-AU_compact",
            "com.apple.ttsbundle.siri_male_en-AU_premium",
            "com.apple.ttsbundle.siri_Lee_en-AU_compact",
            "com.apple.ttsbundle.siri_Lee_en-AU_premium",
            "com.apple.ttsbundle.siri_en-AU_male",
            "com.apple.ttsbundle.siri_en-AU_female",
            "com.apple.ttsbundle.siri_male_en-AU",
            "com.apple.ttsbundle.siri_female_en-AU",
            "com.apple.voice.compact.en-AU.Lee",
            "com.apple.voice.premium.en-AU.Lee",
            "com.apple.speech.synthesis.voice.Gordon",
            "com.apple.speech.synthesis.voice.Lee"
        ]

        print("Testing AVSpeechSynthesisVoice identifiers:")
        for id in testIds {
            if let voice = AVSpeechSynthesisVoice(identifier: id) {
                print("  ✅ VALID: id=\(id) -> name=\(voice.name), lang=\(voice.language), gender=\(voice.gender.rawValue), quality=\(voice.quality.rawValue)")
            } else {
                print("  ❌ nil: id=\(id)")
            }
        }
    }
}
