import Foundation

@main
struct TestRunner {
    static func main() {
        print("🧪 Running Time Sayer unit verification...")

        let announcer = TimeAnnouncer.shared

        // Test 12-Hour format explicitly
        let testDate = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 22, hour: 14, minute: 30, second: 0))!

        let conversational12 = announcer.formatSpokenTime(for: testDate, style: .conversational, is24Hour: false)
        print("12h Conversational format: \(conversational12)")
        assert(conversational12 == "It's 2 30 PM.", "Failed 12h conversational format")

        let concise12 = announcer.formatSpokenTime(for: testDate, style: .concise, is24Hour: false)
        print("12h Concise format: \(concise12)")
        assert(concise12 == "2 30 PM.", "Failed 12h concise format")

        let casual12 = announcer.formatSpokenTime(for: testDate, style: .casual, is24Hour: false)
        print("12h Casual format: \(casual12)")
        assert(casual12 == "Half past two.", "Failed 12h casual format")

        // Test 24-Hour format explicitly (14:30)
        let conversational24 = announcer.formatSpokenTime(for: testDate, style: .conversational, is24Hour: true)
        print("24h Conversational format (14:30): \(conversational24)")
        assert(conversational24 == "It's 14 30 hours.", "Failed 24h conversational format")

        let concise24 = announcer.formatSpokenTime(for: testDate, style: .concise, is24Hour: true)
        print("24h Concise format (14:30): \(concise24)")
        assert(concise24 == "14 30 hours.", "Failed 24h concise format")

        // Test 24-Hour format single digit minute (13:01 -> "It's 13 oh 1 hours.")
        let singleDigitDate = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 22, hour: 13, minute: 1, second: 0))!
        let conversational24Single = announcer.formatSpokenTime(for: singleDigitDate, style: .conversational, is24Hour: true)
        print("24h Conversational format (13:01): \(conversational24Single)")
        assert(conversational24Single == "It's 13 oh 1 hours.", "Failed 24h single digit minute format")

        let concise24Single = announcer.formatSpokenTime(for: singleDigitDate, style: .concise, is24Hour: true)
        print("24h Concise format (13:01): \(concise24Single)")
        assert(concise24Single == "13 oh 1 hours.", "Failed 24h single digit minute concise format")

        // Test on the hour (12h vs 24h)
        let hourDate = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 22, hour: 15, minute: 0, second: 0))!
        let hourConversational12 = announcer.formatSpokenTime(for: hourDate, style: .conversational, is24Hour: false)
        print("12h Hour conversational format: \(hourConversational12)")
        assert(hourConversational12 == "It's 3 o'clock PM.", "Failed 12h hour format")

        let hourConversational24 = announcer.formatSpokenTime(for: hourDate, style: .conversational, is24Hour: true)
        print("24h Hour conversational format: \(hourConversational24)")
        assert(hourConversational24 == "It's 15 hundred hours.", "Failed 24h hour format")

        // Test system format detection helper
        let isSys24 = PreferencesManager.isSystem24HourFormat()
        print("Detected system 24-hour setting: \(isSys24)")

        // Test next boundary calculations
        let baseTime = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 22, hour: 10, minute: 14, second: 25))!

        // Next minute boundary should be 10:15:00
        if let nextMin = announcer.calculateNextBoundaryDate(from: baseTime, interval: .everyMinute) {
            let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: nextMin)
            print("Next minute boundary from 10:14:25: \(comp.hour!):\(comp.minute!):\(comp.second!)")
            assert(comp.hour == 10 && comp.minute == 15 && comp.second == 0, "Minute boundary incorrect")
        }

        // Next 5-minute boundary from 10:14:25 should be 10:15:00
        if let next5Min = announcer.calculateNextBoundaryDate(from: baseTime, interval: .everyFiveMinutes) {
            let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: next5Min)
            print("Next 5-minute boundary from 10:14:25: \(comp.hour!):\(comp.minute!):\(comp.second!)")
            assert(comp.hour == 10 && comp.minute == 15 && comp.second == 0, "5-minute boundary incorrect")
        }

        // Next quarter boundary from 10:14:25 should be 10:15:00
        if let nextQuarter = announcer.calculateNextBoundaryDate(from: baseTime, interval: .everyQuarterHour) {
            let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: nextQuarter)
            print("Next quarter boundary from 10:14:25: \(comp.hour!):\(comp.minute!):\(comp.second!)")
            assert(comp.hour == 10 && comp.minute == 15 && comp.second == 0, "Quarter boundary incorrect")
        }

        // Next half hour boundary from 10:14:25 should be 10:30:00
        if let nextHalf = announcer.calculateNextBoundaryDate(from: baseTime, interval: .everyHalfHour) {
            let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: nextHalf)
            print("Next half boundary from 10:14:25: \(comp.hour!):\(comp.minute!):\(comp.second!)")
            assert(comp.hour == 10 && comp.minute == 30 && comp.second == 0, "Half hour boundary incorrect")
        }

        // Next hour boundary from 10:14:25 should be 11:00:00
        if let nextHour = announcer.calculateNextBoundaryDate(from: baseTime, interval: .everyHour) {
            let comp = Calendar.current.dateComponents([.hour, .minute, .second], from: nextHour)
            print("Next hour boundary from 10:14:25: \(comp.hour!):\(comp.minute!):\(comp.second!)")
            assert(comp.hour == 11 && comp.minute == 0 && comp.second == 0, "Hour boundary incorrect")
        }

        // Test boundary timing protection against saying one minute before (e.g. 12:59:59.8 -> 1:00 PM)
        let justBeforeHour = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 22, hour: 12, minute: 59, second: 59))!.addingTimeInterval(0.8)
        let justBeforeHourText = announcer.formatSpokenTime(for: justBeforeHour, style: .conversational, is24Hour: false)
        print("12:59:59.8 format result: \(justBeforeHourText)")
        assert(justBeforeHourText == "It's 1 o'clock PM.", "Boundary jitter protection failed: should round 12:59:59.8 up to 1:00 PM")

        let justBeforeQuarter = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 22, hour: 13, minute: 14, second: 59))!.addingTimeInterval(0.9)
        let justBeforeQuarterText = announcer.formatSpokenTime(for: justBeforeQuarter, style: .casual, is24Hour: false)
        print("13:14:59.9 format result: \(justBeforeQuarterText)")
        assert(justBeforeQuarterText == "Quarter past one.", "Boundary jitter protection failed: should round 13:14:59.9 up to Quarter past one")

        print("🎉 All verification checks passed successfully!")
    }
}
