import XCTest
@testable import pomo

final class ParseArgumentsTests: XCTestCase {

    func testDefaultConfig() throws {
        let config = try parseArguments(["pomo"])
        XCTAssertEqual(config.duration, 25)
        XCTAssertEqual(config.cycles, 1)
        XCTAssertEqual(config.breakDuration, 5)
    }

    func testCustomDuration() throws {
        let config = try parseArguments(["pomo", "-d", "15"])
        XCTAssertEqual(config.duration, 15)
    }

    func testCustomCycles() throws {
        let config = try parseArguments(["pomo", "-c", "3"])
        XCTAssertEqual(config.cycles, 3)
    }

    func testCustomBreakDuration() throws {
        let config = try parseArguments(["pomo", "-b", "10"])
        XCTAssertEqual(config.breakDuration, 10)
    }

    func testAllCustomOptions() throws {
        let config = try parseArguments(["pomo", "-d", "20", "-c", "2", "-b", "3"])
        XCTAssertEqual(config.duration, 20)
        XCTAssertEqual(config.cycles, 2)
        XCTAssertEqual(config.breakDuration, 3)
    }

    func testLongFormFlags() throws {
        let config = try parseArguments(["pomo", "--duration", "30", "--cycles", "4", "--break", "8"])
        XCTAssertEqual(config.duration, 30)
        XCTAssertEqual(config.cycles, 4)
        XCTAssertEqual(config.breakDuration, 8)
    }

    func testUnknownFlag() {
        XCTAssertThrowsError(try parseArguments(["pomo", "-z", "5"])) { error in
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
        XCTAssertThrowsError(try parseArguments(["pomo", "-d"])) { error in
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
        XCTAssertThrowsError(try parseArguments(["pomo", "-d", "abc"])) { error in
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
        XCTAssertThrowsError(try parseArguments(["pomo", "-d", "0"])) { error in
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
        XCTAssertThrowsError(try parseArguments(["pomo", "-c", "-2"])) { error in
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
