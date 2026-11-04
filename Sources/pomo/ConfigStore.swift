import Foundation

/// Persistent configuration for pomo sessions.
struct Config {
    /// Work duration in minutes.
    let duration: Int
    /// Number of work/break cycles.
    let cycles: Int
    /// Break duration in minutes.
    let breakDuration: Int
    /// Optional notification sound name.
    let sound: String?
}

private let configDirName = "pomo"
private let configFileName = "config.json"

private func getHomeDir() -> URL {
    if let home = ProcessInfo.processInfo.environment["HOME"] {
        return URL(fileURLWithPath: home)
    }
    return FileManager.default.homeDirectoryForCurrentUser
}

/// Loads the persisted configuration from `~/.config/pomo/config.json`.
/// Returns default configuration if the file is missing or unreadable.
func loadConfig() -> Config {
    let defaults = Config(duration: 25, cycles: 1, breakDuration: 5, sound: nil)

    let homeDir = getHomeDir()
    let configDir = homeDir
        .appendingPathComponent(".config")
        .appendingPathComponent(configDirName)
    let configPath = configDir.appendingPathComponent(configFileName)

    guard let data = try? Data(contentsOf: configPath),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        return defaults
    }

    let duration = (json["duration"] as? Int) ?? defaults.duration
    let cycles = (json["cycles"] as? Int) ?? defaults.cycles
    let breakDuration = (json["breakDuration"] as? Int) ?? defaults.breakDuration
    let sound = json["sound"] as? String

    return Config(duration: duration, cycles: cycles, breakDuration: breakDuration, sound: sound)
}

/// Saves the given configuration to `~/.config/pomo/config.json`.
/// Creates the directory if it does not already exist.
func saveConfig(_ config: Config) {
    let homeDir = getHomeDir()
    let configDir = homeDir
        .appendingPathComponent(".config")
        .appendingPathComponent(configDirName)

    try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)

    var json: [String: Any] = [
        "duration": config.duration,
        "cycles": config.cycles,
        "breakDuration": config.breakDuration
    ]

    if let sound = config.sound {
        json["sound"] = sound
    }

    guard let data = try? JSONSerialization.data(
        withJSONObject: json,
        options: [.prettyPrinted]
    ) else {
        return
    }

    let configPath = configDir.appendingPathComponent(configFileName)
    try? data.write(to: configPath, options: [.atomic])
}
