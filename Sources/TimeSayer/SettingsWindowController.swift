import Cocoa
import ServiceManagement

/// Manages the Settings window (opened with ⌘,).
public final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    private let preferences = PreferencesManager.shared
    private var showInDockCheckbox: NSButton!
    private var showInMenuBarCheckbox: NSButton!
    private var openAtLoginCheckbox: NSButton!

    public static let shared = SettingsWindowController()

    private init() {
        // Build the window programmatically
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Time Sayer Settings"
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        buildContent()
    }

    required init?(coder: NSCoder) { fatalError("Not supported") }

    // MARK: - Build UI

    private var hintLabel: NSTextField!

    private func buildContent() {
        guard let contentView = window?.contentView else { return }

        // --- Title label ---
        let titleLabel = makeLabel("Behaviour", bold: true)
        titleLabel.frame = NSRect(x: 20, y: 175, width: 340, height: 20)
        contentView.addSubview(titleLabel)

        // --- Show in Dock ---
        showInDockCheckbox = NSButton(checkboxWithTitle: "Show in Dock", target: self, action: #selector(dockToggled))
        showInDockCheckbox.frame = NSRect(x: 20, y: 145, width: 340, height: 22)
        showInDockCheckbox.state = preferences.showInDock ? .on : .off
        showInDockCheckbox.toolTip = "Show Time Sayer as a regular Dock icon as well as in the menu bar"
        contentView.addSubview(showInDockCheckbox)

        // --- Show in Menu Bar ---
        showInMenuBarCheckbox = NSButton(checkboxWithTitle: "Show in Menu Bar", target: self, action: #selector(menuBarToggled))
        showInMenuBarCheckbox.frame = NSRect(x: 20, y: 115, width: 340, height: 22)
        showInMenuBarCheckbox.state = preferences.showInMenuBar ? .on : .off
        showInMenuBarCheckbox.toolTip = "Show the clock icon in the menu bar. Disable to run silently in the background."
        contentView.addSubview(showInMenuBarCheckbox)

        // --- Open at Login ---
        openAtLoginCheckbox = NSButton(checkboxWithTitle: "Open at Login", target: self, action: #selector(loginToggled))
        openAtLoginCheckbox.frame = NSRect(x: 20, y: 85, width: 340, height: 22)
        openAtLoginCheckbox.state = preferences.openAtLogin ? .on : .off
        openAtLoginCheckbox.toolTip = "Launch Time Sayer automatically when you log in"
        contentView.addSubview(openAtLoginCheckbox)

        // --- Separator line ---
        let separator = NSBox()
        separator.boxType = .separator
        separator.frame = NSRect(x: 20, y: 70, width: 340, height: 1)
        contentView.addSubview(separator)

        // --- Hint / Note label ---
        hintLabel = makeLabel("", bold: false)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.frame = NSRect(x: 20, y: 15, width: 340, height: 48)
        contentView.addSubview(hintLabel)

        updateHintText()
    }

    private func updateHintText() {
        if !preferences.showInDock && !preferences.showInMenuBar {
            hintLabel.stringValue = "💡 Tip: With both hidden, reopen Settings anytime by opening \"Time Sayer\" from Spotlight (⌘ Space) or Launchpad."
            hintLabel.textColor = .systemBlue
        } else {
            hintLabel.stringValue = "Changes take effect immediately."
            hintLabel.textColor = .secondaryLabelColor
        }
    }

    private func makeLabel(_ text: String, bold: Bool) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = bold ? .boldSystemFont(ofSize: 13) : .systemFont(ofSize: 13)
        return label
    }

    // MARK: - Actions

    @objc private func dockToggled() {
        preferences.showInDock = showInDockCheckbox.state == .on
        applyActivationPolicy()
        updateHintText()
    }

    @objc private func menuBarToggled() {
        preferences.showInMenuBar = showInMenuBarCheckbox.state == .on
        NotificationCenter.default.post(name: .timeSayerMenuBarVisibilityChanged, object: nil)
        updateHintText()
    }

    @objc private func loginToggled() {
        let enable = openAtLoginCheckbox.state == .on
        preferences.openAtLogin = enable
        applyLoginItem(enable: enable)
    }

    // MARK: - Helpers

    /// Switches between .accessory (no Dock) and .regular (Dock icon shown).
    public func applyActivationPolicy() {
        if preferences.showInDock {
            NSApplication.shared.setActivationPolicy(.regular)
        } else {
            NSApplication.shared.setActivationPolicy(.accessory)
            // When switching back to accessory, bring settings window back to front if open
            if window?.isVisible == true {
                NSApplication.shared.activate(ignoringOtherApps: true)
                window?.makeKeyAndOrderFront(nil)
            }
        }
    }

    /// Registers or removes the app from the Login Items using ServiceManagement.
    public func applyLoginItem(enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Time Sayer: Could not \(enable ? "register" : "unregister") login item: \(error)")
            }
        }
    }

    // MARK: - Show

    public func showSettings() {
        // Refresh checkbox states in case they changed elsewhere
        showInDockCheckbox.state = preferences.showInDock ? .on : .off
        showInMenuBarCheckbox.state = preferences.showInMenuBar ? .on : .off
        openAtLoginCheckbox.state = preferences.openAtLogin ? .on : .off

        // Temporarily use .regular policy so the window can become key
        if !preferences.showInDock {
            NSApplication.shared.setActivationPolicy(.regular)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    public func windowWillClose(_ notification: Notification) {
        // Return to accessory policy if Dock is hidden
        applyActivationPolicy()
    }
}

extension Notification.Name {
    static let timeSayerMenuBarVisibilityChanged = Notification.Name("timeSayerMenuBarVisibilityChanged")
}
