import XCTest
@testable import pomo

final class ConfigTests: XCTestCase {

    func testConfigStruct() {
        let config = Config(duration: 20, cycles: 3, breakDuration: 5)
        XCTAssertEqual(config.duration, 20)
        XCTAssertEqual(config.cycles, 3)
        XCTAssertEqual(config.breakDuration, 5)
    }

    func testParseErrorDescription_unknownFlag() {
        let error = ParseError.unknownFlag("-x")
        XCTAssertEqual(error.description, "Unknown flag: -x")
    }

    func testParseErrorDescription_missingValue() {
        let error = ParseError.missingValue("-d")
        XCTAssertEqual(error.description, "Flag -d requires a value")
    }

    func testParseErrorDescription_invalidValue() {
        let error = ParseError.invalidValue("-d", "not a number")
        XCTAssertEqual(error.description, "Invalid value for -d: not a number")
    }

}
