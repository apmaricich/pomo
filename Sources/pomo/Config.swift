import Foundation

/// Parsed CLI configuration for the pomodoro timer.
struct Config {
    let duration: Int       // Work session duration in minutes
    let cycles: Int         // Number of work/break cycles
    let breakDuration: Int  // Break duration in minutes
}

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

func printUsage() {
    print("""
    Usage: pomo [OPTIONS]

    A terminal pomodoro timer.

    Options:
      -d, --duration <minutes>    Work session duration (default: 25)
      -c, --cycles <count>        Number of work/break cycles (default: 1)
      -b, --break <minutes>       Break duration between cycles (default: 5)
      -h, --help                  Show this help message
    """)
}

/// Parse command-line arguments into a Config struct.
/// Exits with usage on --help; throws ParseError on invalid input.
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

func parseArguments(_ argv: [String]) throws -> Config {
    var duration = 25
    var cycles = 1
    var breakDuration = 5

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

        default:
            throw ParseError.unknownFlag(arg)
        }

        index += 1
    }

    return Config(duration: duration, cycles: cycles, breakDuration: breakDuration)
}
