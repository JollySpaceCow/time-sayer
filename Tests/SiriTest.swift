import Foundation

@main
struct SiriTest {
    static func main() {
        print("Testing speaking with Gordon via Process...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-v", "Gordon", "Time Sayer: It is currently half past twelve."]
        do {
            try process.run()
            process.waitUntilExit()
            print("Process finished with code \(process.terminationStatus)")
        } catch {
            print("Error: \(error)")
        }
    }
}
