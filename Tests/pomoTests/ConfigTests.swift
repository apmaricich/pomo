import XCTest
@testable import pomo

final class ConfigTests: XCTestCase {

    func testConfigStruct() {
        let config = Config(duration: 20, cycles: 3, breakDuration: 5, sound: nil)
        XCTAssertEqual(config.duration, 20)
        XCTAssertEqual(config.cycles, 3)
        XCTAssertEqual(config.breakDuration, 5)
    }

    func testParseOverrides_noFlags_allNil() throws {
        let overrides = try parseOverrides(["pomo"])
        XCTAssertNil(overrides.duration)
        XCTAssertNil(overrides.cycles)
        XCTAssertNil(overrides.breakDuration)
        XCTAssertNil(overrides.sound)
    }

    func testParseOverrides_withDurationFlag() throws {
        let overrides = try parseOverrides(["pomo", "-d", "15"])
        XCTAssertEqual(overrides.duration, 15)
    }

    func testParseOverrides_withSoundFlag() throws {
        let overrides = try parseOverrides(["pomo", "-s", "/path/to/sound.mp3"])
        XCTAssertEqual(overrides.sound, "/path/to/sound.mp3")
    }

    func testParseOverrides_withMultipleFlags() throws {
        let overrides = try parseOverrides(["pomo", "-d", "15", "-c", "3", "-b", "5"])
        XCTAssertEqual(overrides.duration, 15)
        XCTAssertEqual(overrides.cycles, 3)
        XCTAssertEqual(overrides.breakDuration, 5)
    }

    func testResolveConfig_noOverrides_usesDefaults() throws {
        let overrides = try parseOverrides(["pomo"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.duration, 25)
        XCTAssertEqual(config.cycles, 1)
        XCTAssertEqual(config.breakDuration, 5)
    }

    func testResolveConfig_withCLOverrides() throws {
        let overrides = try parseOverrides(["pomo", "-d", "15", "-c", "3", "-b", "5"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.duration, 15)
        XCTAssertEqual(config.cycles, 3)
        XCTAssertEqual(config.breakDuration, 5)
    }

    func testResolveConfig_withSoundOverride() throws {
        let overrides = try parseOverrides(["pomo", "-s", "my-sound"])
        let config = resolveConfig(overrides)
        XCTAssertEqual(config.sound, "my-sound")
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
