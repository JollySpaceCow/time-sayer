import Foundation

/// Defines the announcement frequency intervals.
public enum AnnouncementInterval: String, CaseIterable, Identifiable {
    case everyMinute = "minute"
    case everyQuarterHour = "quarter"
    case everyHalfHour = "half"
    case everyHour = "hour"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .everyMinute:
            return "Every Minute"
        case .everyQuarterHour:
            return "Every 15 Minutes (Quarter Hour)"
        case .everyHalfHour:
            return "Every 30 Minutes (Half Hour)"
        case .everyHour:
            return "Every Hour"
        }
    }

    public var shortTitle: String {
        switch self {
        case .everyMinute:
            return "1m"
        case .everyQuarterHour:
            return "15m"
        case .everyHalfHour:
            return "30m"
        case .everyHour:
            return "1h"
        }
    }
}

/// Spoken announcement phrasing style.
public enum AnnouncementStyle: String, CaseIterable, Identifiable {
    case conversational = "conversational" // "It's 12:30 PM" or "It's 14 30 hours"
    case concise = "concise"               // "12:30 PM" or "14 30 hours"
    case casual = "casual"                 // "Half past twelve"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .conversational:
            return "Conversational (\"It's 1:30 PM\")"
        case .concise:
            return "Concise (\"1:30 PM\")"
        case .casual:
            return "Natural Spoken (\"Half past one\")"
        }
    }
}

/// Defines 12-hour or 24-hour time format preference.
public enum TimeFormatSetting: String, CaseIterable, Identifiable {
    case system = "system"
    case twelveHour = "12h"
    case twentyFourHour = "24h"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .system:
            return "Follow System Setting (Auto)"
        case .twelveHour:
            return "12-Hour (AM / PM)"
        case .twentyFourHour:
            return "24-Hour"
        }
    }
}

/// Manages persistent user preferences using UserDefaults.
public final class PreferencesManager {
    public static let shared = PreferencesManager()

    private enum Keys {
        static let isEnabled = "TimeSayer_isEnabled"
        static let interval = "TimeSayer_interval"
        static let voiceIdentifier = "TimeSayer_voiceIdentifier"
        static let announcementStyle = "TimeSayer_announcementStyle"
        static let timeFormat = "TimeSayer_timeFormat"
        static let speechVolume = "TimeSayer_speechVolume"
        static let speechRate = "TimeSayer_speechRate"
    }

    private let defaults = UserDefaults.standard

    private init() {
        // Initialise default values if not already present
        if defaults.object(forKey: Keys.isEnabled) == nil {
            defaults.set(true, forKey: Keys.isEnabled)
        }
        if defaults.object(forKey: Keys.interval) == nil {
            defaults.set(AnnouncementInterval.everyHour.rawValue, forKey: Keys.interval)
        }
        if defaults.object(forKey: Keys.voiceIdentifier) == nil {
            defaults.set("siri_male", forKey: Keys.voiceIdentifier)
        }
        if defaults.object(forKey: Keys.announcementStyle) == nil {
            defaults.set(AnnouncementStyle.conversational.rawValue, forKey: Keys.announcementStyle)
        }
        if defaults.object(forKey: Keys.timeFormat) == nil {
            defaults.set(TimeFormatSetting.system.rawValue, forKey: Keys.timeFormat)
        }
        if defaults.object(forKey: Keys.speechVolume) == nil {
            defaults.set(1.0, forKey: Keys.speechVolume)
        }
        if defaults.object(forKey: Keys.speechRate) == nil {
            defaults.set(0.5, forKey: Keys.speechRate)
        }
    }

    public var isEnabled: Bool {
        get { defaults.bool(forKey: Keys.isEnabled) }
        set { defaults.set(newValue, forKey: Keys.isEnabled) }
    }

    public var interval: AnnouncementInterval {
        get {
            guard let rawValue = defaults.string(forKey: Keys.interval),
                  let interval = AnnouncementInterval(rawValue: rawValue) else {
                return .everyHour
            }
            return interval
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.interval)
        }
    }

    public var voiceIdentifier: String {
        get { defaults.string(forKey: Keys.voiceIdentifier) ?? "siri_male" }
        set { defaults.set(newValue, forKey: Keys.voiceIdentifier) }
    }

    public var announcementStyle: AnnouncementStyle {
        get {
            guard let rawValue = defaults.string(forKey: Keys.announcementStyle),
                  let style = AnnouncementStyle(rawValue: rawValue) else {
                return .conversational
            }
            return style
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.announcementStyle)
        }
    }

    public var timeFormat: TimeFormatSetting {
        get {
            guard let rawValue = defaults.string(forKey: Keys.timeFormat),
                  let format = TimeFormatSetting(rawValue: rawValue) else {
                return .system
            }
            return format
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.timeFormat)
        }
    }

    /// Evaluates whether 24-hour time should be used based on preferences and macOS system locale.
    public var is24HourEffective: Bool {
        switch timeFormat {
        case .twelveHour:
            return false
        case .twentyFourHour:
            return true
        case .system:
            return PreferencesManager.isSystem24HourFormat()
        }
    }

    /// Checks the macOS system time format setting.
    public static func isSystem24HourFormat() -> Bool {
        let formatString = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current) ?? ""
        return !formatString.contains("a") && (formatString.contains("H") || formatString.contains("k"))
    }

    public var speechVolume: Float {
        get { defaults.float(forKey: Keys.speechVolume) }
        set { defaults.set(newValue, forKey: Keys.speechVolume) }
    }

    public var speechRate: Float {
        get { defaults.float(forKey: Keys.speechRate) }
        set { defaults.set(newValue, forKey: Keys.speechRate) }
    }
}
