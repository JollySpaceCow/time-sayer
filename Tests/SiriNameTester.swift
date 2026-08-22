import Foundation

@main
struct SiriNameTester {
    static func main() {
        let candidates = [
            "Siri",
            "Siri Voice 1",
            "Siri Voice 2",
            "Siri (Voice 1)",
            "Siri (Voice 2)",
            "Siri (Australia)",
            "Siri (Australia (Voice 2))",
            "Siri (English (Australia))",
            "Siri (en-AU)",
            "Siri Voice 2 (en-AU)",
            "Voice 2",
            "Voice 1",
            "Australian (Voice 2)",
            "English (Australia)",
            "en-AU"
        ]

        for name in candidates {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/say")
            p.arguments = ["-v", name, "test"]
            let errPipe = Pipe()
            p.standardError = errPipe
            try? p.run()
            p.waitUntilExit()
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if p.terminationStatus == 0 && !err.contains("Voice") {
                print("✅ ACCEPTED by say: '\(name)' (exit code: \(p.terminationStatus))")
            } else {
                print("❌ REJECTED by say: '\(name)': \(err.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
        }
    }
}
