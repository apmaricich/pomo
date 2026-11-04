import Foundation

/// Check if we're running inside herdr.
func isInHerdr() -> Bool {
    return ProcessInfo.processInfo.environment["HERDR_ENV"] != nil
}

/// Send a notification.
/// If running in herdr, use herdr's notification system.
/// Otherwise, fall back to the terminal bell.
///
/// - Parameters:
///   - title: Notification title.
///   - body: Optional notification body text.
func notify(title: String, body: String? = nil) {
    if isInHerdr() {
        var args = ["herdr", "notification", "show", title, "--sound", "done"]
        if let body {
            args.append("--body")
            args.append(body)
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = args

        // Redirect both stdout and stderr to /dev/null
        let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        task.standardOutput = out
        task.standardError = err
        try? task.run()
        try? out?.close()
        try? err?.close()
    } else {
        // Fallback: terminal bell
        write(STDOUT_FILENO, "\u{7}", 1)
        fflush(stdout)
    }
}
