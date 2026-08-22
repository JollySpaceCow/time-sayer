import Foundation
import Cocoa

@main
struct VSHelper {
    static func main() {
        let handle = dlopen("/System/Library/PrivateFrameworks/VoiceServices.framework/VoiceServices", RTLD_GLOBAL | RTLD_NOW)
        print("dlopen: \(String(describing: handle))")
        
        let targetClasses = ["VSSpeechSynthesizer", "VSSpeechRequest", "VSVoiceAsset", "VSSpeechConnection"]
        for cName in targetClasses {
            if let cls = NSClassFromString(cName) {
                print("\nClass: \(cName)")
                var count: UInt32 = 0
                if let mList = class_copyMethodList(cls, &count) {
                    for i in 0..<Int(count) {
                        let name = String(cString: sel_getName(method_getName(mList[i])))
                        if !name.hasPrefix("_") {
                            print("  method: \(name)")
                        }
                    }
                }
            }
        }
    }
}
