import XCTest
@testable import pomo

final class StatsTests: XCTestCase {
    
    func testComputePeriodRangeToday() {
        let (start, end) = computePeriodRange(period: "today")
        let calendar = Calendar(identifier: .gregorian)
        
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
        
        XCTAssertEqual(startComponents.year, endComponents.year)
        XCTAssertEqual(startComponents.month, endComponents.month)
        XCTAssertEqual(startComponents.day, endComponents.day)
        
        // Start should be at 00:00:00
        let startHour = calendar.component(.hour, from: start)
        let startMinute = calendar.component(.minute, from: start)
        let startSecond = calendar.component(.second, from: start)
        XCTAssertEqual(startHour, 0)
        XCTAssertEqual(startMinute, 0)
        XCTAssertEqual(startSecond, 0)
    }
    
    func testGetWorkStats() {
        // Create mock work sessions
        let session1 = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 1500,
            actualDuration: 1600,
            type: .work,
            completedNaturally: true
        )
        
        let session2 = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 1500,
            actualDuration: 1500,
            type: .work,
            completedNaturally: false
        )
        
        let workStats = getWorkStats(sessions: [session1, session2])
        
        XCTAssertEqual(workStats.totalPlanned, 3000)
        XCTAssertEqual(workStats.totalActual, 3100)
        XCTAssertEqual(workStats.overflow, 100)
        XCTAssertEqual(workStats.sessionCount, 2)
        XCTAssertEqual(workStats.completedNaturallyCount, 1)
    }
    
    func testGetBreakStats() {
        // Create mock break sessions
        let session1 = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 300,
            actualDuration: 300,
            type: .breakPeriod,
            completedNaturally: true
        )
        
        let session2 = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 300,
            actualDuration: 120,
            type: .breakPeriod,
            completedNaturally: false
        )
        
        let breakStats = getBreakStats(sessions: [session1, session2])
        
        XCTAssertEqual(breakStats.breakCount, 2)
        XCTAssertEqual(breakStats.skippedCount, 1)
        XCTAssertEqual(breakStats.totalDuration, 420)
        XCTAssertEqual(breakStats.averageDuration, 210)
    }
    
    func testFormatDuration() {
        XCTAssertEqual(formatDuration(seconds: 3600), "1h 0m")
        XCTAssertEqual(formatDuration(seconds: 3661), "1h 1m")
        XCTAssertEqual(formatDuration(seconds: 120), "2m")
        XCTAssertEqual(formatDuration(seconds: 45), "45s")
    }
    
    func testGetWorkStatsWithBreakSessions() {
        // Mix of work and break sessions
        let workSession = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 1500,
            actualDuration: 1500,
            type: .work,
            completedNaturally: true
        )
        
        let breakSession = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 300,
            actualDuration: 300,
            type: .breakPeriod,
            completedNaturally: true
        )
        
        let workStats = getWorkStats(sessions: [workSession, breakSession])
        XCTAssertEqual(workStats.sessionCount, 1)
        XCTAssertEqual(workStats.totalPlanned, 1500)
    }
    
    func testGetBreakStatsWithWorkSessions() {
        // Mix of work and break sessions
        let workSession = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 1500,
            actualDuration: 1500,
            type: .work,
            completedNaturally: true
        )
        
        let breakSession = Session(
            startTime: Date(),
            endTime: Date(),
            plannedDuration: 300,
            actualDuration: 300,
            type: .breakPeriod,
            completedNaturally: true
        )
        
        let breakStats = getBreakStats(sessions: [workSession, breakSession])
        XCTAssertEqual(breakStats.breakCount, 1)
        XCTAssertEqual(breakStats.totalDuration, 300)
    }
}
