import Cocoa

@main
struct MenuBarDiagnostic {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("Status item created:", statusItem)
        
        guard let button = statusItem.button else {
            print("ERROR: statusItem.button is NIL!")
            return
        }
        
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        if let img = NSImage(systemSymbolName: "clock", accessibilityDescription: "Time Sayer")?.withSymbolConfiguration(config) {
            img.isTemplate = true
            button.image = img
            print("Successfully assigned clock image:", img.size)
        } else {
            print("ERROR: could not create clock image")
        }
        
        button.toolTip = "Time Sayer Diagnostic"
        print("Button frame:", button.frame)
    }
}
