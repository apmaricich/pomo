import Foundation

struct WorkStats {
    let totalPlanned: Int
    let totalActual: Int
    let overflow: Int
    let sessionCount: Int
    let completedNaturallyCount: Int
    let manualSessionCount: Int
}

struct BreakStats {
    let breakCount: Int
    let skippedCount: Int
    let totalDuration: Int
    let averageDuration: Double
}

func computePeriodRange(period: String) -> (Date, Date) {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date()
    
    switch period {
    case "today":
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let start = calendar.date(from: components)!
        return (start, now)
        
    case "this week":
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        let start = calendar.date(from: components)!
        return (start, now)
        
    case "this month":
        let components = calendar.dateComponents([.year, .month], from: now)
        let start = calendar.date(from: components)!
        return (start, now)
        
    case "this year":
        let components = calendar.dateComponents([.year], from: now)
        let start = calendar.date(from: components)!
        return (start, now)
        
    default:
        return (now, now)
    }
}

func getWorkStats(sessions: [Session]) -> WorkStats {
    let workSessions = sessions.filter { $0.type == .work }
    
    var totalPlanned = 0
    var totalActual = 0
    var completedNaturallyCount = 0
    var manualSessionCount = 0
    
    for session in workSessions {
        totalPlanned += session.plannedDuration
        totalActual += session.actualDuration
        if session.completedNaturally {
            completedNaturallyCount += 1
        }
        if session.source == .manual {
            manualSessionCount += 1
        }
    }
    
    let overflow = max(0, totalActual - totalPlanned)
    
    return WorkStats(
        totalPlanned: totalPlanned,
        totalActual: totalActual,
        overflow: overflow,
        sessionCount: workSessions.count,
        completedNaturallyCount: completedNaturallyCount,
        manualSessionCount: manualSessionCount
    )
}

func getBreakStats(sessions: [Session]) -> BreakStats {
    let breakSessions = sessions.filter { $0.type == .breakPeriod }
    
    var totalDuration = 0
    var skippedCount = 0
    
    for session in breakSessions {
        totalDuration += session.actualDuration
        if !session.completedNaturally {
            skippedCount += 1
        }
    }
    
    let averageDuration = breakSessions.isEmpty ? 0.0 : Double(totalDuration) / Double(breakSessions.count)
    
    return BreakStats(
        breakCount: breakSessions.count,
        skippedCount: skippedCount,
        totalDuration: totalDuration,
        averageDuration: averageDuration
    )
}

func formatDuration(seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    
    if hours > 0 {
        return String(format: "%dh %dm", hours, minutes)
    } else if minutes > 0 {
        return String(format: "%dm", minutes)
    } else {
        return String(format: "%ds", secs)
    }
}

func printStats(period: String, work: WorkStats, breaks: BreakStats) {
    let title = "📊 Pomodoro Stats - \(period)"
    let separator = String(repeating: "=", count: 50)
    
    print("\n\(ANSI.colorCyan)\(title)\(ANSI.reset)")
    print("\(ANSI.colorCyan)\(separator)\(ANSI.reset)\n")
    
    // Work Stats
    print("\(ANSI.colorGreen)📈 Work Sessions\(ANSI.reset)")
    print(String(repeating: "-", count: 50))
    let sessionLine = work.manualSessionCount > 0
        ? "  Sessions: \(work.sessionCount) (\(work.manualSessionCount) manual)"
        : "  Sessions: \(work.sessionCount)"
    print(sessionLine)
    print("  Completed naturally: \(work.completedNaturallyCount)")
    print("  Total planned: \(formatDuration(seconds: work.totalPlanned))")
    print("  Total actual: \(formatDuration(seconds: work.totalActual))")
    if work.overflow > 0 {
        print("  Overflow: \(ANSI.colorRed)+\(formatDuration(seconds: work.overflow))\(ANSI.reset)")
    }
    print("")
    
    // Break Stats
    print("\(ANSI.colorBlue)☕ Breaks\(ANSI.reset)")
    print(String(repeating: "-", count: 50))
    print("  Breaks taken: \(breaks.breakCount)")
    print("  Skipped: \(breaks.skippedCount)")
    print("  Total duration: \(formatDuration(seconds: breaks.totalDuration))")
    if breaks.breakCount > 0 {
        print("  Average duration: \(formatDuration(seconds: Int(breaks.averageDuration)))")
    }
    print("")
    
    // Summary
    let totalTimeSpent = work.totalActual + breaks.totalDuration
    print("\(ANSI.colorMagenta)📊 Summary\(ANSI.reset)")
    print(String(repeating: "-", count: 50))
    print("  Total time spent: \(formatDuration(seconds: totalTimeSpent))")
    if work.sessionCount > 0 {
        print("  Focus time: \(formatDuration(seconds: work.totalPlanned))")
    }
    print("")
}
