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

    /// Speaks the given text using the selected voice and volume.
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

        let script: String
        if voiceId == "siri_male" || voiceId == "system" || voiceId == "Gordon" || voiceId.isEmpty {
            // Uses macOS default AppleScript speech which connects directly to the Siri Australian Male voice
            script = "say \"\(escapedText)\""
        } else {
            let voiceName = voiceId.contains(".") ? (voiceId.components(separatedBy: ".").last ?? voiceId) : voiceId
            script = "say \"\(escapedText)\" using \"\(voiceName)\""
        }

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
    private func scheduleNextAnnouncement() {
        let now = Date()
        let interval = preferences.interval

        guard let nextDate = calculateNextBoundaryDate(from: now, interval: interval) else {
            return
        }

        let timeInterval = max(0.05, nextDate.timeIntervalSince(now))

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(deadline: .now() + timeInterval, leeway: .nanoseconds(0))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            if self.preferences.isEnabled {
                let text = self.formatSpokenTime(for: nextDate, style: self.preferences.announcementStyle)
                self.speak(text: text)
            }
            self.scheduleNextAnnouncement()
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
        let calendar = Calendar.current
        let hour24 = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

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
