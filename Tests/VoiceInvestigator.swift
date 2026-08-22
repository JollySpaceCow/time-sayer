import Foundation

@main
struct VoiceInvestigator {
    static func main() {
        print("Investigating Siri TTS...")
        
        // Check TTS assets in MobileAsset
        let assetPaths = [
            "/System/Library/TTS/Voices",
            "/System/Library/PrivateFrameworks/VoiceServices.framework",
            "/System/Library/PrivateFrameworks/SiriTTSService.framework",
            "/private/var/MobileAsset/AssetsV2/com_apple_MobileAsset_VoiceServices_CustomVoice",
            "/private/var/MobileAsset/AssetsV2/com_apple_MobileAsset_VoiceServices_GryphonVoice",
            "/System/Library/AssetsV2/com_apple_MobileAsset_VoiceServices_CustomVoice",
            "/System/Library/AssetsV2/com_apple_MobileAsset_VoiceServices_GryphonVoice"
        ]
        
        for path in assetPaths {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
                print("Exists: \(path) (isDir: \(isDir.boolValue))")
                if isDir.boolValue, let items = try? FileManager.default.contentsOfDirectory(atPath: path) {
                    print("  Contents: \(items.prefix(10))")
                }
            }
        }
    }
}
