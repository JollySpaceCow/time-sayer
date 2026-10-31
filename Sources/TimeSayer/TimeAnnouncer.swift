import Foundation
import AVFoundation
import AppKit

/// Handles speech synthesis and high-precision wall-clock time alignment scheduling.
public final class TimeAnnouncer: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    public static let shared = TimeAnnouncer()

    private let synthesizer = AVSpeechSynthesizer()
    private var scheduledTimer: DispatchSourceTimer?
    private let preferences = PreferencesManager.shared

    // Callback on announcement events if needed
    public var onAnnouncement: ((String) -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self

        // Observe macOS wake-from-sleep to re-sync the timer immediately.
        // Without this, a DispatchSourceTimer resumes from where it paused,
        // firing at the old pre-sleep boundary time and speaking a stale time.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemDidWake() {
        guard preferences.isEnabled else { return }
        print("Time Sayer: System woke from sleep — rescheduling timer.")
        cancelScheduling()
        scheduleNextAnnouncement()
    }

    /// Initialises scheduling based on current preferences.
    public func startScheduling() {
        cancelScheduling()
        guard preferences.isEnabled else { return }

        scheduleNextAnnouncement()
    }

    /// Stops any active timers.
    public func cancelScheduling() {
        scheduledTimer?.cancel()
        scheduledTimer = nil
    }

    /// Restarts scheduling (e.g. when interval or active status changes).
    public func reschedule() {
        startScheduling()
    }

    /// Announces the current time immediately.
    public func announceCurrentTime(completion: (() -> Void)? = nil) {
        let text = formatSpokenTime(for: Date(), style: preferences.announcementStyle)
        speak(text: text, completion: completion)
    }

    private var activeSpeechProcess: Process?

    /// Speaks the given text using the selected voice, volume, and speech rate.
    public func speak(text: String, completion: (() -> Void)? = nil) {
        // Cancel any active speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        if let proc = activeSpeechProcess, proc.isRunning {
            proc.terminate()
            activeSpeechProcess = nil
        }

        onAnnouncement?(text)

        let voiceId = preferences.voiceIdentifier

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")

        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\")
                              .replacingOccurrences(of: "\"", with: "\\\"")

        // Volume: AppleScript accepts a real number from 0.0 to 1.0
        let volume = max(0.0, min(1.0, Double(preferences.speechVolume)))
        let formattedVolume = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), volume)

        // Speech rate: convert relative multiplier (where 0.5 is default 1.0x) to words per minute
        let rateMultiplier = Double(preferences.speechRate) / Double(AVSpeechUtteranceDefaultSpeechRate)
        let wpm = max(90, min(360, Int(round(rateMultiplier * 180.0))))

        var scriptParts: [String] = ["say \"\(escapedText)\""]
        if voiceId != "siri_male" && voiceId != "system" && voiceId != "Gordon" && !voiceId.isEmpty {
            let voiceName = voiceId.contains(".") ? (voiceId.components(separatedBy: ".").last ?? voiceId) : voiceId
            scriptParts.append("using \"\(voiceName)\"")
        }
        scriptParts.append("volume \(formattedVolume)")
        scriptParts.append("speaking rate \(wpm)")

        let script = scriptParts.joined(separator: " ")

        process.arguments = ["-e", script]

        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.activeSpeechProcess = nil
                completion?()
            }
        }

        self.activeSpeechProcess = process

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try process.run()
            } catch {
                print("Time Sayer: Error launching speech process: \(error)")
            }
        }
    }

    /// Schedules the timer to fire at the exact wall-clock boundary of the next interval.
    private func scheduleNextAnnouncement(after date: Date? = nil) {
        let now = Date()
        let interval = preferences.interval
        let calculationBase = date.map { max($0, now) } ?? now

        guard let nextDate = calculateNextBoundaryDate(from: calculationBase, interval: interval) else {
            return
        }

        let timeInterval = nextDate.timeIntervalSince(now)
        // Add a 50ms buffer past the exact second boundary to guarantee
        // that the wall clock has crossed into the new minute and to avoid
        // monotonic clock drift waking the timer early.
        let fireDelay = max(0.05, timeInterval + 0.05)

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now() + fireDelay, leeway: .nanoseconds(0))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }

            let currentWallTime = Date()
            let drift = currentWallTime.timeIntervalSince(nextDate)

            // If the timer fires significantly late (e.g. after Mac sleep/wake),
            // the scheduled boundary is stale. Skip the announcement and
            // immediately reschedule from the actual current time instead.
            if drift > 30.0 {
                print("Time Sayer: Stale timer fired \(Int(drift))s late — skipping stale announcement and rescheduling.")
                self.scheduleNextAnnouncement()
                return
            }

            if self.preferences.isEnabled {
                // Speak the exact boundary time that was scheduled. This guarantees
                // we never announce one minute before due to sub-second timer jitter.
                let text = self.formatSpokenTime(for: nextDate, style: self.preferences.announcementStyle)
                self.speak(text: text)
            }

            // Advance scheduling from after the boundary that just fired.
            self.scheduleNextAnnouncement(after: nextDate.addingTimeInterval(1.0))
        }
        timer.resume()
        scheduledTimer = timer
    }

    /// Calculates the exact next wall-clock boundary date (e.g. strictly :00 on the hour, or :00/:15/:30/:45 on the quarter hour).
    public func calculateNextBoundaryDate(from date: Date, interval: AnnouncementInterval) -> Date? {
        let calendar = Calendar.current
        let currentSecond = calendar.component(.second, from: date)
        let currentNanosecond = calendar.component(.nanosecond, from: date)
        let currentMinute = calendar.component(.minute, from: date)

        let intervalMinutes: Int
        switch interval {
        case .everyMinute:
            intervalMinutes = 1
        case .everyFiveMinutes:
            intervalMinutes = 5
        case .everyQuarterHour:
            intervalMinutes = 15
        case .everyHalfHour:
            intervalMinutes = 30
        case .everyHour:
            intervalMinutes = 60
        }

        let minuteOffset = currentMinute % intervalMinutes
        let isExactlyOnBoundary = (minuteOffset == 0 && currentSecond == 0 && currentNanosecond == 0)

        let minutesToAdd: Int
        if isExactlyOnBoundary {
            minutesToAdd = intervalMinutes
        } else {
            minutesToAdd = intervalMinutes - minuteOffset
        }

        // Truncate current date down to the beginning of the minute (:00.000)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.second = 0
        components.nanosecond = 0

        guard let baseMinuteDate = calendar.date(from: components) else {
            return nil
        }

        // Add exact minutes to arrive precisely at the next interval boundary
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: baseMinuteDate)
    }

    /// Formats the current time into spoken natural text according to chosen style and 12/24-hour setting.
    public func formatSpokenTime(for date: Date, style: AnnouncementStyle, is24Hour: Bool? = nil) -> String {
        let use24Hour = is24Hour ?? preferences.is24HourEffective
        // Round to nearest second to avoid sub-second boundary truncation
        let roundedDate = date.addingTimeInterval(0.5)
        let calendar = Calendar.current
        let hour24 = calendar.component(.hour, from: roundedDate)
        let minute = calendar.component(.minute, from: roundedDate)

        if use24Hour {
            return format24HourTime(hour24: hour24, minute: minute, style: style)
        } else {
            return format12HourTime(hour24: hour24, minute: minute, style: style)
        }
    }

    private func format12HourTime(hour24: Int, minute: Int, style: AnnouncementStyle) -> String {
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        let period = hour24 < 12 ? "AM" : "PM"

        switch style {
        case .conversational:
            if minute == 0 {
                return "It's \(hour12) o'clock \(period)."
            } else {
                let minuteString = minute < 10 ? "oh \(minute)" : "\(minute)"
                return "It's \(hour12) \(minuteString) \(period)."
            }

        case .concise:
            if minute == 0 {
                return "\(hour12) o'clock \(period)."
            } else {
                let minuteString = minute < 10 ? "oh \(minute)" : "\(minute)"
                return "\(hour12) \(minuteString) \(period)."
            }

        case .casual:
            return formatCasualTime(hour12: hour12, minute: minute, hour24: hour24)
        }
    }

    private func format24HourTime(hour24: Int, minute: Int, style: AnnouncementStyle) -> String {
        let minutePhrase: String
        if minute == 0 {
            minutePhrase = "hundred"
        } else if minute < 10 {
            minutePhrase = "oh \(minute)"
        } else {
            minutePhrase = "\(minute)"
        }

        switch style {
        case .conversational:
            return "It's \(hour24) \(minutePhrase) hours."

        case .concise:
            return "\(hour24) \(minutePhrase) hours."

        case .casual:
            if minute == 0 {
                return "\(hour24) hundred hours."
            } else if minute == 15 {
                return "Quarter past \(hour24)."
            } else if minute == 30 {
                return "Half past \(hour24)."
            } else if minute == 45 {
                let nextHour = (hour24 + 1) % 24
                return "Quarter to \(nextHour)."
            } else {
                return "\(hour24) \(minutePhrase) hours."
            }
        }
    }

    private func formatCasualTime(hour12: Int, minute: Int, hour24: Int) -> String {
        let numberWords = [
            1: "one", 2: "two", 3: "three", 4: "four", 5: "five",
            6: "six", 7: "seven", 8: "eight", 9: "nine", 10: "ten",
            11: "eleven", 12: "twelve"
        ]
        let currentHourWord = numberWords[hour12] ?? "\(hour12)"
        let nextHourWord = numberWords[(hour12 % 12) + 1] ?? "\((hour12 % 12) + 1)"

        let timeOfDay: String
        switch hour24 {
        case 0..<12:
            timeOfDay = "in the morning"
        case 12..<17:
            timeOfDay = "in the afternoon"
        case 17..<21:
            timeOfDay = "in the evening"
        default:
            timeOfDay = "at night"
        }

        switch minute {
        case 0:
            return "\(currentHourWord.capitalized) o'clock \(timeOfDay)."
        case 15:
            return "Quarter past \(currentHourWord)."
        case 30:
            return "Half past \(currentHourWord)."
        case 45:
            return "Quarter to \(nextHourWord)."
        default:
            let minuteString = minute < 10 ? "oh \(minute)" : "\(minute)"
            return "\(currentHourWord.capitalized) \(minuteString)."
        }
    }

    /// Returns all available system voices, sorted by language and display name.
    public func availableVoices() -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().sorted {
            if $0.language != $1.language {
                return $0.language < $1.language
            }
            return $0.name < $1.name
        }
    }
}
