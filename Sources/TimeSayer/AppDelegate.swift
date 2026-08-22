import Cocoa

/// Main application delegate coordinating startup and lifecycle.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure accessory activation policy so no Dock icon is shown
        NSApplication.shared.setActivationPolicy(.accessory)

        // Initialise the menu bar interface
        menuBarController = MenuBarController()

        // Start scheduling announcements
        TimeAnnouncer.shared.startScheduling()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        TimeAnnouncer.shared.cancelScheduling()
    }
}
