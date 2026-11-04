# pomo

A terminal Pomodoro timer written in Swift.

## Features

- Customizable work/break durations
- Multiple work cycles with break intervals
- Runs inside [herdr](https://github.com/ogilvieherdr/herdr) with notification support
- Falls back to terminal bell when not in herdr
- ANSI-colored countdown display
- Custom notification sound (MP3, WAV, AAC, FLAC, and more)
- Pause/resume timer with 'p' key
- Persistent configuration in ~/.config/pomo/config.json

![Pomodoro timer](Resources/timer.png)

## Usage

```bash
# Default 25-minute work session
pomo

# Custom duration (minutes)
pomo -d 15

# Multiple work cycles with breaks
pomo -c 3 -b 3

# Custom notification sound (any afplay-supported format)
pomo -s /path/to/chime.wav

# Multiple cycles with custom sound
pomo -c 3 -s ~/Sounds/pomo.mp3

# Pause/resume: press 'p' during any segment
# Skip to next segment: press 'c' during any segment
```

## Timer Controls

- **p / P** — Pause or resume the timer
- **c / C** — Skip to the next segment (or completion)

When paused, the timer shows a "PAUSED" indicator and the remaining time freezes. Press 'p' again to resume.

## Configuration

Persistent settings are stored in `~/.config/pomo/config.json`:

```json
{
  "duration": 25,
  "cycles": 1,
  "breakDuration": 5,
  "sound": "/path/to/chime.wav"
}
```

CLI flags override persisted values, which override built-in defaults.

Supports any format playable by afplay: MP3, WAV, AAC, FLAC, AIFF, CAF, OGG, MIDI, and more.

## Building

```bash
swift build -c release
```

## Testing

```bash
swift test
```
