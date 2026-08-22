import Foundation

@main
struct VoiceAssetFinder {
    static func main() {
        print("Searching for voice files on disk...")
        let commands = [
            "find /System/Library/TTS /Library/Speech /System/Library/Speech ~/Library/Speech -maxdepth 4 2>/dev/null",
            "find /private/var/MobileAsset/AssetsV2 -name \"*.asset\" 2>/dev/null",
            "defaults read com.apple.speech.voice.prefs",
            "defaults read com.apple.Accessibility"
        ]
        
        for cmd in commands {
            print("\n--- Command: \(cmd) ---")
            let pipe = Pipe()
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/bin/sh")
            p.arguments = ["-c", cmd]
            p.standardOutput = pipe
            try? p.run()
            p.waitUntilExit()
            let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            print(out.prefix(1500))
        }
    }
}
