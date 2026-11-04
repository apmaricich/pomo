# AGENTS.md — pomo

A terminal Pomodoro timer written in Swift. Runs inside [herdr](https://github.com/ogilvieherdr/herdr) and uses herdr's notification system when a session completes. Falls back to the terminal bell when not in herdr.

## Building

```bash
swift build -c debug      # Debug build
swift build -c release    # Release build
```

## Running

```bash
swift run -c release pomo                # 25-min work session
swift run -c release pomo -d 15           # Custom duration
swift run -c release pomo -c 3            # 3 cycles with breaks
swift run -c release pomo -b 3            # 3-min break
swift run -c release pomo --help
```

## Testing

```bash
swift test                         # Run all tests
swift test --filter SomeTest       # Run a specific test
```

## Linting

```bash
swiftlint lint                     # Run SwiftLint
swiftlint lint --fix               # Auto-fix where possible
```

## Coding Standards

**Error handling:**
- Use `Result` for operations that can fail.
- Prefer throwing functions over optional returns.
- Use `try?` only for truly optional operations.

**Concurrency:**
- Use Swift's structured concurrency: `async/await`.
- Use `Task {}` for spawning work.
- Use `TaskGroup` for parallel work.
- Avoid completion handlers.

**Types and access control:**
- Prefer value types (`struct`) over reference types (`class`).
- Use access control (`private`, `internal`, `public`) appropriately.
- Document public APIs with doc comments.
- Use explicit types where clarity improves readability.

**Naming:**
- `camelCase` for variables and functions.
- `PascalCase` for types.

**Terminal output:**
- Use ANSI escape codes for colors and formatting.
- Flush stdout after writes (`fflush(stdout)` or equivalent).
- Use `\r` for in-place line overwriting (countdown display).
- Use `\n` for new lines.

**herdr integration:**
- Check `HERDR_ENV` to detect if running in herdr.
- Use `herdr notification show <title> --body <text> --sound done` when a session completes.
- Fallback to terminal bell (`\a`) if not in herdr.

## Project Structure

```
pomo/
├── Package.swift
├── Sources/
│   └── pomo/
│       ├── main.swift          # Entry point, CLI parsing
│       ├── Timer.swift         # Countdown logic
│       └── Herdr.swift         # herdr integration
├── Tests/
│   └── pomoTests/
├── .swiftlint.yml
├── AGENTS.md
└── README.md
```

## Development Notes

- This is a CLI-only project using Swift Package Manager, not an Xcode project.
- The timer uses ANSI escape codes to display the countdown in place.
- When running inside herdr, completion notifications use herdr's system; otherwise the terminal bell is used.
