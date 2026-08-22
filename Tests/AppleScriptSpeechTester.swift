import Foundation
import Cocoa

@main
struct AppleScriptSpeechTester {
    static func main() {
        print("Testing AppleScript speech...")
        let text = "It's 13 36 hours. This is your Siri Australian Male voice announcing the time."
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
        process.arguments = ["-e", "say \"\(escaped)\""]
        
        do {
            try process.run()
            process.waitUntilExit()
            print("AppleScript speech exited with code \(process.terminationStatus)")
        } catch {
            print("Error: \(error)")
        }
    }
}
