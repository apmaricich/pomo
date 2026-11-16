// pomo - Terminal Pomodoro Timer
// Runs inside herdr with notification support

import Foundation

let args = CommandLine.arguments

enum Subcommand {
    case work
    case breakPeriod
    case stats
}

struct StatsPeriod: CustomStringConvertible {
    let period: String
    
    var description: String {
        return period
    }
}

func detectSubcommand(_ args: [String]) -> (Subcommand, [String]) {
    if args.count > 1 {
        switch args[1] {
        case "break":
            return (.breakPeriod, Array(args[2...]))
        case "stats":
            return (.stats, Array(args[2...]))
        default:
            break
        }
    }
    return (.work, args)
}

func parseStatsPeriod(_ args: [String]) -> StatsPeriod {
    for i in 0..<args.count {
        switch args[i] {
        case "--day":
            return StatsPeriod(period: "today")
        case "--week":
            return StatsPeriod(period: "this week")
        case "--month":
            return StatsPeriod(period: "this month")
        case "--year":
            return StatsPeriod(period: "this year")
        default:
            break
        }
    }
    return StatsPeriod(period: "today")
}

func handleWork(overrides: CLIOverrides, config: Config) async {
    let sessionStore = SessionStore()
    
    notify(title: "Pomodoro starting", body: "Work session: \(config.duration) minutes", customSound: config.sound)

    for cycle in 1...config.cycles {
        let workSession = await runSegment(
            duration: config.duration,
            phase: "WORK",
            cycle: cycle,
            color: ANSI.colorGreen,
            sessionType: .work,
            onTimerComplete: {
                notify(title: "Work complete", body: "Take a \(config.breakDuration)-minute break", customSound: config.sound)
            }
        )
        
        do {
            try sessionStore.saveSession(workSession)
        } catch {
            print("Warning: Could not save work session: \(error)")
        }

        if cycle < config.cycles {
            notify(title: "Break starting", body: "\(config.breakDuration)-minute break")
            let breakSession = await runSegment(
                duration: config.breakDuration,
                phase: "BREAK",
                cycle: cycle,
                color: ANSI.colorBlue,
                sessionType: .breakPeriod,
                onTimerComplete: {
                    notify(title: "Break complete", body: "Start working when you are ready", customSound: config.sound)
                }
            )
            
            do {
                try sessionStore.saveSession(breakSession)
            } catch {
                print("Warning: Could not save break session: \(error)")
            }
        }
    }

    notify(title: "All cycles complete!", body: "\(config.cycles) pomodoro cycle(s) finished", customSound: config.sound)
    print("\n✅ All \(config.cycles) cycle(s) complete!")
    fflush(stdout)
}

func handleBreak(overrides: CLIOverrides, config: Config) async {
    let sessionStore = SessionStore()
    let breakDuration = overrides.duration ?? 600  // 10 minutes default for standalone break
    print("🍵 Starting \(breakDuration)-minute break...")
    fflush(stdout)

    notify(title: "Break starting", body: "\(breakDuration)-minute break", customSound: config.sound)

    let breakSession = await runSegment(
        duration: breakDuration,
        phase: "BREAK",
        cycle: 1,
        color: ANSI.colorBlue,
        sessionType: .breakPeriod,
        onTimerComplete: {
            notify(title: "Break complete", body: "Time to get back to work!", customSound: config.sound)
        }
    )
    
    do {
        try sessionStore.saveSession(breakSession)
    } catch {
        print("Warning: Could not save break session: \(error)")
    }

    print("\n✅ Break complete!")
    fflush(stdout)
}

func handleStats(period: StatsPeriod) {
    let (start, end) = computePeriodRange(period: period.period)
    
    let sessionStore = SessionStore()
    let sessions = sessionStore.filterByPeriod(from: start, to: end)
    
    if sessions.isEmpty {
        print("No sessions found for \(period).")
        fflush(stdout)
        return
    }
    
    let workStats = getWorkStats(sessions: sessions)
    let breakStats = getBreakStats(sessions: sessions)
    
    printStats(period: period.period, work: workStats, breaks: breakStats)
    fflush(stdout)
}

func main() async {
    do {
        let (subcommand, subArgs) = detectSubcommand(args)
        
        switch subcommand {
        case .work:
            let overrides = try parseOverrides(subArgs)
            let config = resolveConfig(overrides)
            await handleWork(overrides: overrides, config: config)
            
        case .breakPeriod:
            let overrides = try parseOverrides(subArgs)
            let config = resolveConfig(overrides)
            await handleBreak(overrides: overrides, config: config)
            
        case .stats:
            let period = parseStatsPeriod(subArgs)
            handleStats(period: period)
        }
    } catch {
        fputs("Error: \(error)\n", stderr)
        exit(1)
    }
}

await main()
