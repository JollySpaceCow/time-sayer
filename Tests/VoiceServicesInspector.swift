import Foundation

@main
struct VoiceServicesInspector {
    static func main() {
        print("Loading VoiceServices...")
        let vsHandle = dlopen("/System/Library/PrivateFrameworks/VoiceServices.framework/VoiceServices", RTLD_NOW)
        print("VoiceServices dlopen handle: \(String(describing: vsHandle))")
        
        let siriHandle = dlopen("/System/Library/PrivateFrameworks/SiriTTSService.framework/SiriTTSService", RTLD_NOW)
        print("SiriTTSService dlopen handle: \(String(describing: siriHandle))")
        
        if let vsClass = NSClassFromString("VSSpeechSynthesizer") as? NSObject.Type {
            print("Found VSSpeechSynthesizer class: \(vsClass)")
            let synth = vsClass.init()
            print("Initialized VSSpeechSynthesizer: \(synth)")
            
            if let availableVoicesMethod = NSClassFromString("VSVoiceAsset") {
                print("Found VSVoiceAsset: \(availableVoicesMethod)")
            }
        }
        
        if let siriClass = NSClassFromString("SiriTTSService.SiriTTSDaemon") as? NSObject.Type ?? NSClassFromString("SiriTTSDaemon") as? NSObject.Type {
            print("Found SiriTTS class: \(siriClass)")
        }
        
        // Let's test checking all classes containing Siri or VoiceServices in memory
        var count: UInt32 = 0
        if let classList = objc_copyClassList(&count) {
            var vsClasses: [String] = []
            for i in 0..<Int(count) {
                let name = String(cString: class_getName(classList[i]))
                if name.contains("VoiceServices") || name.contains("VSSpeech") || name.contains("SiriTTS") {
                    vsClasses.append(name)
                }
            }
            print("Matching classes count: \(vsClasses.count), sample: \(vsClasses.prefix(20))")
        }
    }
}
