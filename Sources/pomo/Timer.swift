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
        + "remaining: \(ANSI.colorRed)\(formatTime(remaining))\(ANSI.reset) "
        + "\(ANSI.colorGreen)[p] pause [c] skip\(ANSI.reset)"

    writeLine(line)
}

/// Render the paused display, showing the timer is paused.
///
/// - Parameters:
///   - elapsed: Elapsed seconds for the current segment.
///   - total: Total seconds for the current segment.
///   - phase: Current phase (e.g., "WORK" or "BREAK").
///   - cycle: Current cycle number (1-based).
///   - color: ANSI color for the progress bar.
func renderPaused(elapsed: Int, total: Int, phase: String, cycle: Int, color: String) {
    let remaining = max(0, total - elapsed)

    // Progress bar: 30 characters wide.
    let width = 30
    let filled = Int(Double(elapsed) / Double(total) * Double(width))
    let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: width - filled)

    let line = "\(ANSI.clearLine)"
        + "\(color)│\(bar)│\(ANSI.reset) "
        + "\(ANSI.colorYellow)⏸ PAUSED\(ANSI.reset) "
        + "\(ANSI.colorMagenta)\(phase)\(ANSI.reset) "
        + "(cycle \(cycle)) "
        + "\(ANSI.colorYellow)⏱ \(formatTime(elapsed))\(ANSI.reset) "
        + "remaining: \(ANSI.colorRed)\(formatTime(remaining))\(ANSI.reset) "
        + "\(ANSI.colorGreen)[p] resume [c] skip\(ANSI.reset)"

    writeLine(line)
}

/// Render the overflow display, showing how long past the timer the user is.
///
/// - Parameters:
///   - completed: The completed duration of the segment in seconds.
///   - overflow: Seconds elapsed past the segment's original duration.
///   - phase: Current phase (e.g., "WORK" or "BREAK").
///   - cycle: Current cycle number (1-based).
///   - color: ANSI color for the progress bar.
func renderOverflow(completed: Int, overflow: Int, phase: String, cycle: Int, color: String) {
    let width = 30
    let bar = String(repeating: "█", count: width)

    let line = "\(ANSI.clearLine)"
        + "\(color)│\(bar)│\(ANSI.reset) "
        + "\(ANSI.colorMagenta)\(phase)\(ANSI.reset) "
        + "(cycle \(cycle)) "
        + "\(ANSI.colorYellow)⏱ \(formatTime(completed))\(ANSI.reset) "
        + "overflow: \(ANSI.colorRed)\(formatTime(overflow))\(ANSI.reset)"

    writeLine(line)
}

/// Read a single character from the terminal in non-blocking mode.
/// Returns the character as an optional Character, or nil if no input is available.
func readChar() -> Character? {
    var settings = termios()
    tcgetattr(STDIN_FILENO, &settings)

    defer {
        tcsetattr(STDIN_FILENO, TCSANOW, &settings)
    }

    // Turn off echo and canonical mode for immediate input
    settings.c_lflag &= ~tcflag_t(ECHO)
    settings.c_lflag &= ~tcflag_t(ICANON)

    // Set VMIN and VTIME for non-blocking read
    // In Swift on Darwin, c_cc is a tuple of 20 cc_t values.
    // We need to destructure and reconstruct it.
    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, _, _, c18, c19) = settings.c_cc
    let newCcc = (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, cc_t(0), cc_t(0), c18, c19)
    settings.c_cc = newCcc

    tcsetattr(STDIN_FILENO, TCSANOW, &settings)

    var buf = [UInt8](repeating: 0, count: 1)
    let result = read(STDIN_FILENO, &buf, 1)
    if result == 1 {
        return Character(UnicodeScalar(buf[0]))
    }
    return nil
}

/// Wait for the user to press the 'c' key to continue.
/// Renders the overflow timer continuously until the key is pressed.
///
/// - Parameters:
///   - completed: The completed duration of the segment in seconds.
///   - phase: Current phase (e.g., "WORK" or "BREAK").
///   - cycle: Current cycle number (1-based).
///   - color: ANSI color for the progress bar.
///
/// - Returns: The total time the user stayed in the overflow state, in seconds.
func waitForContinue(completed: Int, phase: String, cycle: Int, color: String) -> Int {
    let startTime = Date()

    while true {
        let elapsedOverflow = Int(Date().timeIntervalSince(startTime))
        renderOverflow(completed: completed, overflow: elapsedOverflow, phase: phase, cycle: cycle, color: color)

        // Check for 'c' key press (non-blocking)
        if let ch = readChar() {
            if ch == "c" || ch == "C" {
                return elapsedOverflow
            }
        }

        // Sleep briefly to avoid busy-waiting
        usleep(100_000)
    }
}

/// Run a single timer segment (work or break) with pause, resume, and overflow support.
///
/// - Parameters:
///   - duration: Duration of the segment in minutes.
///   - phase: Label for the phase (e.g., "WORK").
///   - cycle: Cycle number for display.
///   - color: ANSI color for the progress bar.
///   - onTimerComplete: Optional callback invoked when the timer reaches zero,
///     before the user is prompted to continue.
///
/// - Returns: The total time spent in this segment (including overflow), in seconds.
func runSegment(duration: Int, phase: String, cycle: Int, color: String,
                onTimerComplete: (() -> Void)? = nil) async -> Int {
    let totalSeconds = duration * 60
    let segmentDuration = totalSeconds

    let segmentStartTime = Date()
    var paused = false
    var totalPausedSeconds = 0
    var pauseStartTime: Date? = nil

    // Run the countdown loop using real elapsed time.
    // While paused, elapsed does not advance; on resume, remaining time continues.
    while true {
        let rawElapsed = Int(Date().timeIntervalSince(segmentStartTime))
        let elapsed = rawElapsed - totalPausedSeconds

        if elapsed >= totalSeconds {
            break
        }

        if paused {
            renderPaused(elapsed: elapsed, total: totalSeconds, phase: phase, cycle: cycle, color: color)
        } else {
            renderTimer(elapsed: elapsed, total: totalSeconds, phase: phase, cycle: cycle, color: color)
        }

        if let ch = readChar() {
            if ch == "p" || ch == "P" {
                if !paused {
                    paused = true
                    pauseStartTime = Date()
                } else {
                    paused = false
                    if let pauseStart = pauseStartTime {
                        totalPausedSeconds += Int(Date().timeIntervalSince(pauseStart))
                    }
                    pauseStartTime = nil
                }
                continue
            }
            if ch == "c" || ch == "C" {
                break
            }
        }

        usleep(100_000)
    }

    // Calculate total segment time (including pause)
    let totalSegmentTime = Int(Date().timeIntervalSince(segmentStartTime))

    // Final tick: show 100% complete
    renderTimer(elapsed: totalSeconds, total: totalSeconds, phase: phase, cycle: cycle, color: color)

    // Notify caller that the segment is done
    onTimerComplete?()

    // Wait for user to press 'c' to continue
    let overflow = waitForContinue(completed: segmentDuration, phase: phase, cycle: cycle, color: color)

    writeLine("\n")
    return totalSegmentTime + overflow
}
