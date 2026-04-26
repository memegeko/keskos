# keskos

`keskos` is a small Arch Linux KDE Plasma rice with a black/orange retro terminal feel.

The desktop stays recognizably Plasma, but the surface is pushed toward a quieter machine-console look:

- black background
- orange accent `#ce6a35`
- centered `rofi` launcher on `Meta` and `Meta+K`
- custom KDE color scheme
- optional Quickshell HUD on Wayland

The important part is that the HUD is optional now.

If you want the wallpaper, launcher, and theme only, you can install `keskos` in minimal mode and skip widgets completely.

## Supported Setup

`keskos` is built for:

- Arch Linux
- KDE Plasma
- Wayland

Testing in a VM first is still the safest path.

## Install

```bash
git clone https://github.com/memegeko/keskos.git
cd keskos
chmod +x install.sh
./install.sh
```

During install you will be asked:

```text
Install KeskOS HUD widgets? (y/n)
Do you want to install the Kesk OS themed LibreWolf browser? [y/N]
```

If you choose:

- `y` -> `keskos` installs Quickshell, the HUD config, and autostarts the HUD
- `n` -> `keskos` skips all widget setup and leaves you with a clean minimal desktop
- `y` at the LibreWolf prompt -> `keskos` installs LibreWolf when possible, adds the offline Kesk homepage, and themes the browser chrome
- `n` or pressing `Enter` at the LibreWolf prompt -> `keskos` skips all LibreWolf changes and keeps going

At the end it prints:

```text
KESKOS setup complete.
If widgets enabled: Quickshell HUD active.
```

or:

```text
KESKOS setup complete.
If disabled: running minimal mode.
```

You can also pre-answer the prompt:

```bash
KESKOS_INSTALL_WIDGETS=y ./install.sh
KESKOS_INSTALL_LIBREWOLF=y ./install.sh
```

## What Gets Installed

Base packages:

- `rofi`
- `konsole`
- `dolphin`
- `fastfetch`
- `ttf-jetbrains-mono-nerd`
- `python`
- `python-pyxdg`
- `wl-clipboard`
- `xclip`
- `wmctrl`

On Plasma Wayland, `keskos` also tries to install `kdotool-bin` from the AUR so `Active Windows` can stay inside the launcher instead of bouncing out to KDE's own window runner.

The install order is:

- `paru -S --needed --noconfirm kdotool-bin`
- `yay -S --needed --noconfirm kdotool-bin`
- if `yay` is missing, `keskos` tries to install `yay-bin` first and retries `kdotool-bin`

If that still fails, the install continues and `Active Windows` falls back to a KDE-native external runner path until `kdotool-bin` is installed manually.

If you enable the optional LibreWolf step, `keskos` tries this install order:

- `paru -S --needed --noconfirm librewolf-bin`
- `yay -S --needed --noconfirm librewolf-bin`
- if `yay` is missing, `keskos` installs `yay-bin` first and retries `librewolf-bin`
- `sudo pacman -S --needed --noconfirm librewolf`

If none of those work, the installer prints a warning and continues.

If you enable widgets, `keskos` also installs the Quickshell runtime and build dependencies it needs, including:

- `qt6-base`
- `qt6-declarative`
- `qt6-wayland`
- `qt6-5compat`
- `qt6-svg`
- `jq`
- `lm_sensors`
- `procps-ng`
- `iproute2`

If `quickshell` is not already available, `keskos` builds it from official upstream source and installs it into `~/.local`.

By default the source build tracks upstream `master`, which tends to be the safer choice on rolling Arch systems when Qt moves forward. If you want to pin a specific ref:

```bash
KESKOS_QUICKSHELL_REF=v0.2.1 ./install.sh
```

## Launcher

The launcher is still a compact centered `rofi` prompt:

```text
KESK >
```

Default shortcut:

- `Meta`
- `Meta+K`
- `Meta+T` or `Meta+Enter`
- `Meta+N`
- `Meta+W`
- `Meta+Shift+K`
- `Meta+Shift+Tab`
- `Meta+Shift+S`
- `Meta+P`
- the `browser` entry prefers LibreWolf and opens the local Kesk homepage when it is installed
- `Active Windows` stays inside the launcher on Wayland when `kdotool` is available

