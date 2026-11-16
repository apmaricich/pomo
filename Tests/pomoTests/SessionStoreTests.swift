import XCTest
@testable import pomo

final class SessionStoreTests: XCTestCase {
    var tempDir: URL!
    var store: SessionStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Create a unique temporary directory for each test
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        store = SessionStore(fileURL: tempDir.appendingPathComponent("sessions.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        try super.tearDownWithError()
    }

    // MARK: - Save and Load Tests

    func testSaveAndLoadSingleSession() throws {
        let start = Date().addingTimeInterval(-3600)
        let end = start.addingTimeInterval(1500)
        let session = Session(startTime: start, endTime: end, plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)

        try store.saveSession(session)
        let loaded = store.loadSessions()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, session.id)
        XCTAssertEqual(loaded[0].plannedDuration, 1500)
        XCTAssertEqual(loaded[0].type, .work)
        XCTAssertTrue(loaded[0].completedNaturally)
    }

    func testSaveAndLoadMultipleSessions() throws {
        let sessions = [
            Session(startTime: Date().addingTimeInterval(-7200), endTime: Date().addingTimeInterval(-3600), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true),
            Session(startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-1800), plannedDuration: 300, actualDuration: 300, type: .breakPeriod, completedNaturally: false),
            Session(startTime: Date().addingTimeInterval(-1800), endTime: Date(), plannedDuration: 1500, actualDuration: 1400, type: .work, completedNaturally: false)
        ]

        for session in sessions {
            try store.saveSession(session)
        }

        let loaded = store.loadSessions()
        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(loaded[0].type, .work)
        XCTAssertEqual(loaded[1].type, .breakPeriod)
        XCTAssertEqual(loaded[2].type, .work)
        XCTAssertEqual(loaded[2].actualDuration, 1400)
    }

    // MARK: - Empty Store Tests

    func testEmptyStoreReturnsEmptyArray() {
        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 0)
    }

    func testLoadFromFileDoesNotExist() {
        // Use a store pointing to a path that was never written
        let emptyStore = SessionStore(fileURL: tempDir.appendingPathComponent("never_created.json"))
        let sessions = emptyStore.loadSessions()
        XCTAssertEqual(sessions.count, 0)
    }

    // MARK: - Date Range Filter Tests

    func testFilterSessionsByDateRange() throws {
        let now = Date()
        
        let past = Session(startTime: now.addingTimeInterval(-10000), endTime: now.addingTimeInterval(-9000), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)
        let inRange = Session(startTime: now.addingTimeInterval(-3000), endTime: now.addingTimeInterval(-2000), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)
        let future = Session(startTime: now.addingTimeInterval(1000), endTime: now.addingTimeInterval(2500), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)

        try store.saveSession(past)
        try store.saveSession(inRange)
        try store.saveSession(future)

        // Filter for sessions that occurred in the last 5000 seconds
        let filtered = store.filterByPeriod(from: now.addingTimeInterval(-5000), to: now)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].id, inRange.id)
    }

    func testFilterExcludesSessionsOutsideRange() throws {
        let now = Date()
        
        let session1 = Session(startTime: now.addingTimeInterval(-10000), endTime: now.addingTimeInterval(-9000), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)
        let session2 = Session(startTime: now.addingTimeInterval(-5000), endTime: now.addingTimeInterval(-4000), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)
        let session3 = Session(startTime: now.addingTimeInterval(-1000), endTime: now.addingTimeInterval(-500), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)

        try store.saveSession(session1)
        try store.saveSession(session2)
        try store.saveSession(session3)

        // Filter to only include session2
        let filtered = store.filterByPeriod(from: now.addingTimeInterval(-6000), to: now.addingTimeInterval(-3000))
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered[0].id, session2.id)
    }

    // MARK: - File System Tests

    func testFileCreatedIfNotExists() throws {
        let fileURL = tempDir.appendingPathComponent("new_sessions.json")
        let newStore = SessionStore(fileURL: fileURL)
        
        let session = Session(startTime: Date(), endTime: Date(), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)
        try newStore.saveSession(session)

        XCTAssertEqual(newStore.loadSessions().count, 1)
    }

    func testAtomicWriteCompletesSuccessfully() throws {
        let session = Session(startTime: Date(), endTime: Date(), plannedDuration: 1500, actualDuration: 1500, type: .work, completedNaturally: true)
        
        // Save twice to ensure atomic write (temp -> rename) works
        try store.saveSession(session)
        try store.saveSession(session)

        XCTAssertEqual(store.loadSessions().count, 2)
    }
}
