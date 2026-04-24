# keskos

`keskos` is an Arch Linux KDE Plasma rice that turns the desktop into a Wayland-friendly retro terminal HUD. The desktop stays recoverable and usable, but the visible layer becomes a black and orange machine interface with a centered `rofi` launcher, a HUD wallpaper, and a live Eww overlay that matches the wallpaper boxes.

The target feel is:

- black background
- orange accent `#ce6a35`
- subtle CRT scanlines and grain baked into the wallpaper
- small centered launcher
- no colorful dashboard
- no gaming stack
- no Conky
- Wayland-compatible HUD windows using Eww

## Supported System

`keskos` targets:

- Arch Linux
- KDE Plasma on Wayland
- user-local installation
- VM-first testing

It is a desktop customization only. It does not build a custom OS.

## What It Installs

Runtime packages:

- `rofi`
- `konsole`
- `dolphin`
- `fastfetch`
- `jq`
- `lm_sensors`
- `procps-ng`
- `iproute2`
- `ttf-jetbrains-mono-nerd`

Build and Eww runtime packages:

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

The installer builds `eww` from the official upstream source with Wayland enabled:

```bash
cargo build --release --no-default-features --features=wayland
```

By default the build uses official tag `v0.6.0`. You can override that for testing with:

```bash
KESKOS_EWW_REF=<tag> ./install.sh
```

## Repo Layout

Important project files:

- `install.sh`
- `CHANGELOG.md`
- `scripts/setup-eww.sh`
- `scripts/start-eww.sh`
- `scripts/select-resolution.sh`
- `configs/eww/eww.yuck`
- `configs/eww/eww.scss`
- `configs/eww/widgets/`
- `assets/wallpaper.svg`

## Install

```bash
git clone https://github.com/memegeko/keskos.git
cd keskos
chmod +x install.sh
./install.sh
```

The installer:

- checks that `pacman` exists
- fails clearly when not on Arch
- refuses to run as root
- uses `sudo` only for `pacman`
- installs runtime and Eww build dependencies
- copies the Eww config into `~/.config/eww/`
- copies helper scripts into `~/.local/bin/`
- removes old Conky startup files from earlier `keskos` installs
- applies the wallpaper
- applies the KDE color scheme
- attempts to set Plasma panels to auto-hide
- safely restarts `plasmashell`

When it finishes, it prints:

```text
KESKOS EWW HUD installed. Log out and back in.
```

## Changelog

Recent project history lives in:

- `CHANGELOG.md`

The current update replaces the old Conky HUD with an Eww-based Wayland HUD and removes the earlier picom-based overlay path.

## Launcher

The launcher stays as the same compact centered `rofi` prompt:

```text
KESK >
```

You can test it directly with:

```bash
~/.local/bin/keskos-launcher
```

The intended shortcut is:

- `Meta+K`

If automatic binding fails:

1. Open `System Settings`
2. Go to `Keyboard`
3. Open `Shortcuts`
4. Search for `KESKOS Launcher`
5. Bind it to `Meta+K`

## Eww HUD

`keskos` now uses Eww instead of Conky.

The live widgets are placed to match the wallpaper frame:

- left top: `SYSTEM STATUS`
- left middle: `CORE MODULES`
- left bottom: `NETWORK`
- right top: `SYSTEM LOG`
- right middle: `SYSTEM PROFILE`
- right bottom: `MEMORY`

The center remains clean so the wallpaper title can stay untouched.

### How It Works

- `~/.local/bin/keskos-start-eww` starts the Eww daemon and opens the HUD
- `~/.local/bin/keskos-select-resolution` detects the screen width and applies the closest layout profile
- `~/.local/bin/keskos-eww-data` provides JSON data for Eww polling variables
- `~/.config/autostart/keskos-eww.desktop` starts the HUD on login

### Restart The HUD

```bash
~/.local/bin/keskos-start-eww
```

If you want to fully stop it:

```bash
eww --config ~/.config/eww close-all
eww --config ~/.config/eww kill
```

If the local binary was built into `~/.local/bin/eww`, that path takes precedence automatically.

### Disable Eww Autostart

```bash
rm -f ~/.config/autostart/keskos-eww.desktop
```

## Resolution Handling

`scripts/select-resolution.sh` chooses one of three layout profiles:

- width `>= 3840` -> `4K`
- width `>= 2560` -> `1440p`
- otherwise -> `1080p`

The selector updates:

- panel sizes
- panel heights
- margins
- row spacing
- profile class used by `eww.scss`

You can rerun it manually:

```bash
~/.local/bin/keskos-select-resolution
cat ~/.config/eww/keskos-layout.env
```

## Wallpaper

The main editable wallpaper source is:

- `assets/wallpaper.svg`

The repo also ships raster variants:

- `assets/wallpaper-1920x1080.png`
- `assets/wallpaper-2560x1440.png`
- `assets/wallpaper-4096x2160.png`

The wallpaper helper prefers the closest PNG and falls back to the SVG. On KDE it tries `plasma-apply-wallpaperimage` first, then Plasma scripting, and keeps a black Plasma wallpaper fallback if those wallpaper helpers are unavailable.

To apply the wallpaper manually:

```bash
~/.local/bin/keskos-wallpaper-apply
```

## KDE Theme And Panels

The custom color scheme lives in:

- `configs/kde/keskos.colors`

It is installed to:

- `~/.local/share/color-schemes/KESKOS.colors`

`keskos` never deletes Plasma panels. It only attempts to switch them to auto-hide.

If panel auto-hide does not apply automatically:

1. Right click the panel
2. Choose `Enter Edit Mode`
3. Open `More Options`
4. Set `Visibility` to `Auto Hide`

## Manual Wallpaper Or HUD Recovery

Reset wallpaper manually:

1. Open `System Settings`
2. Go to `Wallpaper`
3. Choose another wallpaper or solid color

Stop the HUD:

```bash
eww --config ~/.config/eww close-all
eww --config ~/.config/eww kill
```

Remove Eww autostart:

```bash
rm -f ~/.config/autostart/keskos-eww.desktop
```

## Known Limitations

- Plasma Wayland layer-shell behavior can differ slightly between Plasma releases
- The HUD is designed to stay non-focusable and desktop-like, so it is opened on the bottom layer to avoid blocking interaction
- `journalctl` output may vary by system; when access fails, `keskos` falls back to harmless machine-style status lines
- Multi-monitor setups may need a manual rerun of `~/.local/bin/keskos-select-resolution`
- Desktop icons are not force-disabled automatically for safety reasons

## VM Notes

- Test in an Arch KDE VM first
- Snapshot before install when possible
- Wayland is the intended test path for this revision of `keskos`
- If the HUD looks offset after changing resolution, rerun `~/.local/bin/keskos-select-resolution` and restart Eww
