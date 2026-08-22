import Foundation

@main
struct VoiceSearch {
    static func main() {
        print("🔍 Searching for Siri voices on disk and in assets...")
        
        let searchDirs = [
            "/System/Library/AssetsV2",
            "/Library/Caches/com.apple.SpeechSynthesis",
            "/System/Library/Speech",
            "/Library/Speech",
            "/private/var/MobileAsset/AssetsV2",
            NSHomeDirectory() + "/Library/Speech",
            NSHomeDirectory() + "/Library/Caches/com.apple.SpeechSynthesis"
        ]
        
        for dir in searchDirs {
            findVoiceFiles(in: dir)
        }
        
        print("\n🔍 Checking available voices via osascript / system speech:")
        let pipe = Pipe()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", "tell application \"SpeechSynthesisServer\" to get the name of every voice"]
        proc.standardOutput = pipe
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let str = String(data: data, encoding: .utf8), !str.isEmpty {
            print("SpeechSynthesisServer voices: \(str.prefix(500))")
        }
    }
    
    static func findVoiceFiles(in path: String) {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else { return }
        var found: [String] = []
        while let file = enumerator.nextObject() as? String {
            if file.lowercased().contains("siri") || file.lowercased().contains("en_au") || file.lowercased().contains("en-au") {
                found.append("\(path)/\(file)")
                if found.count >= 20 { break }
            }
        }
        if !found.isEmpty {
            print("\nFound in \(path):")
            for f in found {
                print("  -> \(f)")
            }
        }
    }
}
