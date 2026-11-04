import XCTest
@testable import pomo

final class ParseArgumentsTests: XCTestCase {

    func testDefaultConfig() throws {
        let overrides = try parseOverrides(["pomo"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.duration, 25)
        XCTAssertEqual(config.cycles, 1)
        XCTAssertEqual(config.breakDuration, 5)
    }

    func testCustomDuration() throws {
        let overrides = try parseOverrides(["pomo", "-d", "15"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.duration, 15)
    }

    func testCustomCycles() throws {
        let overrides = try parseOverrides(["pomo", "-c", "3"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.cycles, 3)
    }

    func testCustomBreakDuration() throws {
        let overrides = try parseOverrides(["pomo", "-b", "10"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.breakDuration, 10)
    }

    func testAllCustomOptions() throws {
        let overrides = try parseOverrides(["pomo", "-d", "20", "-c", "2", "-b", "3"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.duration, 20)
        XCTAssertEqual(config.cycles, 2)
        XCTAssertEqual(config.breakDuration, 3)
    }

    func testLongFormFlags() throws {
        let overrides = try parseOverrides(["pomo", "--duration", "30", "--cycles", "4", "--break", "8"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.duration, 30)
        XCTAssertEqual(config.cycles, 4)
        XCTAssertEqual(config.breakDuration, 8)
    }

    func testUnknownFlag() {
        XCTAssertThrowsError(try parseOverrides(["pomo", "-z", "5"])) { error in
            if let parseError = error as? ParseError {
                if case .unknownFlag(let flag) = parseError {
                    XCTAssertEqual(flag, "-z")
                } else {
                    XCTFail("Expected .unknownFlag, got \(parseError)")
                }
            } else {
                XCTFail("Expected ParseError, got \(error)")
            }
        }
    }

    func testMissingValue() {
        XCTAssertThrowsError(try parseOverrides(["pomo", "-d"])) { error in
            if let parseError = error as? ParseError {
                if case .missingValue(let flag) = parseError {
                    XCTAssertEqual(flag, "-d")
                } else {
                    XCTFail("Expected .missingValue, got \(parseError)")
                }
            } else {
                XCTFail("Expected ParseError, got \(error)")
            }
        }
    }

    func testInvalidValue_notANumber() {
        XCTAssertThrowsError(try parseOverrides(["pomo", "-d", "abc"])) { error in
            if let parseError = error as? ParseError {
                if case .invalidValue(let flag, let reason) = parseError {
                    XCTAssertEqual(flag, "-d")
                    XCTAssertEqual(reason, "must be a number")
                } else {
                    XCTFail("Expected .invalidValue, got \(parseError)")
                }
            } else {
                XCTFail("Expected ParseError, got \(error)")
            }
        }
    }

    func testInvalidValue_zero() {
        XCTAssertThrowsError(try parseOverrides(["pomo", "-d", "0"])) { error in
            if let parseError = error as? ParseError {
                if case .invalidValue(let flag, let reason) = parseError {
                    XCTAssertEqual(flag, "-d")
                    XCTAssertEqual(reason, "must be positive")
                } else {
                    XCTFail("Expected .invalidValue, got \(parseError)")
                }
            } else {
                XCTFail("Expected ParseError, got \(error)")
            }
        }
    }

    func testInvalidValue_negative() {
        XCTAssertThrowsError(try parseOverrides(["pomo", "-c", "-2"])) { error in
            if let parseError = error as? ParseError {
                if case .invalidValue(let flag, let reason) = parseError {
                    XCTAssertEqual(flag, "-c")
                    XCTAssertEqual(reason, "must be positive")
                } else {
                    XCTFail("Expected .invalidValue, got \(parseError)")
                }
            } else {
                XCTFail("Expected ParseError, got \(error)")
            }
        }
    }

}
