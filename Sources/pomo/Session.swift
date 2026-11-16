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
    
    init(startTime: Date, endTime: Date, plannedDuration: Int, actualDuration: Int, type: SessionType, completedNaturally: Bool) {
        self.id = UUID()
        self.startTime = ISO8601Date(startTime)
        self.endTime = ISO8601Date(endTime)
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.type = type
        self.completedNaturally = completedNaturally
    }
}
