import XCTest
@testable import pomo

final class OverflowTests: XCTestCase {

    func testCompletedDuration_displayedCorrectly() {
        let completed = 5 * 60
        XCTAssertEqual(formatTime(completed), "05:00")
    }

    func testOverflowDuration_displayedCorrectly() {
        let overflow = 19
        XCTAssertEqual(formatTime(overflow), "00:19")
    }

    func testCompletedDuration_isStatic() {
        let completed = 5 * 60
        let displayTime = formatTime(completed)
        XCTAssertEqual(displayTime, "05:00")
    }

}
