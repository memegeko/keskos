# keskos

`keskos` is a small KDE Plasma rice for Arch Linux. The idea is simple: keep Plasma usable, but make the desktop feel like a quiet orange machine console instead of a modern dashboard.

The current version is built around:

- KDE Plasma on Wayland
- a compact `rofi` launcher on `Meta+K`
- an Eww HUD that sits inside the wallpaper frame
- a custom orange-on-black KDE color scheme
- a setup that stays reversible and does not delete panels

If you want a desktop that feels like "future tech imagined in the 90s" without turning your system into a full custom distro, that is what this repo is for.

## What It Looks Like

The look is intentionally restrained:

- black background
- `#ce6a35` as the main accent
- subtle scanlines and grain baked into the wallpaper
- small centered launcher instead of a full-screen app menu
- live side panels for system info, memory, logs, and network status

The middle of the screen stays mostly clean so it still feels like a desktop, not a wall of widgets.

## Supported Setup

`keskos` is meant for:

- Arch Linux
- KDE Plasma
- Wayland

It is safest to test in a VM first.

This project does not replace your OS. It only installs user-level desktop customization and a few dependencies.

## Install

```bash
git clone https://github.com/memegeko/keskos.git
cd keskos
chmod +x install.sh
./install.sh
```

The installer will:

- verify that you are on Arch and that `pacman` exists
- refuse to run as root
- install the required runtime and build packages
- build `eww` locally with Wayland support
- copy the launcher, wallpaper, HUD config, and color scheme into your home directory
- try to switch existing Plasma panels to auto-hide
- restart `plasmashell` safely

When it finishes, you should see:

```text
KESKOS EWW HUD installed. Log out and back in.
```

## What Gets Installed

Runtime tools:

- `rofi`
- `konsole`
- `dolphin`
- `fastfetch`
- `jq`
- `lm_sensors`
- `procps-ng`
- `iproute2`
- `ttf-jetbrains-mono-nerd`

Build and Eww runtime dependencies:

- `git`
- `cargo`
- `base-devel`
- `gtk3`
- `gtk-layer-shell`
- `pango`
- `gdk-pixbuf2`
- `libdbusmenu-gtk3`
- `cairo`
- `glib2`
- `gcc-libs`

`eww` is built from upstream with:

```bash
cargo build --release --no-default-features --features=wayland
```

By default the installer uses upstream tag `v0.6.0`. If you want to test another tag:

```bash
KESKOS_EWW_REF=<tag> ./install.sh
```

## Launcher

The launcher is a compact `rofi` prompt with the prompt text:

```text
KESK >
```

Default shortcut:

- `Meta+K`

You can test it directly:

```bash
~/.local/bin/keskos-launcher
```

If the automatic shortcut binding does not stick:

1. Open `System Settings`
2. Go to `Keyboard`
3. Open `Shortcuts`
4. Search for `KESKOS Launcher`
5. Bind it to `Meta+K`

## HUD

The live HUD is handled by Eww, not Conky.

The wallpaper provides the frame, and Eww fills the frame with live text in these areas:

- top left: `SYSTEM STATUS`
- middle left: `CORE MODULES`
- bottom left: `NETWORK`
- top right: `SYSTEM LOG`
- middle right: `SYSTEM PROFILE`
- bottom right: `MEMORY`

The center stays empty on purpose so the wallpaper title remains readable.

Main HUD pieces:

- `scripts/setup-eww.sh`
- `scripts/start-eww.sh`
- `scripts/select-resolution.sh`
- `configs/eww/eww.yuck`
- `configs/eww/eww.scss`
- `configs/eww/widgets/`

## How The HUD Starts

On login:

- `~/.config/autostart/keskos-eww.desktop` runs `~/.local/bin/keskos-start-eww`
- that script starts the Eww daemon
- it reruns the resolution selector
- then it opens the main HUD window

To restart the HUD manually:

```bash
~/.local/bin/keskos-start-eww
```

To stop it:

```bash
eww --config ~/.config/eww close-all
eww --config ~/.config/eww kill
```

To disable autostart:

```bash
rm -f ~/.config/autostart/keskos-eww.desktop
```

## Resolution Handling

The layout is not hardcoded to one screen size.

`scripts/select-resolution.sh` chooses a profile based on screen width:

- `>= 3840` -> `4K`
- `>= 2560` -> `1440p`
- otherwise -> `1080p`

It adjusts panel width, spacing, offsets, and font sizing through Eww variables.

You can rerun it manually:

```bash
~/.local/bin/keskos-select-resolution
cat ~/.config/eww/keskos-layout.env
```

## Wallpaper

Main editable source:

- `assets/wallpaper.svg`

Generated raster variants:

- `assets/wallpaper-1920x1080.png`
- `assets/wallpaper-2560x1440.png`
- `assets/wallpaper-4096x2160.png`

The wallpaper helper prefers the closest PNG for the current screen and falls back to the SVG if needed.

To apply it manually:

```bash
~/.local/bin/keskos-wallpaper-apply
```

## KDE Theme And Panels

The color scheme is stored in:

- `configs/kde/keskos.colors`

It is installed to:

- `~/.local/share/color-schemes/KESKOS.colors`

`keskos` does not delete your Plasma panels. It only tries to switch them to auto-hide.

If auto-hide does not get applied automatically:

1. Right click the panel
2. Choose `Enter Edit Mode`
3. Open `More Options`
4. Set `Visibility` to `Auto Hide`

## Recovery

If you want to stop using the HUD for a while:

```bash
eww --config ~/.config/eww close-all
eww --config ~/.config/eww kill
rm -f ~/.config/autostart/keskos-eww.desktop
```

If you want to change the wallpaper back manually:

1. Open `System Settings`
2. Go to `Wallpaper`
3. Pick another wallpaper or solid color

## Notes

- Plasma Wayland layer-shell behavior can vary a little between Plasma versions
- the HUD is opened as a non-focusable desktop-like layer so it does not act like a normal app window
- `journalctl` output can differ across systems, so the log panel falls back to harmless status lines when needed
- multi-monitor setups may need a manual rerun of `~/.local/bin/keskos-select-resolution`
- desktop icons are not force-disabled automatically for safety

## VM First

Testing in a VM first is still the right move.

- snapshot before install if you can
- use an Arch KDE Wayland VM
- if the HUD looks offset after a resolution change, rerun `~/.local/bin/keskos-select-resolution` and restart Eww

## Changelog

Recent project history is in [CHANGELOG.md](CHANGELOG.md).
