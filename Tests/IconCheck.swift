import Cocoa

@main
struct IconCheck {
    static func main() {
        print("Testing SF Symbols...")
        let img1 = NSImage(systemSymbolName: "clock.badge.waveform", accessibilityDescription: nil)
        print("clock.badge.waveform:", img1 != nil ? "Valid size \(img1!.size)" : "NIL")

        let img2 = NSImage(systemSymbolName: "clock", accessibilityDescription: nil)
        print("clock:", img2 != nil ? "Valid size \(img2!.size)" : "NIL")

        let defaults = UserDefaults.standard
        print("UserDefaults showInMenuBar:", defaults.object(forKey: "TimeSayer_showInMenuBar") ?? "nil (default true)")
        print("UserDefaults showInDock:", defaults.object(forKey: "TimeSayer_showInDock") ?? "nil (default false)")
        print("UserDefaults isEnabled:", defaults.object(forKey: "TimeSayer_isEnabled") ?? "nil")
    }
}
