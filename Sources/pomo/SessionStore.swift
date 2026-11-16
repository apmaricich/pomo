import Foundation

/// Wrapper that encodes/decodes Date as ISO8601 string (needed because newer
/// Swift toolchains removed dateStrategy from JSONEncoder/JSONDecoder).
struct ISO8601Date: Codable, Comparable {
    let date: Date
    
    init(_ date: Date) {
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(string)")
        }
        self.date = date
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let string = formatter.string(from: date)
        try container.encode(string)
    }
    
    static func < (lhs: ISO8601Date, rhs: ISO8601Date) -> Bool {
        return lhs.date < rhs.date
    }
    
    static func == (lhs: ISO8601Date, rhs: ISO8601Date) -> Bool {
        return lhs.date == rhs.date
    }
}

final class SessionStore {
    private let filePath: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.filePath = fileURL.path
        } else {
            let configDir = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".config")
                .appendingPathComponent("pomo")
            self.filePath = configDir.appendingPathComponent("sessions.json").path
        }
    }
    
    /// Save a session by appending it to the store.
    func saveSession(_ session: Session) throws {
        var sessions = loadSessions()
        sessions.append(session)
        
        let data = try encoder.encode(sessions)
        try atomicWrite(data, toPath: filePath)
    }
    
    /// Load all sessions from the store. Returns empty array if file doesn't exist.
    func loadSessions() -> [Session] {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let sessions = try? decoder.decode([Session].self, from: data) else {
            return []
        }
        return sessions
    }
    
    /// Filter sessions within a date range.
    func filterByPeriod(from start: Date, to end: Date) -> [Session] {
        let startWrapped = ISO8601Date(start)
        let endWrapped = ISO8601Date(end)
        return loadSessions().filter { session in
            session.startTime >= startWrapped && session.endTime <= endWrapped
        }
    }
    
    /// Atomic write: write to temp file, then rename to target.
    private func atomicWrite(_ data: Data, toPath path: String) throws {
        let fileURL = URL(fileURLWithPath: path)
        
        // Ensure directory exists
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Write to temp file in same directory
        let tempURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent(".sessions.json.tmp")
        try data.write(to: tempURL, options: .atomic)
        
        // Rename temp to target (atomic on POSIX)
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        }
        try FileManager.default.moveItem(at: tempURL, to: fileURL)
    }
}
