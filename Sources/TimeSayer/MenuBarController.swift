import Cocoa
import AVFoundation

/// Manages the macOS menu bar status item and its interactive menu.
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

        // Observe menu bar visibility changes from the Settings window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuBarVisibilityChanged),
            name: .timeSayerMenuBarVisibilityChanged,
            object: nil
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = preferences.showInMenuBar
        if let button = statusItem.button {
            updateStatusIcon()
            button.toolTip = "Time Sayer — Menu Bar Time Announcer"
        }
        statusItem.menu = menu
    }

    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }

        let symbolName = preferences.isEnabled ? "clock.badge.waveform" : "clock.badge.xmark"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Time Sayer") {
            image.isTemplate = true
            button.image = image
        } else {
            // Fallback for systems where specific SF symbol may not be present
            let fallbackImage = NSImage(systemSymbolName: "clock", accessibilityDescription: "Time Sayer")
            fallbackImage?.isTemplate = true
            button.image = fallbackImage
        }
    }

    public func menuWillOpen(_ menu: NSMenu) {
        buildMenu()
    }

    /// Constructs the menu dynamically to reflect up-to-date state.
    public func buildMenu() {
        menu.removeAllItems()

        // Status Header Item
        let statusTitle: String
        if preferences.isEnabled {
            statusTitle = "Time Sayer: Active (\(preferences.interval.shortTitle))"
        } else {
            statusTitle = "Time Sayer: Paused"
        }
        let headerItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // Next announcement time preview
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

        // Quick Action: Announce Time Now
        let announceNowItem = NSMenuItem(
            title: "Announce Time Now",
            action: #selector(announceNowClicked),
            keyEquivalent: "a"
        )
        announceNowItem.target = self
        menu.addItem(announceNowItem)

        menu.addItem(NSMenuItem.separator())

        // Active Toggle
        let enableToggleItem = NSMenuItem(
            title: "Enable Time Announcements",
            action: #selector(toggleEnableClicked),
            keyEquivalent: ""
        )
        enableToggleItem.target = self
        enableToggleItem.state = preferences.isEnabled ? .on : .off
        menu.addItem(enableToggleItem)

        // Interval Submenu
        let intervalMenuItem = NSMenuItem(title: "Frequency Interval", action: nil, keyEquivalent: "")
        let intervalSubmenu = NSMenu(title: "Frequency Interval")
        for interval in AnnouncementInterval.allCases {
            let item = NSMenuItem(
                title: interval.title,
                action: #selector(intervalSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = interval
            item.state = (preferences.interval == interval) ? .on : .off
            intervalSubmenu.addItem(item)
        }
        intervalMenuItem.submenu = intervalSubmenu
        menu.addItem(intervalMenuItem)

        // Announcement Style Submenu
        let styleMenuItem = NSMenuItem(title: "Announcement Phrasing", action: nil, keyEquivalent: "")
        let styleSubmenu = NSMenu(title: "Announcement Phrasing")
        for style in AnnouncementStyle.allCases {
            let item = NSMenuItem(
                title: style.title,
                action: #selector(styleSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = style
            item.state = (preferences.announcementStyle == style) ? .on : .off
            styleSubmenu.addItem(item)
        }
        styleMenuItem.submenu = styleSubmenu
        menu.addItem(styleMenuItem)

        // Time Format (12h vs 24h) Submenu
        let formatMenuItem = NSMenuItem(title: "Time Format (12h / 24h)", action: nil, keyEquivalent: "")
        let formatSubmenu = NSMenu(title: "Time Format")
        for format in TimeFormatSetting.allCases {
            let currentDetail = format == .system ? (PreferencesManager.isSystem24HourFormat() ? " [System: 24h]" : " [System: 12h]") : ""
            let item = NSMenuItem(
                title: "\(format.title)\(currentDetail)",
                action: #selector(formatSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = format
            item.state = (preferences.timeFormat == format) ? .on : .off
            formatSubmenu.addItem(item)
        }
        formatMenuItem.submenu = formatSubmenu
        menu.addItem(formatMenuItem)

        // Voices Submenu
        let voiceMenuItem = NSMenuItem(title: "System Voice", action: nil, keyEquivalent: "")
        voiceMenuItem.submenu = createVoiceSubmenu()
        menu.addItem(voiceMenuItem)

        // Volume Submenu
        let volumeMenuItem = NSMenuItem(title: "Volume", action: nil, keyEquivalent: "")
        volumeMenuItem.submenu = createVolumeSubmenu()
        menu.addItem(volumeMenuItem)

        // Speech Rate Submenu
        let rateMenuItem = NSMenuItem(title: "Speech Speed", action: nil, keyEquivalent: "")
        rateMenuItem.submenu = createRateSubmenu()
        menu.addItem(rateMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(settingsClicked),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // About / Information
        let aboutItem = NSMenuItem(title: "About Time Sayer", action: #selector(aboutClicked), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // Quit Item
        let quitItem = NSMenuItem(
            title: "Quit Time Sayer",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func createVoiceSubmenu() -> NSMenu {
        let voiceMenu = NSMenu(title: "System Voice")
        let currentVoice = preferences.voiceIdentifier

        // Siri Australian Male System Voice Option
        let siriMaleItem = NSMenuItem(
            title: "Siri Australian Male (System Voice) ★",
            action: #selector(voiceSelected(_:)),
            keyEquivalent: ""
        )
        siriMaleItem.target = self
        siriMaleItem.representedObject = "siri_male"
        siriMaleItem.state = (currentVoice == "siri_male" || currentVoice == "system" || currentVoice == "Gordon") ? .on : .off
        voiceMenu.addItem(siriMaleItem)

        voiceMenu.addItem(NSMenuItem.separator())

        // Standard System Voices Section
        let standardHeader = NSMenuItem(title: "— Other System Voices —", action: nil, keyEquivalent: "")
        standardHeader.isEnabled = false
        voiceMenu.addItem(standardHeader)

        // Karen (Standard Australian)
        let karenItem = NSMenuItem(
            title: "Karen (Standard Australian English)",
            action: #selector(voiceSelected(_:)),
            keyEquivalent: ""
        )
        karenItem.target = self
        karenItem.representedObject = "Karen"
        karenItem.state = (currentVoice == "Karen") ? .on : .off
        voiceMenu.addItem(karenItem)

        let allVoices = announcer.availableVoices()
        let englishVoices = allVoices.filter { $0.language.lowercased().hasPrefix("en") && !$0.name.contains("Karen") }
        let otherVoices = allVoices.filter { !$0.language.lowercased().hasPrefix("en") }

        for voice in englishVoices {
            let localeName = Locale.current.localizedString(forIdentifier: voice.language) ?? voice.language
            let item = NSMenuItem(
                title: "\(voice.name) (\(localeName))",
                action: #selector(voiceSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = voice.identifier
            item.state = (currentVoice == voice.identifier) ? .on : .off
            voiceMenu.addItem(item)
        }

        if !otherVoices.isEmpty {
            voiceMenu.addItem(NSMenuItem.separator())
            let otherMenuItem = NSMenuItem(title: "Other Languages", action: nil, keyEquivalent: "")
            let otherSubmenu = NSMenu(title: "Other Languages")

            for voice in otherVoices {
                let localeName = Locale.current.localizedString(forIdentifier: voice.language) ?? voice.language
                let item = NSMenuItem(
                    title: "\(voice.name) (\(localeName))",
                    action: #selector(voiceSelected(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = voice.identifier
                item.state = (currentVoice == voice.identifier) ? .on : .off
                otherSubmenu.addItem(item)
            }
            otherMenuItem.submenu = otherSubmenu
            voiceMenu.addItem(otherMenuItem)
        }

        return voiceMenu
    }

    private func createVolumeSubmenu() -> NSMenu {
        let volumeMenu = NSMenu(title: "Volume")
        let levels: [(String, Float)] = [
            ("100%", 1.0),
            ("75%", 0.75),
            ("50%", 0.50),
            ("25%", 0.25)
        ]

        for (label, value) in levels {
            let item = NSMenuItem(
                title: label,
                action: #selector(volumeSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = value
            item.state = (abs(preferences.speechVolume - value) < 0.05) ? .on : .off
            volumeMenu.addItem(item)
        }
        return volumeMenu
    }

    private func createRateSubmenu() -> NSMenu {
        let rateMenu = NSMenu(title: "Speech Speed")
        let rates: [(String, Float)] = [
            ("Slower (0.4x)", AVSpeechUtteranceDefaultSpeechRate * 0.8),
            ("Normal (Default)", AVSpeechUtteranceDefaultSpeechRate),
            ("Faster (1.2x)", AVSpeechUtteranceDefaultSpeechRate * 1.2),
            ("Very Fast (1.4x)", AVSpeechUtteranceDefaultSpeechRate * 1.4)
        ]

        for (label, value) in rates {
            let item = NSMenuItem(
                title: label,
                action: #selector(rateSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = value
            item.state = (abs(preferences.speechRate - value) < 0.03) ? .on : .off
            rateMenu.addItem(item)
        }
        return rateMenu
    }

    // MARK: - Action Handlers

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
    }

    @objc private func intervalSelected(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? AnnouncementInterval else { return }
        preferences.interval = interval
        announcer.reschedule()
        buildMenu()
    }

    @objc private func styleSelected(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? AnnouncementStyle else { return }
        preferences.announcementStyle = style
        buildMenu()
    }

    @objc private func formatSelected(_ sender: NSMenuItem) {
        guard let format = sender.representedObject as? TimeFormatSetting else { return }
        preferences.timeFormat = format
        buildMenu()
    }

    @objc private func voiceSelected(_ sender: NSMenuItem) {
        let voiceId = (sender.representedObject as? String) ?? "system"
        preferences.voiceIdentifier = voiceId
        buildMenu()
        // Preview sample speech with chosen voice
        announcer.speak(text: "Time Sayer voice selected.")
    }

    @objc private func volumeSelected(_ sender: NSMenuItem) {
        guard let volume = sender.representedObject as? Float else { return }
        preferences.speechVolume = volume
        buildMenu()
    }

    @objc private func rateSelected(_ sender: NSMenuItem) {
        guard let rate = sender.representedObject as? Float else { return }
        preferences.speechRate = rate
        buildMenu()
    }

    @objc private func settingsClicked() {
        SettingsWindowController.shared.showSettings()
    }

    @objc private func menuBarVisibilityChanged() {
        statusItem.isVisible = preferences.showInMenuBar
    }

    @objc private func aboutClicked() {
        let alert = NSAlert()
        alert.messageText = "Time Sayer"
        alert.informativeText = "A lightweight macOS menu bar application that announces the time at your chosen interval using the macOS system voice.\n\nCreated with native Swift & AppKit."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}
