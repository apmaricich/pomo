import Foundation

enum ParseError: Error, CustomStringConvertible {
    case unknownFlag(String)
    case missingValue(String)
    case invalidValue(String, String)

    var description: String {
        switch self {
        case .unknownFlag(let flag):
            return "Unknown flag: \(flag)"
        case .missingValue(let flag):
            return "Flag \(flag) requires a value"
        case .invalidValue(let flag, let reason):
            return "Invalid value for \(flag): \(reason)"
        }
    }
}

/// Overrides provided via command-line arguments; nil means "not specified."
struct CLIOverrides {
    let duration: Int?
    let cycles: Int?
    let breakDuration: Int?
    let sound: String?
}

func printUsage() {
    print("""
    Usage: pomo [OPTIONS]

    A terminal pomodoro timer.

    Options:
      -d, --duration <minutes>    Work session duration (default: 25)
      -c, --cycles <count>        Number of work/break cycles (default: 1)
      -b, --break <minutes>       Break duration between cycles (default: 5)
      -s, --sound <path>          Path to MP3 sound file for notifications
      -h, --help                  Show this help message

    Configuration is stored in ~/.config/pomo/config.json. CLI flags
    override persisted values, which override built-in defaults.
    """)
}

private func parsePositiveInt(_ argv: [String], index: inout Int, flag: String) throws -> Int {
    index += 1
    guard index < argv.count else {
        throw ParseError.missingValue(flag)
    }
    guard let value = Int(argv[index]) else {
        throw ParseError.invalidValue(flag, "must be a number")
    }
    guard value > 0 else {
        throw ParseError.invalidValue(flag, "must be positive")
    }
    return value
}

/// Parse command-line arguments into CLIOverrides (nil = not specified).
/// Exits with usage on --help; throws ParseError on invalid input.
func parseOverrides(_ argv: [String]) throws -> CLIOverrides {
    var duration: Int?
    var cycles: Int?
    var breakDuration: Int?
    var sound: String?

    var index = 1
    while index < argv.count {
        let arg = argv[index]

        switch arg {
        case "-h", "--help":
            printUsage()
            exit(0)

        case "-d", "--duration":
            duration = try parsePositiveInt(argv, index: &index, flag: arg)

        case "-c", "--cycles":
            cycles = try parsePositiveInt(argv, index: &index, flag: arg)

        case "-b", "--break":
            breakDuration = try parsePositiveInt(argv, index: &index, flag: arg)

        case "-s", "--sound":
            index += 1
            guard index < argv.count else {
                throw ParseError.missingValue(arg)
            }
            sound = argv[index]

        default:
            throw ParseError.unknownFlag(arg)
        }

        index += 1
    }

    return CLIOverrides(duration: duration, cycles: cycles, breakDuration: breakDuration, sound: sound)
}

/// Resolve final configuration: CLI overrides > persisted config > built-in defaults.
func resolveConfig(_ overrides: CLIOverrides) -> Config {
    let persisted = loadConfig()

    return Config(
        duration: overrides.duration ?? persisted.duration,
        cycles: overrides.cycles ?? persisted.cycles,
        breakDuration: overrides.breakDuration ?? persisted.breakDuration,
        sound: overrides.sound ?? persisted.sound
    )
}
