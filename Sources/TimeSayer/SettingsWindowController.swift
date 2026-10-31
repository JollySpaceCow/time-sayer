import Cocoa
import ServiceManagement
import AVFoundation

/// Unified Settings Window Controller (accessible via ⌘, or Menu Bar).
public final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    public static let shared = SettingsWindowController()

    private let preferences = PreferencesManager.shared
    private let announcer = TimeAnnouncer.shared

    // Announcements Controls
    private var enableCheckbox: NSButton!
    private var intervalPopUp: NSPopUpButton!
    private var formatSegmented: NSSegmentedControl!
    private var styleSegmented: NSSegmentedControl!

    // Voice Controls
    private var voicePopUp: NSPopUpButton!
    private var speedPopUp: NSPopUpButton!
    private var volumeSlider: NSSlider!
    private var volumeLabel: NSTextField!
    private var testVoiceButton: NSButton!

    // Behaviour Controls
    private var showInDockCheckbox: NSButton!
    private var showInMenuBarCheckbox: NSButton!
    private var openAtLoginCheckbox: NSButton!
    private var hintLabel: NSTextField!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 530),
            styleMask: [.titled, .closable, .miniaturizable],
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

    // MARK: - Layout Construction

    private func buildContent() {
        guard let contentView = window?.contentView else { return }
        contentView.subviews.forEach { $0.removeFromSuperview() }

        var y: CGFloat = 490

        // ==========================================
        // 1. SECTION: ANNOUNCEMENTS
        // ==========================================
        let announcementsTitle = makeSectionHeader("Announcements")
        announcementsTitle.frame = NSRect(x: 20, y: y, width: 440, height: 20)
        contentView.addSubview(announcementsTitle)
        y -= 30

        // Enable Announcements Checkbox
        enableCheckbox = NSButton(checkboxWithTitle: "Enable Time Announcements", target: self, action: #selector(enableToggled))
        enableCheckbox.frame = NSRect(x: 24, y: y, width: 430, height: 22)
        enableCheckbox.state = preferences.isEnabled ? .on : .off
        enableCheckbox.font = .systemFont(ofSize: 13, weight: .medium)
        contentView.addSubview(enableCheckbox)
        y -= 34

        // Frequency Interval
        let freqLabel = makeFieldLabel("Frequency:")
        freqLabel.frame = NSRect(x: 24, y: y, width: 110, height: 20)
        contentView.addSubview(freqLabel)

        intervalPopUp = NSPopUpButton(frame: NSRect(x: 140, y: y - 3, width: 240, height: 26), pullsDown: false)
        for interval in AnnouncementInterval.allCases {
            intervalPopUp.addItem(withTitle: interval.title)
            intervalPopUp.lastItem?.representedObject = interval
        }
        selectCurrentInterval()
        intervalPopUp.target = self
        intervalPopUp.action = #selector(intervalChanged)
        contentView.addSubview(intervalPopUp)
        y -= 34

        // Time Format
        let formatLabel = makeFieldLabel("Time Format:")
        formatLabel.frame = NSRect(x: 24, y: y, width: 110, height: 20)
        contentView.addSubview(formatLabel)

        let sysDetail = PreferencesManager.isSystem24HourFormat() ? "24h" : "12h"
        formatSegmented = NSSegmentedControl(
            labels: ["Auto (\(sysDetail))", "12-Hour", "24-Hour"],
            trackingMode: .selectOne,
            target: self,
            action: #selector(formatChanged)
        )
        formatSegmented.frame = NSRect(x: 140, y: y - 2, width: 310, height: 24)
        selectCurrentFormat()
        contentView.addSubview(formatSegmented)
        y -= 34

        // Phrasing Style
        let styleLabel = makeFieldLabel("Phrasing:")
        styleLabel.frame = NSRect(x: 24, y: y, width: 110, height: 20)
        contentView.addSubview(styleLabel)

        styleSegmented = NSSegmentedControl(
            labels: ["Conversational", "Concise", "Natural Spoken"],
            trackingMode: .selectOne,
            target: self,
            action: #selector(styleChanged)
        )
        styleSegmented.frame = NSRect(x: 140, y: y - 2, width: 310, height: 24)
        selectCurrentStyle()
        contentView.addSubview(styleSegmented)
        y -= 25

        // Separator 1
        contentView.addSubview(makeSeparator(y: y))
        y -= 20

        // ==========================================
        // 2. SECTION: VOICE & AUDIO
        // ==========================================
        let voiceTitle = makeSectionHeader("Voice & Audio")
        voiceTitle.frame = NSRect(x: 20, y: y, width: 440, height: 20)
        contentView.addSubview(voiceTitle)
        y -= 30

        // Voice Picker
        let voiceLabel = makeFieldLabel("Voice:")
        voiceLabel.frame = NSRect(x: 24, y: y, width: 110, height: 20)
        contentView.addSubview(voiceLabel)

        voicePopUp = NSPopUpButton(frame: NSRect(x: 140, y: y - 3, width: 230, height: 26), pullsDown: false)
        populateVoices()
        voicePopUp.target = self
        voicePopUp.action = #selector(voiceChanged)
        contentView.addSubview(voicePopUp)

        // Test Voice Button
        testVoiceButton = NSButton(title: "Play Sample", target: self, action: #selector(testVoiceClicked))
        testVoiceButton.bezelStyle = .rounded
        testVoiceButton.frame = NSRect(x: 375, y: y - 4, width: 85, height: 26)
        contentView.addSubview(testVoiceButton)
        y -= 34

        // Speech Speed
        let speedLabel = makeFieldLabel("Speech Speed:")
        speedLabel.frame = NSRect(x: 24, y: y, width: 110, height: 20)
        contentView.addSubview(speedLabel)

        speedPopUp = NSPopUpButton(frame: NSRect(x: 140, y: y - 3, width: 230, height: 26), pullsDown: false)
        let speeds: [(String, Float)] = [
            ("Slower (0.8x)", AVSpeechUtteranceDefaultSpeechRate * 0.8),
            ("Normal (Default)", AVSpeechUtteranceDefaultSpeechRate),
            ("Faster (1.2x)", AVSpeechUtteranceDefaultSpeechRate * 1.2),
            ("Very Fast (1.4x)", AVSpeechUtteranceDefaultSpeechRate * 1.4)
        ]
        for (name, val) in speeds {
            speedPopUp.addItem(withTitle: name)
            speedPopUp.lastItem?.representedObject = val
        }
        selectCurrentSpeed()
        speedPopUp.target = self
        speedPopUp.action = #selector(speedChanged)
        contentView.addSubview(speedPopUp)
        y -= 34

        // Volume
        let volLabel = makeFieldLabel("Volume:")
        volLabel.frame = NSRect(x: 24, y: y, width: 110, height: 20)
        contentView.addSubview(volLabel)

        volumeSlider = NSSlider(value: Double(preferences.speechVolume), minValue: 0.1, maxValue: 1.0, target: self, action: #selector(volumeChanged))
        volumeSlider.isContinuous = true
        volumeSlider.frame = NSRect(x: 140, y: y, width: 250, height: 20)
        contentView.addSubview(volumeSlider)

        volumeLabel = makeFieldLabel("\(Int(preferences.speechVolume * 100))%")
        volumeLabel.frame = NSRect(x: 395, y: y, width: 50, height: 20)
        volumeLabel.alignment = .right
        contentView.addSubview(volumeLabel)
        y -= 25

        // Separator 2
        contentView.addSubview(makeSeparator(y: y))
        y -= 20

        // ==========================================
        // 3. SECTION: BEHAVIOUR
        // ==========================================
        let behaviourTitle = makeSectionHeader("Behaviour & Visibility")
        behaviourTitle.frame = NSRect(x: 20, y: y, width: 440, height: 20)
        contentView.addSubview(behaviourTitle)
        y -= 28

        // Checkboxes
        showInMenuBarCheckbox = NSButton(checkboxWithTitle: "Show in Menu Bar", target: self, action: #selector(menuBarToggled))
        showInMenuBarCheckbox.frame = NSRect(x: 24, y: y, width: 430, height: 22)
        showInMenuBarCheckbox.state = preferences.showInMenuBar ? .on : .off
        contentView.addSubview(showInMenuBarCheckbox)
        y -= 26

        showInDockCheckbox = NSButton(checkboxWithTitle: "Show in Dock", target: self, action: #selector(dockToggled))
        showInDockCheckbox.frame = NSRect(x: 24, y: y, width: 430, height: 22)
        showInDockCheckbox.state = preferences.showInDock ? .on : .off
        contentView.addSubview(showInDockCheckbox)
        y -= 26

        openAtLoginCheckbox = NSButton(checkboxWithTitle: "Open automatically at Login", target: self, action: #selector(loginToggled))
        openAtLoginCheckbox.frame = NSRect(x: 24, y: y, width: 430, height: 22)
        openAtLoginCheckbox.state = preferences.openAtLogin ? .on : .off
        contentView.addSubview(openAtLoginCheckbox)
        y -= 38

        // Hint Label
        hintLabel = NSTextField(wrappingLabelWithString: "")
        hintLabel.isEditable = false
        hintLabel.isBordered = false
        hintLabel.backgroundColor = .clear
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.frame = NSRect(x: 24, y: 15, width: 430, height: 35)
        contentView.addSubview(hintLabel)

        updateHintText()
    }

    // MARK: - Populate Controls

    private func populateVoices() {
        voicePopUp.removeAllItems()

        // 1. Siri Australian Male (Default Recommended)
        voicePopUp.addItem(withTitle: "Siri Australian Male (System) ★")
        voicePopUp.lastItem?.representedObject = "siri_male"

        // 2. Karen
        voicePopUp.addItem(withTitle: "Karen (Standard Australian)")
        voicePopUp.lastItem?.representedObject = "Karen"

        // 3. Other system voices
        let allVoices = announcer.availableVoices()
        let englishVoices = allVoices.filter { $0.language.lowercased().hasPrefix("en") && !$0.name.contains("Karen") }

        if !englishVoices.isEmpty {
            voicePopUp.menu?.addItem(NSMenuItem.separator())
            for voice in englishVoices {
                let localeName = Locale.current.localizedString(forIdentifier: voice.language) ?? voice.language
                voicePopUp.addItem(withTitle: "\(voice.name) (\(localeName))")
                voicePopUp.lastItem?.representedObject = voice.identifier
            }
        }

        selectCurrentVoice()
    }

    private func selectCurrentInterval() {
        for item in intervalPopUp.itemArray {
            if let val = item.representedObject as? AnnouncementInterval, val == preferences.interval {
                intervalPopUp.select(item)
                break
            }
        }
    }

    private func selectCurrentFormat() {
        switch preferences.timeFormat {
        case .system: formatSegmented.selectedSegment = 0
        case .twelveHour: formatSegmented.selectedSegment = 1
        case .twentyFourHour: formatSegmented.selectedSegment = 2
        }
    }

    private func selectCurrentStyle() {
        switch preferences.announcementStyle {
        case .conversational: styleSegmented.selectedSegment = 0
        case .concise: styleSegmented.selectedSegment = 1
        case .casual: styleSegmented.selectedSegment = 2
        }
    }

    private func selectCurrentVoice() {
        let current = preferences.voiceIdentifier
        for item in voicePopUp.itemArray {
            if let id = item.representedObject as? String {
                if id == current || (current.isEmpty && id == "siri_male") || (current == "system" && id == "siri_male") || (current == "Gordon" && id == "siri_male") {
                    voicePopUp.select(item)
                    return
                }
            }
        }
    }

    private func selectCurrentSpeed() {
        for item in speedPopUp.itemArray {
            if let val = item.representedObject as? Float, abs(val - preferences.speechRate) < 0.03 {
                speedPopUp.select(item)
                break
            }
        }
    }

    // MARK: - Actions

    @objc private func enableToggled() {
        preferences.isEnabled = enableCheckbox.state == .on
        if preferences.isEnabled {
            announcer.startScheduling()
        } else {
            announcer.cancelScheduling()
        }
        notifyPreferencesChanged()
    }

    @objc private func intervalChanged() {
        guard let item = intervalPopUp.selectedItem,
              let interval = item.representedObject as? AnnouncementInterval else { return }
        preferences.interval = interval
        announcer.reschedule()
        notifyPreferencesChanged()
    }

    @objc private func formatChanged() {
        switch formatSegmented.selectedSegment {
        case 0: preferences.timeFormat = .system
        case 1: preferences.timeFormat = .twelveHour
        case 2: preferences.timeFormat = .twentyFourHour
        default: break
        }
        notifyPreferencesChanged()
    }

    @objc private func styleChanged() {
        switch styleSegmented.selectedSegment {
        case 0: preferences.announcementStyle = .conversational
        case 1: preferences.announcementStyle = .concise
        case 2: preferences.announcementStyle = .casual
        default: break
        }
        notifyPreferencesChanged()
    }

    @objc private func voiceChanged() {
        guard let item = voicePopUp.selectedItem,
              let voiceId = item.representedObject as? String else { return }
        preferences.voiceIdentifier = voiceId
        notifyPreferencesChanged()
    }

    @objc private func testVoiceClicked() {
        announcer.announceCurrentTime()
    }

    @objc private func speedChanged() {
        guard let item = speedPopUp.selectedItem,
              let speed = item.representedObject as? Float else { return }
        preferences.speechRate = speed
        notifyPreferencesChanged()
    }

    @objc private func volumeChanged() {
        preferences.speechVolume = volumeSlider.floatValue
        volumeLabel.stringValue = "\(Int(preferences.speechVolume * 100))%"
        notifyPreferencesChanged()
    }

    @objc private func dockToggled() {
        preferences.showInDock = showInDockCheckbox.state == .on
        applyActivationPolicy()
        updateHintText()
        notifyPreferencesChanged()
    }

    @objc private func menuBarToggled() {
        preferences.showInMenuBar = showInMenuBarCheckbox.state == .on
        NotificationCenter.default.post(name: .timeSayerMenuBarVisibilityChanged, object: nil)
        updateHintText()
        notifyPreferencesChanged()
    }

    @objc private func loginToggled() {
        let enable = openAtLoginCheckbox.state == .on
        preferences.openAtLogin = enable
        applyLoginItem(enable: enable)
        notifyPreferencesChanged()
    }

    private func notifyPreferencesChanged() {
        NotificationCenter.default.post(name: .timeSayerPreferencesChanged, object: nil)
    }

    private func updateHintText() {
        if !preferences.showInDock && !preferences.showInMenuBar {
            hintLabel.stringValue = "💡 Tip: With both hidden, reopen Settings anytime by opening \"Time Sayer\" from Spotlight (⌘ Space) or Launchpad."
            hintLabel.textColor = .systemBlue
        } else {
            hintLabel.stringValue = "Changes take effect immediately and are saved automatically."
            hintLabel.textColor = .secondaryLabelColor
        }
    }

    // MARK: - Helpers

    private func makeSectionHeader(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .labelColor
        return label
    }

    private func makeFieldLabel(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func makeSeparator(y: CGFloat) -> NSBox {
        let separator = NSBox(frame: NSRect(x: 20, y: y, width: 440, height: 1))
        separator.boxType = .separator
        return separator
    }

    public func applyActivationPolicy() {
        if preferences.showInDock {
            NSApplication.shared.setActivationPolicy(.regular)
        } else {
            NSApplication.shared.setActivationPolicy(.accessory)
            if window?.isVisible == true {
                NSApplication.shared.activate(ignoringOtherApps: true)
                window?.makeKeyAndOrderFront(nil)
            }
        }
    }

    public func applyLoginItem(enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Time Sayer: Login item registration: \(error)")
            }
        }
    }

    // MARK: - Window Management

    public func showSettings() {
        enableCheckbox.state = preferences.isEnabled ? .on : .off
        selectCurrentInterval()
        selectCurrentFormat()
        selectCurrentStyle()
        selectCurrentVoice()
        selectCurrentSpeed()
        volumeSlider.floatValue = preferences.speechVolume
        volumeLabel.stringValue = "\(Int(preferences.speechVolume * 100))%"
        showInDockCheckbox.state = preferences.showInDock ? .on : .off
        showInMenuBarCheckbox.state = preferences.showInMenuBar ? .on : .off
        openAtLoginCheckbox.state = preferences.openAtLogin ? .on : .off
        updateHintText()

        if !preferences.showInDock {
            NSApplication.shared.setActivationPolicy(.regular)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    public func windowWillClose(_ notification: Notification) {
        applyActivationPolicy()
    }
}

extension Notification.Name {
    static let timeSayerMenuBarVisibilityChanged = Notification.Name("timeSayerMenuBarVisibilityChanged")
    static let timeSayerPreferencesChanged = Notification.Name("timeSayerPreferencesChanged")
}
