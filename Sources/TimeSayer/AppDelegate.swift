import Cocoa

/// Main application delegate coordinating startup and lifecycle.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply user preference for Dock icon visibility (.accessory vs .regular)
        SettingsWindowController.shared.applyActivationPolicy()

        // Initialise the menu bar interface
        menuBarController = MenuBarController()

        // Start high-precision scheduling for announcements
        TimeAnnouncer.shared.startScheduling()
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowController.shared.showSettings()
        return true
    }

    public func applicationWillTerminate(_ notification: Notification) {
        TimeAnnouncer.shared.cancelScheduling()
    }
}
