import Foundation

/// Parse various time formats into a Date.
///
/// Supported formats:
/// - 12-hour: "10am", "10:30am", "11pm", "2:15pm"
/// - 24-hour: "14:00", "10:30"
/// - Relative: "today", "yesterday"
/// - If only time is given (no date), assume today
func parseTime(_ input: String) -> Date? {
    let trimmed = input.trimmingCharacters(in: .whitespaces)
    let calendar = Calendar.current
    let now = Date()
    
    // Handle relative dates
    if trimmed.lowercased() == "today" {
        return calendar.startOfDay(for: now)
    }
    if trimmed.lowercased() == "yesterday" {
        let yesterdayComponents = DateComponents(day: -1)
        let yesterday = calendar.date(byAdding: yesterdayComponents, to: calendar.startOfDay(for: now))
        return yesterday
    }
    
    // Try 12-hour format with am/pm
    if trimmed.contains("am") || trimmed.contains("pm") {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "ha"
        let clean = trimmed.replacingOccurrences(of: " ", with: "")
        
        if let date = formatter.date(from: clean) {
            // Add time to today's start
            let startOfDay = calendar.startOfDay(for: now)
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            return calendar.date(bySettingHour: components.hour ?? 0,
                                minute: components.minute ?? 0,
                                second: components.second ?? 0,
                                of: startOfDay)
        }
        
        formatter.dateFormat = "h:mma"
        if let date = formatter.date(from: clean) {
            let startOfDay = calendar.startOfDay(for: now)
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            return calendar.date(bySettingHour: components.hour ?? 0,
                                minute: components.minute ?? 0,
                                second: components.second ?? 0,
                                of: startOfDay)
        }
        
        return nil
    }
    
    // Try 24-hour format
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    
    // HH:mm format
    formatter.dateFormat = "HH:mm"
    if let date = formatter.date(from: trimmed) {
        let startOfDay = calendar.startOfDay(for: now)
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        return calendar.date(bySettingHour: components.hour ?? 0,
                            minute: components.minute ?? 0,
                            second: components.second ?? 0,
                            of: startOfDay)
    }
    
    // HH format (just hour)
    formatter.dateFormat = "HH"
    if let date = formatter.date(from: trimmed) {
        let startOfDay = calendar.startOfDay(for: now)
        let components = calendar.dateComponents([.hour], from: date)
        return calendar.date(bySettingHour: components.hour ?? 0,
                            minute: 0,
                            second: 0,
                            of: startOfDay)
    }
    
    return nil
}

/// Error type for manual session creation.
enum ManualSessionError: Error, CustomStringConvertible {
    case noDurationProvided
    case bothDurationProvided
    case invalidDuration(Int)
    case timeParseFailed(String)
    
    var description: String {
        switch self {
        case .noDurationProvided:
            return "No duration provided. Use -m or -h."
        case .bothDurationProvided:
            return "Provide only one of -m (minutes) or -h (hours), not both."
        case .invalidDuration(let dur):
            return "Duration must be positive (got \(dur))."
        case .timeParseFailed(let input):
            return "Could not parse time: '\(input)'"
        }
    }
}

/// Create a manually logged session.
func createManualSession(minutes: Int?, hours: Int?, startTime: Date?, sessionType: SessionType) throws -> Session {
    let duration: Int
    if let minutes = minutes {
        if hours != nil {
            throw ManualSessionError.bothDurationProvided
        }
        duration = minutes * 60
    } else if let hours = hours {
        duration = hours * 3600
    } else {
        throw ManualSessionError.noDurationProvided
    }
    
    if duration <= 0 {
        throw ManualSessionError.invalidDuration(duration)
    }
    
    let now = Date()
    let start: Date
    let end: Date
    
    if let startInput = startTime {
        start = startInput
        end = start.addingTimeInterval(Double(duration))
    } else {
        end = now
        start = now.addingTimeInterval(-Double(duration))
    }
    
    return Session(
        startTime: start,
        endTime: end,
        plannedDuration: duration,
        actualDuration: duration,
        type: sessionType,
        completedNaturally: true,
        source: .manual
    )
}

/// Parse arguments for the log subcommand.
struct LogArguments {
    let minutes: Int?
    let hours: Int?
    let startTimeString: String?
    let sessionType: SessionType
    
    init(minutes: Int?, hours: Int?, startTime: String?, type: SessionType) {
        self.minutes = minutes
        self.hours = hours
        self.startTimeString = startTime
        self.sessionType = type
    }
}

func parseLogArgs(_ args: [String]) throws -> LogArguments {
    var minutes: Int?
    var hours: Int?
    var startTime: String?
    var sessionType: SessionType = .work
    
    var i = 0
    while i < args.count {
        switch args[i] {
        case "-m", "--minutes":
            if i + 1 >= args.count {
                throw ManualSessionError.noDurationProvided
            }
            if let value = Int(args[i + 1]) {
                minutes = value
            } else {
                throw ManualSessionError.invalidDuration(0)
            }
            i += 2
        case "-h", "--hours":
            if i + 1 >= args.count {
                throw ManualSessionError.noDurationProvided
            }
            if let value = Int(args[i + 1]) {
                hours = value
            } else {
                throw ManualSessionError.invalidDuration(0)
            }
            i += 2
        case "-t", "--start":
            if i + 1 >= args.count {
                throw ManualSessionError.timeParseFailed("")
            }
            startTime = args[i + 1]
            i += 2
        case "--break":
            sessionType = .breakPeriod
            i += 1
        default:
            throw ManualSessionError.timeParseFailed(args[i])
        }
    }
    
    return LogArguments(minutes: minutes, hours: hours, startTime: startTime, type: sessionType)
}

/// Execute the log command with the given arguments.
///
/// Returns true on success, false on failure.
func executeLogCommand(args: [String]) throws -> Bool {
    let logArgs = try parseLogArgs(args)
    
    let startTime = logArgs.startTimeString.flatMap { parseTime($0) }
    if let input = logArgs.startTimeString, startTime == nil {
        throw ManualSessionError.timeParseFailed(input)
    }
    
    let session = try createManualSession(
        minutes: logArgs.minutes,
        hours: logArgs.hours,
        startTime: startTime,
        sessionType: logArgs.sessionType
    )
    
    let store = SessionStore()
    try store.saveSession(session)
    
    // Print confirmation
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    
    let startStr = formatter.string(from: session.startTime.date)
    let endStr = formatter.string(from: session.endTime.date)
    
    let durationStr: String
    if let hours = logArgs.hours {
        durationStr = "\(hours)h"
    } else if let minutes = logArgs.minutes {
        durationStr = "\(minutes)m"
    } else {
        durationStr = "0m"
    }
    
    print("✅ Logged \(session.type.rawValue) session: \(startStr) - \(endStr) (\(durationStr))")
    fflush(stdout)
    
    return true
}
