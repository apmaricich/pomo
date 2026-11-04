// pomo - Terminal Pomodoro Timer
// Runs inside herdr with notification support

import Foundation

let args = CommandLine.arguments

func main() async {
    do {
        let config = try parseArguments(args)

        notify(title: "Pomodoro starting", body: "Work session: \(config.duration) minutes")

        for cycle in 1...config.cycles {
            let workElapsed = await runSegment(
                duration: config.duration,
                phase: "WORK",
                cycle: cycle,
                color: ANSI.colorGreen
            )
            _ = workElapsed

            notify(title: "Work complete", body: "Take a \(config.breakDuration)-minute break")

            if cycle < config.cycles {
                let breakElapsed = await runSegment(
                    duration: config.breakDuration,
                    phase: "BREAK",
                    cycle: cycle,
                    color: ANSI.colorBlue
                )
                _ = breakElapsed
            }
        }

        notify(title: "All cycles complete!", body: "\(config.cycles) pomodoro cycle(s) finished")
        print("\n✅ All \(config.cycles) cycle(s) complete!")
        fflush(stdout)
    } catch {
        fputs("Error: \(error)\n", stderr)
        exit(1)
    }
}

await main()
