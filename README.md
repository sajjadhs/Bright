# bright

Change your monitor brightness from the Windows command line — laptop screen **and** external monitors, with one command.

```
bright 30
```

Windows only lets you change the laptop screen from its settings. External monitors usually need their physical buttons. `bright` controls both: the laptop screen through WMI, and external monitors through DDC/CI (the same channel the monitor's own menu uses). No install, no background app, no dependencies — just one PowerShell script.

## Usage

| Command | What it does |
|---|---|
| `bright` | Show the current brightness of every monitor. |
| `bright 30` | Set every monitor to 30 %. |
| `bright +10` | Make every monitor 10 % brighter. |
| `bright -10` | Make every monitor 10 % darker. |
| `bright 50 laptop` | Change only the laptop screen. |
| `bright 50 ext` | Change only external monitors. |

It works in PowerShell, Command Prompt and the Win+R Run box.

## Install

1. Clone or download this repository.
2. Add the folder to your `Path` environment variable.
3. Open a new terminal and type `bright`.

## Requirements

- Windows 10 or 11.
- For external monitors, DDC/CI must be turned on in the monitor's on-screen menu. Most monitors have it on by default.

## License

MIT
