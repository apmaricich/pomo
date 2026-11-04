import XCTest
import Foundation
@testable import pomo

final class HerdrTests: XCTestCase {

    func testIsInHerdr_falseWhenEnvNotSet() {
        unsetenv("HERDR_ENV")
        XCTAssertFalse(isInHerdr())
    }

    func testIsInHerdr_trueWhenEnvSet() {
        setenv("HERDR_ENV", "1", 1)
        defer { unsetenv("HERDR_ENV") }
        XCTAssertTrue(isInHerdr())
    }

    func testPlayCustomSound_withValidFile() {
        let testSound = Bundle.main.path(forResource: "test", ofType: "mp3")
            ?? "/System/Library/Sounds/Basso.aiff"

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["afplay", testSound]
        let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        task.standardOutput = out
        task.standardError = err

        try? task.run()
        task.waitUntilExit()
        try? out?.close()
        try? err?.close()
        XCTAssertEqual(task.terminationStatus, 0)
    }

    func testNotify_withCustomSound_inHerdr() {
        setenv("HERDR_ENV", "1", 1)
        defer { unsetenv("HERDR_ENV") }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["herdr", "notification", "show", "Test Notification",
                         "--sound", "custom", "--body", "Test body"]
        let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        task.standardOutput = out
        task.standardError = err

        try? task.run()
        task.waitUntilExit()
        try? out?.close()
        try? err?.close()
    }

    func testNotify_withCustomSound_notInHerdr() {
        unsetenv("HERDR_ENV")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["afplay", "/System/Library/Sounds/Basso.aiff"]
        let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        task.standardOutput = out
        task.standardError = err

        try? task.run()
        task.waitUntilExit()
        try? out?.close()
        try? err?.close()
    }

    func testNotify_defaultSound_inHerdr() {
        setenv("HERDR_ENV", "1", 1)
        defer { unsetenv("HERDR_ENV") }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["herdr", "notification", "show", "Test",
                         "--sound", "done", "--body", "Test body"]
        let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        task.standardOutput = out
        task.standardError = err

        try? task.run()
        task.waitUntilExit()
        try? out?.close()
        try? err?.close()
    }

    func testNotify_defaultSound_notInHerdr() {
        unsetenv("HERDR_ENV")

        let bell = Process()
        bell.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        bell.arguments = ["printf", "\u{7}"]
        let out = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        let err = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        bell.standardOutput = out
        bell.standardError = err

        try? bell.run()
        bell.waitUntilExit()
        try? out?.close()
        try? err?.close()
    }
}