Full shortcut notes are in [KEYBINDS.md](KEYBINDS.md).

You can test the launcher directly:

```bash
~/.local/bin/keskos-launcher
```

The main launcher page now behaves more like a small KRunner-style command layer. You can type:

- app names like `dolphin` or `konsole`
- folders like `Downloads`
- settings like `display`
- math like `2+2`
- conversions like `10 cm to inch`
- web shortcuts like `gg kde plasma`

If a query is still incomplete, the launcher stays open and shows a small placeholder row instead of closing.

If shortcut binding does not apply automatically:

1. Open `System Settings`
2. Go to `Keyboard`
3. Open `Shortcuts`
4. Search for `KESKOS`
5. Rebind the matching `KESKOS` entry to the shortcut you want

## Quickshell HUD

If widgets are enabled, `keskos` installs a Quickshell overlay that matches the wallpaper layout:

- left top: `SYSTEM STATUS`
- left middle: `CORE MODULES`
- left bottom: `NETWORK`
- right top: `SYSTEM LOG`
- right middle: `SYSTEM PROFILE`
- right bottom: `MEMORY`

The center stays clear for the wallpaper title.

The HUD is:

- Wayland-first
- transparent
- non-focusable
- mouse click-through
- above normal windows

## Quickshell Files

Main files:

- `scripts/setup-quickshell.sh`
- `scripts/start-quickshell.sh`
- `scripts/select-resolution.sh`
- `configs/quickshell/main.qml`
- `configs/quickshell/widgets/`

The start script installed into your home directory is:

- `~/.local/bin/keskos-start-quickshell`

The data helper installed into your home directory is:

- `~/.local/bin/keskos-quickshell-data`

## Resolution Handling

`scripts/select-resolution.sh` detects the screen size and writes a small env file used by Quickshell.

Scaling rules:

- `4K` -> `1.5`
- `1440p` -> `1.2`
- `1080p` -> `1.0`

You can rerun it manually:

```bash
~/.local/bin/keskos-select-resolution
cat ~/.config/quickshell/keskos-resolution.env
```

## Wallpaper

Main editable wallpaper source:

- `assets/wallpaper.svg`

Raster variants:

- `assets/wallpaper-1920x1080.png`
- `assets/wallpaper-2560x1440.png`
- `assets/wallpaper-4096x2160.png`

To apply the wallpaper manually:

```bash
~/.local/bin/keskos-wallpaper-apply
```

The wallpaper helper prefers a matching PNG when possible and falls back to the SVG or a black Plasma background.

## KDE Theme And Panels

The color scheme lives in:

- `configs/kde/keskos.colors`

It is installed to:

- `~/.local/share/color-schemes/KESKOS.colors`

`keskos` now removes existing Plasma panels by default after backing up:

- `~/.config/plasma-org.kde.plasma.desktop-appletsrc.keskos.bak`

If you want the older behavior instead, run the installer with:

```bash
KESKOS_PANEL_MODE=autohide ./install.sh
```

If you want to restore the old panel layout manually:

1. Log out of Plasma
2. Replace `~/.config/plasma-org.kde.plasma.desktop-appletsrc` with the `.keskos.bak` copy
3. Log back in

## Logs And Debugging

If Quickshell is enabled, the startup log is written to:

```bash
~/.cache/keskos/quickshell.log
```

To restart the HUD manually:

```bash
~/.local/bin/keskos-start-quickshell
```

To stop the HUD:

```bash
pkill -x quickshell
```

Launcher debug log:

```bash
~/.cache/keskos/launcher-debug.log
```

To test the launcher with debug logging:

```bash
rm -f ~/.cache/keskos/launcher-debug.log
KESKOS_LAUNCHER_DEBUG=1 ~/.local/bin/keskos-launcher --mode main
sed -n '1,120p' ~/.cache/keskos/launcher-debug.log
```

To test the Wayland window helper directly:

```bash
kdotool search --limit 20 '.*'
kdotool getactivewindow
kdotool --debug search --limit 20 '.*'
```

