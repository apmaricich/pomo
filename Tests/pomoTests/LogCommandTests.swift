import XCTest
@testable import pomo

final class LogCommandTests: XCTestCase {
    // MARK: - Time Parsing Tests

    func testParseTime12HourNoMinutes() {
        let result = parseTime("10am")
        XCTAssertNotNil(result)
        let comps = Calendar.current.dateComponents([.hour], from: result!)
        XCTAssertEqual(comps.hour, 10)
    }

    func testParseTime12HourWithMinutes() {
        let result = parseTime("10:30am")
        XCTAssertNotNil(result)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: result!)
        XCTAssertEqual(comps.hour, 10)
        XCTAssertEqual(comps.minute, 30)
    }

    func testParseTimePM() {
        let result = parseTime("2pm")
        XCTAssertNotNil(result)
        let comps = Calendar.current.dateComponents([.hour], from: result!)
        XCTAssertEqual(comps.hour, 14)
    }

    func testParseTime24Hour() {
        let result = parseTime("14:00")
        XCTAssertNotNil(result)
        let comps = Calendar.current.dateComponents([.hour], from: result!)
        XCTAssertEqual(comps.hour, 14)
    }

    func testParseTime24HourShort() {
        let result = parseTime("14")
        XCTAssertNotNil(result)
        let comps = Calendar.current.dateComponents([.hour], from: result!)
        XCTAssertEqual(comps.hour, 14)
    }

    func testParseTimeInvalid() {
        let result = parseTime("not a time")
        XCTAssertNil(result)
    }

    // MARK: - Manual Session Creation Tests

    func testCreateManualSessionMinutes() throws {
        let session = try createManualSession(minutes: 45, hours: nil, startTime: nil, sessionType: .work)
        XCTAssertEqual(session.actualDuration, 45 * 60)
        XCTAssertEqual(session.plannedDuration, 45 * 60)
        XCTAssertEqual(session.type, .work)
        XCTAssertEqual(session.source, .manual)
        XCTAssertTrue(session.completedNaturally)
    }

    func testCreateManualSessionHours() throws {
        let session = try createManualSession(minutes: nil, hours: 2, startTime: nil, sessionType: .work)
        XCTAssertEqual(session.actualDuration, 2 * 3600)
        XCTAssertEqual(session.source, .manual)
    }

    func testCreateManualSessionBothDuration() {
        do {
            _ = try createManualSession(minutes: 30, hours: 1, startTime: nil, sessionType: .work)
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func testCreateManualSessionNoDuration() {
        do {
            _ = try createManualSession(minutes: nil, hours: nil, startTime: nil, sessionType: .work)
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func testCreateManualBreakSession() throws {
        let session = try createManualSession(minutes: 15, hours: nil, startTime: nil, sessionType: .breakPeriod)
        XCTAssertEqual(session.type, .breakPeriod)
        XCTAssertEqual(session.source, .manual)
    }

    func testCreateManualSessionWithStartTime() throws {
        let start = Date().addingTimeInterval(-7200)
        let session = try createManualSession(minutes: 30, hours: nil, startTime: start, sessionType: .work)
        XCTAssertEqual(session.startTime.date, start)
    }

    // MARK: - Argument Parsing Tests

    func testParseLogArgsMinutes() throws {
        let args = try parseLogArgs(["-m", "45"])
        XCTAssertEqual(args.minutes, 45)
        XCTAssertNil(args.hours)
    }

    func testParseLogArgsHours() throws {
        let args = try parseLogArgs(["-h", "2"])
        XCTAssertEqual(args.hours, 2)
        XCTAssertNil(args.minutes)
    }

    func testParseLogArgsBreak() throws {
        let args = try parseLogArgs(["-m", "15", "--break"])
        XCTAssertEqual(args.sessionType, .breakPeriod)
    }

    func testParseLogArgsStartTime() throws {
        let args = try parseLogArgs(["-m", "30", "-t", "10am"])
        XCTAssertEqual(args.startTimeString, "10am")
    }

    func testParseLogArgsInvalidArg() {
        do {
            _ = try parseLogArgs(["--unknown"])
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }
}