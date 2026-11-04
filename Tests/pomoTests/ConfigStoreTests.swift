import XCTest
import Foundation
@testable import pomo

final class ConfigStoreTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Create a custom config directory
        try FileManager.default.createDirectory(at: tempDir.appendingPathComponent(".config").appendingPathComponent("pomo"),
                                                withIntermediateDirectories: true)

        // Override the home directory for this test
        setenv("HOME", tempDir.path, 1)
    }

    override func tearDownWithError() throws {
        unsetenv("HOME")
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testLoadConfig_noConfigFile_returnsDefaults() {
        let config = loadConfig()
        XCTAssertEqual(config.duration, 25)
        XCTAssertEqual(config.cycles, 1)
        XCTAssertEqual(config.breakDuration, 5)
        XCTAssertNil(config.sound)
    }

    func testLoadConfig_validConfigFile_parsesCorrectly() {
        let configDir = tempDir
            .appendingPathComponent(".config")
            .appendingPathComponent("pomo")
        let configPath = configDir.appendingPathComponent("config.json")

        let json = """
        {
            "duration": 20,
            "cycles": 3,
            "breakDuration": 5,
            "sound": "custom"
        }
        """
        try? json.data(using: .utf8)?.write(to: configPath)

        let config = loadConfig()
        XCTAssertEqual(config.duration, 20)
        XCTAssertEqual(config.cycles, 3)
        XCTAssertEqual(config.breakDuration, 5)
        XCTAssertEqual(config.sound, "custom")
    }

    func testLoadConfig_invalidJSON_returnsDefaults() {
        let configDir = tempDir
            .appendingPathComponent(".config")
            .appendingPathComponent("pomo")
        let configPath = configDir.appendingPathComponent("config.json")

        try? Data("not valid json".utf8).write(to: configPath)

        let config = loadConfig()
        XCTAssertEqual(config.duration, 25)
        XCTAssertEqual(config.cycles, 1)
        XCTAssertEqual(config.breakDuration, 5)
        XCTAssertNil(config.sound)
    }

    func testLoadConfig_partialConfig_usesDefaultsForMissing() {
        let configDir = tempDir
            .appendingPathComponent(".config")
            .appendingPathComponent("pomo")
        let configPath = configDir.appendingPathComponent("config.json")

        let json = """
        {
            "duration": 15
        }
        """
        try? json.data(using: .utf8)?.write(to: configPath)

        let config = loadConfig()
        XCTAssertEqual(config.duration, 15)
        XCTAssertEqual(config.cycles, 1)
        XCTAssertEqual(config.breakDuration, 5)
        XCTAssertNil(config.sound)
    }

    func testSaveConfig_createsDirectoryAndWritesValidJSON() {
        saveConfig(Config(duration: 25, cycles: 1, breakDuration: 5, sound: nil))

        let configDir = tempDir
            .appendingPathComponent(".config")
            .appendingPathComponent("pomo")
        let configPath = configDir.appendingPathComponent("config.json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: configPath.path))

        let config = loadConfig()
        XCTAssertEqual(config.duration, 25)
        XCTAssertEqual(config.cycles, 1)
        XCTAssertEqual(config.breakDuration, 5)
        XCTAssertNil(config.sound)
    }

    func testSaveConfig_allFieldsSet() {
        saveConfig(Config(duration: 30, cycles: 4, breakDuration: 8, sound: "my-sound"))

        let config = loadConfig()
        XCTAssertEqual(config.duration, 30)
        XCTAssertEqual(config.cycles, 4)
        XCTAssertEqual(config.breakDuration, 8)
        XCTAssertEqual(config.sound, "my-sound")
    }

    func testSaveConfig_soundNil_omitsSoundKey() {
        saveConfig(Config(duration: 25, cycles: 1, breakDuration: 5, sound: nil))

        let configDir = tempDir
            .appendingPathComponent(".config")
            .appendingPathComponent("pomo")
        let configPath = configDir.appendingPathComponent("config.json")

        let contents = try? String(contentsOf: configPath, encoding: .utf8)
        XCTAssertFalse(contents?.contains("\"sound\"") == true)
    }
}