## LibreWolf Browser Layer

If you answer `y` to the LibreWolf prompt, `keskos` installs a browser layer that matches the rest of the theme:

- dark browser chrome
- orange active tab and focus states
- compact toolbar spacing
- dark menus and sidebar
- offline custom homepage at `file:///usr/share/kesk/browser-home/index.html`
- live homepage probe cards for ad and tracker blocking instead of fake random counters

Repo sources for that layer live in:

- `kesk-librewolf/chrome/userChrome.css`
- `kesk-librewolf/chrome/userContent.css`
- `kesk-librewolf/homepage/index.html`
- `kesk-librewolf/homepage/style.css`
- `kesk-librewolf/homepage/script.js`
- `kesk-librewolf/policies/policies.json`

Installed system files go to:

- `/usr/share/kesk/browser-home/`
- `/usr/lib/librewolf/distribution/policies.json`

Profile-side theme files go to the detected LibreWolf profile under:

- `~/.librewolf/*/chrome/userChrome.css`
- `~/.librewolf/*/chrome/userContent.css`
- `~/.librewolf/*/user.js`
- `~/.config/librewolf/librewolf/*/chrome/userChrome.css`
- `~/.config/librewolf/librewolf/*/chrome/userContent.css`
- `~/.config/librewolf/librewolf/*/user.js`

`keskos` now themes every discovered LibreWolf profile it can find in the common Linux locations instead of touching only one guessed default profile.

It also installs `librewolf.overrides.cfg` into the common LibreWolf config roots so stylesheet support and homepage defaults survive across multiple profiles more reliably:

- `~/.librewolf/librewolf.overrides.cfg`
- `~/.config/librewolf/librewolf/librewolf.overrides.cfg`

Existing `userChrome.css`, `userContent.css`, and `user.js` files are backed up once as `*.keskos.bak` before `keskos` overwrites its own browser layer files.

To rerun just the browser setup:

```bash
bash scripts/setup-librewolf.sh "$PWD"
```

If you are installing for a different target user or a mounted target root, you can point the script at that location:

```bash
TARGET_USER=myuser TARGET_HOME=/home/myuser INSTALL_ROOT=/mnt bash scripts/setup-librewolf.sh "$PWD"
```

## Disable Widgets

If you installed the HUD and want to disable it later:

```bash
rm -f ~/.config/autostart/keskos-quickshell.desktop
pkill -x quickshell
```

You can also rerun `./install.sh` and answer `n` at the widget prompt.

## Minimal Mode

If you skip widgets, you still get:

- wallpaper setup
- KDE color scheme
- rofi launcher
- full Meta-based launcher shortcuts

## Known Limitations

- LibreWolf policy paths differ between packages. `keskos` installs policies to the common LibreWolf locations it can detect, but some custom package layouts may still need a manual copy.
- Current LibreWolf and Firefox builds do not reliably expose a clean policy for forcing every new tab to a local file homepage. `keskos` sets the startup homepage and themes `about:newtab`, but new tabs may still use LibreWolf's own new-tab page depending on version.
- The homepage protection counters are live probe-based estimates. They reflect whether the current browser/session blocks a set of known ad and tracker endpoints, not private internal extension totals.
- If no LibreWolf profile exists yet and profile creation fails, launch LibreWolf once manually and rerun `bash scripts/setup-librewolf.sh "$PWD"`.
- The installer now tries LibreWolf profile creation before a headless first run, and any fallback headless seeding is time-limited so it does not hang forever.
- If `INSTALL_ROOT` points at a mounted target instead of the live system root, `keskos` skips automatic LibreWolf package installation and profile creation on purpose so it does not install the browser into the wrong system.

## Notes

- Quickshell is built around Wayland layer-shell behavior, so Plasma version differences can still matter
- the HUD uses a click-through mask so it should not steal normal desktop input
- multi-monitor setups may need a manual rerun of `~/.local/bin/keskos-select-resolution`
- `keskos` now backs up the current panel layout before removing panels by default

## Changelog

Recent project history is in [CHANGELOG.md](CHANGELOG.md).
