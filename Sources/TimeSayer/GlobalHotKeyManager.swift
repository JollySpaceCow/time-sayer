import Cocoa
import Carbon

/// Manages system-wide global hotkeys using the Carbon Event Manager.
/// This allows triggering time announcements from anywhere in macOS without requiring Accessibility permissions.
public final class GlobalHotKeyManager {
    public static let shared = GlobalHotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var isRegistered = false

    private init() {}

    /// Registers the global shortcut ⌥⌘A (Option + Command + A).
    public func setup() {
        guard !isRegistered else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { (_, theEvent, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            if status == noErr && hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    TimeAnnouncer.shared.announceCurrentTime()
                }
            }
            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, nil)

        // HotKey: ⌥⌘A (Option + Command + A)
        let hotKeyID = EventHotKeyID(signature: OSType(0x54534159), id: 1) // 'TSAY'
        let regStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_A),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if regStatus == noErr {
            isRegistered = true
        } else {
            print("Time Sayer: Failed to register global hotkey (status: \(regStatus))")
        }
    }
}
