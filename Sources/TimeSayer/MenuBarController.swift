import Cocoa
import AVFoundation

/// Manages the streamlined macOS menu bar status item and its clean menu.
public final class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let preferences = PreferencesManager.shared
    private let announcer = TimeAnnouncer.shared

    private let menu = NSMenu()

    public override init() {
        super.init()
        setupStatusItem()
        buildMenu()
        menu.delegate = self

        // Observe menu bar visibility changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuBarVisibilityChanged),
            name: .timeSayerMenuBarVisibilityChanged,
            object: nil
        )

        // Observe general preference changes (e.g. from Settings window)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: .timeSayerPreferencesChanged,
            object: nil
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            updateStatusIcon()
            button.toolTip = "Time Sayer — Menu Bar Time Announcer"
        }
        statusItem.menu = menu
        statusItem.isVisible = preferences.showInMenuBar
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let symbolName = preferences.isEnabled ? "clock" : "clock.badge.xmark"
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Time Sayer")?.withSymbolConfiguration(config) {
            image.isTemplate = true
            button.image = image
        } else if let fallback = NSImage(systemSymbolName: "clock", accessibilityDescription: "Time Sayer")?.withSymbolConfiguration(config) {
            fallback.isTemplate = true
            button.image = fallback
        }
    }

    public func menuWillOpen(_ menu: NSMenu) {
        buildMenu()
    }

    /// Constructs the clean, streamlined menu.
    public func buildMenu() {
        menu.removeAllItems()

        // 1. Status Header
        let statusTitle: String
        if preferences.isEnabled {
            statusTitle = "Time Sayer: Active (\(preferences.interval.shortTitle))"
        } else {
            statusTitle = "Time Sayer: Paused"
        }
        let headerItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // 2. Next announcement time preview
        if preferences.isEnabled,
           let nextDate = announcer.calculateNextBoundaryDate(from: Date(), interval: preferences.interval) {
            let formatter = DateFormatter()
            if preferences.is24HourEffective {
                formatter.dateFormat = "HH:mm:ss"
            } else {
                formatter.dateFormat = "h:mm:ss a"
            }
            let nextString = formatter.string(from: nextDate)
            let nextItem = NSMenuItem(title: "Next announcement: \(nextString)", action: nil, keyEquivalent: "")
            nextItem.isEnabled = false
            menu.addItem(nextItem)
        }

        menu.addItem(NSMenuItem.separator())

        // 3. Quick Action: Announce Time Now (⌥⌘A)
        let announceNowItem = NSMenuItem(
            title: "Announce Time Now",
            action: #selector(announceNowClicked),
            keyEquivalent: "a"
        )
        announceNowItem.keyEquivalentModifierMask = [.command, .option]
        announceNowItem.target = self
        menu.addItem(announceNowItem)

        // 4. Quick Action: Pause / Resume Toggle
        let toggleTitle = preferences.isEnabled ? "Pause Announcements" : "Resume Announcements"
        let toggleItem = NSMenuItem(
            title: toggleTitle,
            action: #selector(toggleEnableClicked),
            keyEquivalent: "p"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Open Settings Window (⌘,)
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(settingsClicked),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 6. About
        let aboutItem = NSMenuItem(
            title: "About Time Sayer",
            action: #selector(aboutClicked),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // 7. Quit (⌘Q)
        let quitItem = NSMenuItem(
            title: "Quit Time Sayer",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func announceNowClicked() {
        announcer.announceCurrentTime()
    }

    @objc private func toggleEnableClicked() {
        preferences.isEnabled.toggle()
        updateStatusIcon()
        if preferences.isEnabled {
            announcer.startScheduling()
        } else {
            announcer.cancelScheduling()
        }
        buildMenu()
        NotificationCenter.default.post(name: .timeSayerPreferencesChanged, object: nil)
    }

    @objc private func settingsClicked() {
        SettingsWindowController.shared.showSettings()
    }

    @objc private func menuBarVisibilityChanged() {
        statusItem.isVisible = preferences.showInMenuBar
    }

    @objc private func preferencesChanged() {
        updateStatusIcon()
        buildMenu()
    }

    @objc private func aboutClicked() {
        let alert = NSAlert()
        alert.messageText = "Time Sayer"
        alert.informativeText = "A lightweight macOS menu bar application that announces the time at your chosen interval using the Siri Australian Male system voice.\n\nVersion 1.1.0\nCreated with native Swift & AppKit."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}
