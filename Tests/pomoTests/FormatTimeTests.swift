import XCTest
@testable import pomo

final class FormatTimeTests: XCTestCase {

    func testFormatTime_zero() {
        XCTAssertEqual(formatTime(0), "00:00")
    }

    func testFormatTime_underAMinute() {
        XCTAssertEqual(formatTime(45), "00:45")
    }

    func testFormatTime_oneMinute() {
        XCTAssertEqual(formatTime(60), "01:00")
    }

    func testFormatTime_minutesAndSeconds() {
        XCTAssertEqual(formatTime(150), "02:30")
    }

    func testFormatTime_fifteenMinutes() {
        XCTAssertEqual(formatTime(900), "15:00")
    }

    func testFormatTime_fiftyNineMinutesFiftyNineSeconds() {
        XCTAssertEqual(formatTime(3599), "59:59")
    }

    func testFormatTime_oneHour() {
        XCTAssertEqual(formatTime(3600), "01:00:00")
    }

    func testFormatTime_justUnderOneHour() {
        XCTAssertEqual(formatTime(3599), "59:59")
    }

    func testFormatTime_justOverOneHour() {
        XCTAssertEqual(formatTime(3601), "01:00:01")
    }

    func testFormatTime_twoHours() {
        XCTAssertEqual(formatTime(7200), "02:00:00")
    }

    func testFormatTime_oneHourThirty() {
        XCTAssertEqual(formatTime(5400), "01:30:00")
    }

    func testFormatTime_oneHourFifteen() {
        XCTAssertEqual(formatTime(4500), "01:15:00")
    }

    func testFormatTime_fortyFiveMinutes() {
        XCTAssertEqual(formatTime(2700), "45:00")
    }

}
