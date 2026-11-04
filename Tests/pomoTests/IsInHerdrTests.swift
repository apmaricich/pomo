import XCTest
@testable import pomo

final class IsInHerdrTests: XCTestCase {

    func testIsInHerdr_true() {
        setenv("HERDR_ENV", "true", 1)
        defer { unsetenv("HERDR_ENV") }

        XCTAssertTrue(isInHerdr())
    }

    func testIsInHerdr_false() {
        unsetenv("HERDR_ENV")

        XCTAssertFalse(isInHerdr())
    }

}
