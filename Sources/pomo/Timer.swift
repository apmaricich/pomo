import Darwin
import Foundation

/// Write a string to stdout without a newline, flushing immediately.
func writeLine(_ text: String) {
    let bytes = text.data(using: .utf8)!
    let result = bytes.withUnsafeBytes { ptr in
        write(STDOUT_FILENO, ptr.baseAddress!, bytes.count)
    }
    if result == -1 {
        perror("write")
    }
    fflush(stdout)
}

/// ANSI codes for in-place terminal display.
enum ANSI {
    static let clearLine = "\r\u{1B}[2K"
    static let colorRed = "\u{1B}[31m"
    static let colorGreen = "\u{1B}[32m"
    static let colorYellow = "\u{1B}[33m"
    static let colorBlue = "\u{1B}[34m"
    static let colorMagenta = "\u{1B}[35m"
    static let colorCyan = "\u{1B}[36m"
    static let reset = "\u{1B}[0m"
    static let bell = "\u{7}"
}

/// Format a number of seconds as MM:SS.
func formatTime(_ seconds: Int) -> String {
    let mins = seconds / 60
    let secs = seconds % 60
    return String(format: "%02d:%02d", mins, secs)
}

/// Render the timer line: a progress bar, elapsed time, and remaining time.
///
/// - Parameters:
///   - elapsed: Elapsed seconds for the current segment.
///   - total: Total seconds for the current segment.
///   - phase: Current phase (e.g., "WORK" or "BREAK").
///   - cycle: Current cycle number (1-based).
///   - color: ANSI color for the progress bar.
func renderTimer(elapsed: Int, total: Int, phase: String, cycle: Int, color: String) {
    let remaining = max(0, total - elapsed)

    // Progress bar: 30 characters wide.
    let width = 30
    let filled = Int(Double(elapsed) / Double(total) * Double(width))
    let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: width - filled)

    let line = "\(ANSI.clearLine)"
        + "\(color)│\(bar)│\(ANSI.reset) "
        + "\(ANSI.colorMagenta)\(phase)\(ANSI.reset) "
        + "(cycle \(cycle)) "
        + "\(ANSI.colorYellow)⏱ \(formatTime(elapsed))\(ANSI.reset) "
        + "remaining: \(ANSI.colorRed)\(formatTime(remaining))\(ANSI.reset)"

    writeLine(line)
}

/// Wait one second, yielding to the runtime so other tasks can run.
func sleepOneSecond() async {
    try? await Task.sleep(nanoseconds: 1_000_000_000)
}

/// Run a single timer segment (work or break).
///
/// - Parameters:
///   - duration: Duration of the segment in minutes.
///   - phase: Label for the phase (e.g., "WORK").
///   - cycle: Cycle number for display.
///   - color: ANSI color for the progress bar.
func runSegment(duration: Int, phase: String, cycle: Int, color: String) async {
    let totalSeconds = duration * 60

    for elapsed in 0..<totalSeconds {
        renderTimer(elapsed: elapsed, total: totalSeconds, phase: phase, cycle: cycle, color: color)
        await sleepOneSecond()
    }

    // Final tick: show 100% complete.
    renderTimer(elapsed: totalSeconds, total: totalSeconds, phase: phase, cycle: cycle, color: color)
    writeLine("\n")
}
