import Foundation
import Cocoa

@main
struct VoiceServicesTester {
    static func main() {
        print("Testing VoiceServices framework...")
        
        let bundle = Bundle(path: "/System/Library/PrivateFrameworks/VoiceServices.framework")
        bundle?.load()
        
        if let synthClass = NSClassFromString("VSSpeechSynthesizer") as? NSObject.Type {
            let synth = synthClass.init()
            print("Successfully instantiated VSSpeechSynthesizer!")
            
            // Call startSpeakingString:toURL:withLanguageCode:andVoiceName:
            let sel = NSSelectorFromString("startSpeakingString:withLanguageCode:")
            if synth.responds(to: sel) {
                print("Responds to startSpeakingString:withLanguageCode:")
                synth.perform(sel, with: "Time Sayer: Testing VoiceServices with Australian English", with: "en-AU")
                Thread.sleep(forTimeInterval: 4.0)
            } else {
                print("Methods on VSSpeechSynthesizer:")
                var count: UInt32 = 0
                if let methods = class_copyMethodList(synthClass, &count) {
                    for i in 0..<Int(count) {
                        let selName = sel_getName(method_getName(methods[i]))
                        let nameStr = String(cString: selName)
                        if nameStr.contains("speak") || nameStr.contains("Voice") || nameStr.contains("start") {
                            print("  - \(nameStr)")
                        }
                    }
                }
            }
        }
    }
}
