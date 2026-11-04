import XCTest
import Foundation
@testable import pomo

/// Tests for pause/resume functionality.
///
/// The runSegment function depends on TTY stdin via readChar(), making true
/// interactive testing difficult in the test suite. These tests cover:
/// 1. The paused display rendering (what the user sees when paused)
/// 2. Correct elapsed/remaining time formatting during pause
/// 3. The paused vs. running display difference
///
/// The core pause/resume logic in runSegment is straightforward:
/// - paused flag toggles on 'p' keypress
/// - elapsed only advances when !paused
/// - the display switches between renderTimer and renderPaused

final class PauseResumeTests: XCTestCase {

    private var outputFile: URL!
    private var originalStdout: Int32!

    override func setUp() {
        super.setUp()
        outputFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("pomo_test_output_\(ProcessInfo.processInfo.processIdentifier)")

        // Redirect stdout to a file
        originalStdout = dup(STDOUT_FILENO)
        let fd = open(outputFile.path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        dup2(fd, STDOUT_FILENO)
        close(fd)
        fflush(stdout)
    }

    override func tearDown() {
        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)

        if FileManager.default.fileExists(atPath: outputFile.path) {
            try? FileManager.default.removeItem(atPath: outputFile.path)
        }

        super.tearDown()
    }

    private func capturedOutput() -> String {
        return (try? String(contentsOfFile: outputFile.path, encoding: .utf8)) ?? ""
    }

    // MARK: - Paused State Rendering

    func testRenderPaused_showsPausedIndicator() {
        renderPaused(elapsed: 10, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("PAUSED"))
    }

    func testRenderPaused_showsResumeHint() {
        renderPaused(elapsed: 10, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("[p] resume"))
    }

    func testRenderPaused_showsSkipHint() {
        renderPaused(elapsed: 10, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("[c] skip"))
    }

    func testRenderPaused_showsElapsedTime() {
        renderPaused(elapsed: 150, total: 1500, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        // Elapsed should show 02:30 (150 seconds)
        XCTAssertTrue(output.contains(formatTime(150)))
    }

    func testRenderPaused_showsRemainingTime() {
        renderPaused(elapsed: 300, total: 1500, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        let remaining = 1500 - 300
        XCTAssertTrue(output.contains("remaining:"))
        XCTAssertTrue(output.contains(formatTime(remaining)))
    }

    func testRenderPaused_showsPhase() {
        renderPaused(elapsed: 10, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("WORK"))
    }

    func testRenderPaused_showsCycle() {
        renderPaused(elapsed: 10, total: 60, phase: "WORK", cycle: 3, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("cycle 3"))
    }

    func testRenderPaused_breakPhase() {
        renderPaused(elapsed: 60, total: 300, phase: "BREAK", cycle: 2, color: ANSI.colorBlue)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("BREAK"))
        XCTAssertTrue(output.contains("PAUSED"))
    }

    // MARK: - Running vs Paused Display

    func testRunningShowsPauseHint() {
        renderTimer(elapsed: 10, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("[p] pause"))
        XCTAssertFalse(output.contains("PAUSED"))
    }

    func testPausedShowsResumeHint() {
        renderPaused(elapsed: 10, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("[p] resume"))
        XCTAssertTrue(output.contains("PAUSED"))
    }

    func testPausedAndRunningShareSameElapsedAndRemaining() {
        let elapsed = 90
        let total = 300
        let phase = "WORK"
        let cycle = 1
        let color = ANSI.colorGreen

        renderTimer(elapsed: elapsed, total: total, phase: phase, cycle: cycle, color: color)
        let running = capturedOutput()

        renderPaused(elapsed: elapsed, total: total, phase: phase, cycle: cycle, color: color)
        let paused = capturedOutput()

        // Both should show the same elapsed time
        XCTAssertTrue(running.contains(formatTime(elapsed)))
        XCTAssertTrue(paused.contains(formatTime(elapsed)))

        // Both should show the same remaining time
        let remaining = total - elapsed
        XCTAssertTrue(running.contains(formatTime(remaining)))
        XCTAssertTrue(paused.contains(formatTime(remaining)))
    }

    // MARK: - Edge Cases

    func testPauseAtZeroElapsed() {
        renderPaused(elapsed: 0, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("PAUSED"))
        XCTAssertTrue(output.contains(formatTime(60)))  // Full remaining
    }

    func testPauseAtLastSecond() {
        renderPaused(elapsed: 59, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("PAUSED"))
        XCTAssertTrue(output.contains(formatTime(1)))   // 1 second remaining
    }

    func testPauseAtCompletion() {
        renderPaused(elapsed: 60, total: 60, phase: "WORK", cycle: 1, color: ANSI.colorGreen)
        let output = capturedOutput()
        XCTAssertTrue(output.contains("PAUSED"))
        XCTAssertTrue(output.contains(formatTime(0)))   // 0 seconds remaining
    }
}
