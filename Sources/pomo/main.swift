// pomo - Terminal Pomodoro Timer
// Runs inside herdr with notification support

import Foundation

let args = CommandLine.arguments

func main() async {
    do {
        let overrides = try parseOverrides(args)
        let config = resolveConfig(overrides)

        notify(title: "Pomodoro starting", body: "Work session: \(config.duration) minutes", customSound: config.sound)

        for cycle in 1...config.cycles {
            let workElapsed = await runSegment(
                duration: config.duration,
                phase: "WORK",
                cycle: cycle,
                color: ANSI.colorGreen,
                onTimerComplete: {
                    notify(title: "Work complete", body: "Take a \(config.breakDuration)-minute break", customSound: config.sound)
                }
            )
            _ = workElapsed

            if cycle < config.cycles {
                notify(title: "Break starting", body: "\(config.breakDuration)-minute break")
                let breakElapsed = await runSegment(
                    duration: config.breakDuration,
                    phase: "BREAK",
                    cycle: cycle,
                    color: ANSI.colorBlue,
                    onTimerComplete: {
                        notify(title: "Break complete", body: "Start working when you are ready", customSound: config.sound)
                    }
                )
                _ = breakElapsed
            }
        }

        notify(title: "All cycles complete!", body: "\(config.cycles) pomodoro cycle(s) finished", customSound: config.sound)
        print("\n✅ All \(config.cycles) cycle(s) complete!")
        fflush(stdout)
    } catch {
        fputs("Error: \(error)\n", stderr)
        exit(1)
    }
}

await main()
