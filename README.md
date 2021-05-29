# My widgets for AwesomeWM

![my-awesome-widgets](screenshot.png)

## Installation

1. Clone the repo to awesome config folder (usually `~/.config/awesome`).
2. Import module with widgets:
   ```lua
   local my_widgets = require("my-awesome-widgets")
   ```
3. Create desired widget (e.g. newpackages):
   ```lua
   newpackages = my_widgets.newpackages(<optional args in {}>)
   ```
4. Add widget to wibar.

## Battery status widget

`acpi` package is obligatory for this widget.

Optional arguments:
- `timeout`: widget update time in seconds, default is 30

## Clock widget

Just standard textclock widget with the icon and tooltip added.

## New packages widget

At the moment supports Arch Linux, Debian and Void Linux. Add the command for your distro to the `newpackages.conf` file if needed.

Optional arguments:
- `timeout`: widget update time in seconds, default is 900
- `distro`: Your distro ID, autodetected by default
- `config`: custom path to `newpackages.conf` file

Mouse actions:
- Left click: force update of the widget

## Volume widget

Supports both ALSA (via `amixer`) and PulseAudio (via `pactl`).

Optional arguments:
- `timeout`: widget update time in seconds, default is 5
- `daemon`: alsa or pulse, autodetected by default
- `device`: ALSA device or PulseAudio sink number, "Master" and "0" by default
- `step` : volume change step, default is 1
- `jump` : volume change bigger step, default is `step * 5`

Mouse actions:
- Right click: Toggle mute
- Wheel up/down: volume up/down
- Shift + wheel up/down: volume up/down, bigger step

