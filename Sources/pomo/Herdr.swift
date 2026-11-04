import Foundation

/// Check if we're running inside herdr.
func isInHerdr() -> Bool {
    return ProcessInfo.processInfo.environment["HERDR_ENV"] != nil
}

/// Play a custom MP3 sound using afplay.
/// Falls back to terminal bell if afplay fails or file doesn't exist.
///
/// - Parameter path: Path to the MP3 file to play.
func playCustomSound(_ path: String) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = ["afplay", path]

    // Redirect both stdout and stderr to /dev/null
    let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
    let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
    task.standardOutput = out
    task.standardError = err

    do {
        try task.run()
        task.waitUntilExit()
        let success = task.terminationStatus == 0
        try? out?.close()
        try? err?.close()
        if !success {
            write(STDOUT_FILENO, "\u{7}", 1)
            fflush(stdout)
        }
    } catch {
        try? out?.close()
        try? err?.close()
        write(STDOUT_FILENO, "\u{7}", 1)
        fflush(stdout)
    }
}

/// Send a herdr notification with optional sound override.
///
/// - Parameters:
///   - title: Notification title.
///   - body: Optional notification body text.
///   - customSound: Optional path to MP3 file for custom sound playback.
private func sendHerdrNotification(_ title: String, body: String? = nil, customSound: String? = nil) {
    var args = ["herdr", "notification", "show", title]
    if let customSound {
        args.append("--sound")
        args.append(customSound)
    }
    if let body {
        args.append("--body")
        args.append(body)
    }

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    task.arguments = args

    let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
    let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
    task.standardOutput = out
    task.standardError = err
    try? task.run()
    try? out?.close()
    try? err?.close()
}

/// Send a notification.
/// If running in herdr, use herdr's notification system.
/// Otherwise, fall back to the terminal bell.
///
/// - Parameters:
///   - title: Notification title.
///   - body: Optional notification body text.
///   - customSound: Optional path to MP3 file for custom sound playback.
func notify(title: String, body: String? = nil, customSound: String? = nil) {
    if let sound = customSound {
        if isInHerdr() {
            sendHerdrNotification(title, body: body)
        }
        playCustomSound(sound)
    } else if isInHerdr() {
        sendHerdrNotification(title, body: body, customSound: "done")
    } else {
        write(STDOUT_FILENO, "\u{7}", 1)
        fflush(stdout)
    }
}
