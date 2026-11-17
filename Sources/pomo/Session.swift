import Foundation

enum SessionType: String, Codable {
    case work
    case breakPeriod
}

struct Session: Codable {
    let id: UUID
    let startTime: ISO8601Date
    let endTime: ISO8601Date
    let plannedDuration: Int  // seconds
    let actualDuration: Int   // seconds
    let type: SessionType
    let completedNaturally: Bool
    let source: SessionSource
    
    private enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, plannedDuration, actualDuration, type, completedNaturally, source
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.startTime = try container.decode(ISO8601Date.self, forKey: .startTime)
        self.endTime = try container.decode(ISO8601Date.self, forKey: .endTime)
        self.plannedDuration = try container.decode(Int.self, forKey: .plannedDuration)
        self.actualDuration = try container.decode(Int.self, forKey: .actualDuration)
        self.type = try container.decode(SessionType.self, forKey: .type)
        self.completedNaturally = try container.decode(Bool.self, forKey: .completedNaturally)
        self.source = try container.decodeIfPresent(SessionSource.self, forKey: .source) ?? .timer
    }
    
    init(startTime: Date, endTime: Date, plannedDuration: Int, actualDuration: Int, type: SessionType, completedNaturally: Bool, source: SessionSource = .timer) {
        self.id = UUID()
        self.startTime = ISO8601Date(startTime)
        self.endTime = ISO8601Date(endTime)
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.type = type
        self.completedNaturally = completedNaturally
        self.source = source
    }
}
