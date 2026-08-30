import Cocoa
import Carbon

@main
struct HotKeyTester {
    static func main() {
        print("Testing Carbon Global HotKey...")
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let status = InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            print("Global HotKey Pressed!")
            return noErr
        }, 1, &eventType, nil, nil)
        
        print("InstallEventHandler status:", status)
        
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x54534159), id: 1) // 'TSAY'
        
        // Register Option + Command + A (keyCode 0 is 'A')
        let regStatus = RegisterEventHotKey(UInt32(kVK_ANSI_A), UInt32(cmdKey | optionKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        print("RegisterEventHotKey status:", regStatus)
    }
}
