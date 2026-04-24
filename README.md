# keskos

`keskos` is a barebones Arch Linux KDE Plasma rice that turns the desktop into a dark orange terminal HUD. It keeps Plasma usable as a normal desktop, but replaces the visual layer with a centered command launcher, a resolution-aware retro wallpaper, subtle CRT texture, and a live Conky overlay that sits inside the wallpaper HUD boxes.

The target feel is:

- black background
- accent orange `#ce6a35`
- subtle glow, scanlines, and grain
- small centered `rofi` launcher
- no gaming stack
- no full-screen dashboard
- recoverable KDE setup with panel auto-hide instead of panel deletion

## Supported System

`keskos` is built for:

- Arch Linux
- KDE Plasma 5 or 6
- VM-first testing
- user-local installation

It is a desktop customization only. It does not build a custom OS.

## What The Project Installs

The installer keeps dependencies minimal and uses:

- `rofi`
- `picom`
- `feh`
- `konsole`
- `dolphin`
- `fastfetch`
- `conky`
- `lm_sensors`
- `iproute2`
- `procps-ng`
- `xorg-xrandr`
- `xorg-xsetroot`
- `ttf-jetbrains-mono-nerd`

It also installs:

- the `KESKOS` KDE color scheme
- a small centered `rofi` launcher bound to `Meta+K`
- SVG and PNG wallpaper assets
- resolution-aware Conky HUD profiles for `1080p`, `1440p`, and `4K`
- autostart helpers for wallpaper, Conky, and picom

## Install

```bash
git clone <your-repo-url> keskos
cd keskos
chmod +x install.sh
./install.sh
```

The installer:

- checks that `pacman` exists
- fails clearly when not on Arch
- refuses to run as root
- uses `sudo` only for `pacman -S --needed`
- creates the needed user-local directories
- copies configs into your home directory
- backs up KDE config files before editing them when possible
- installs the color scheme into `~/.local/share/color-schemes/KESKOS.colors`
- applies the wallpaper, color scheme, launcher shortcut, and HUD
- attempts to switch existing Plasma panels to auto-hide
- safely restarts `plasmashell`

When it finishes, it prints:

```text
KESKOS HUD installed. Log out and back in, then press Meta+K.
```

## Launcher

The main launcher is a compact centered `rofi` prompt with:

```text
KESK >
```

You can test it directly with:

```bash
~/.local/bin/keskos-launcher
```

By default it exposes:

- terminal
- files
- browser
- settings
- app search
- fastfetch
- logout
- reboot
- shutdown

The intended shortcut is:

- `Meta+K`

If automatic binding fails, set it manually:

1. Open `System Settings`
2. Go to `Keyboard`
3. Open `Shortcuts`
4. Search for `KESKOS Launcher`
5. Bind it to `Meta+K`

## HUD And Conky

`keskos` uses Conky as a live transparent HUD layer instead of Plasma widgets. The wallpaper supplies the orange frame and labeled empty boxes, and Conky fills those boxes with live text.

The HUD boxes are:

- `SYSTEM STATUS`
- `CORE MODULES`
- `NETWORK`
- `SYSTEM LOG`
- `QUICK ACCESS`
- `MEMORY`

The center title stays in the wallpaper so Conky does not have to fight the layout.

### How Conky Works

- The repo ships `configs/conky/keskos-1080p.conf`
- The repo ships `configs/conky/keskos-1440p.conf`
- The repo ships `configs/conky/keskos-4k.conf`
- `scripts/select-resolution-profile.sh` picks the closest profile by screen width
- The selected profile is copied to `~/.config/conky/keskos.conf`
- `~/.local/bin/keskos-start-conky` re-selects the profile on login, waits a few seconds for Plasma to settle, and then launches Conky

Resolution selection works like this:

- width `>= 3840` uses the `4K` profile
- width `>= 2560` uses the `1440p` profile
- everything else uses the `1080p` profile

To restart the HUD manually:

```bash
pkill -f 'conky.*keskos.conf' || true
~/.local/bin/keskos-start-conky
```

To force the current resolution profile again:

```bash
~/.local/bin/keskos-select-resolution-profile
cat ~/.config/conky/keskos.env
```

To disable Conky autostart:

```bash
rm -f ~/.config/autostart/keskos-conky.desktop
```

## Wallpaper

The main wallpaper source is:

- `assets/wallpaper.svg`

The repo also ships generated raster variants for cleaner KDE scaling on common screens:

- `assets/wallpaper-1920x1080.png`
- `assets/wallpaper-2560x1440.png`
- `assets/wallpaper-4096x2160.png`

The wallpaper helper prefers the closest PNG first, then falls back to the SVG. It also sets a black `xsetroot` fallback on X11 to reduce white background flashes.

To re-apply the wallpaper manually:

```bash
~/.local/bin/keskos-wallpaper-apply
```

If you want to set it from KDE by hand:

1. Open `System Settings`
2. Go to `Wallpaper`
3. Choose one of the installed files from `~/.local/share/keskos/assets/`
4. Use a fill or crop mode that covers the whole screen

## KDE Theme And Panel

The custom color scheme lives in:

- `configs/kde/keskos.colors`

During install it is copied to:

- `~/.local/share/color-schemes/KESKOS.colors`

The installer then tries to apply it with KDE tools and direct config writes. If that fails, it falls back to `Breeze Dark`.

The installer also tries to set `JetBrainsMono Nerd Font` as the main KDE UI and fixed font where supported.

`keskos` never deletes Plasma panels. It only attempts to switch them to auto-hide.

If panel auto-hide does not apply automatically:

1. Right click the panel
2. Choose `Enter Edit Mode`
3. Open `More Options`
4. Set `Visibility` to `Auto Hide`

## Desktop Icons

This project does not aggressively rewrite Plasma desktop containment just to hide icons, because that is more invasive and easier to break than the rest of the rice.

If you want a cleaner desktop manually:

1. Right click the desktop
2. Open `Configure Desktop and Wallpaper`
3. Switch away from a folder-view style containment if your Plasma setup exposes desktop icons there
4. Or remove icons from the desktop folder view manually

## Picom

`picom` is included only as an optional extra for lightweight polish:

- subtle shadows
- basic fading
- no heavy blur
- no click-blocking overlay

On modern KDE Plasma sessions, `keskos` skips `picom` by default because KWin already handles compositing. This avoids duplicate window trails, repaint glitches, and lag in VMs.

If you want to test `picom` manually anyway:

```bash
KESKOS_FORCE_PICOM=1 ~/.local/bin/keskos-picom-start
```

If windows smear, duplicate, or leave trails while moving:

```bash
pkill picom
```

## VM Notes

- Test in an Arch KDE VM first
- Snapshot before running the installer if possible
- X11 gives the most predictable `rofi`, `picom`, and root-background behavior
- The HUD and wallpaper still make sense on Wayland, but Conky stacking behavior can vary depending on the Plasma session

## Known Limitations

- Conky works best on X11; Wayland support depends on the session and XWayland behavior
- The HUD uses width-based profile selection, so unusual multi-monitor layouts may need a manual rerun of `~/.local/bin/keskos-select-resolution-profile`
- `SYSTEM LOG` uses `journalctl` when available; if access is limited it falls back to harmless status lines
- Desktop icons are not force-disabled automatically for safety reasons
- Plasma wallpaper handling is not perfectly identical across every Plasma release, which is why `keskos` ships both SVG and PNG assets
- Running `picom` on top of Plasma's own compositor can cause trails or ghosting, so `keskos` disables it by default on KDE and in VMs

## Manual Reset

Reset wallpaper:

1. Open `System Settings`
2. Go to `Wallpaper`
3. Choose another wallpaper or solid color

Reset panel visibility:

1. Right click the panel
2. Enter `Edit Mode`
3. Set `Visibility` back to `Always Visible`

Reset the launcher shortcut:

1. Open `System Settings`
2. Go to `Keyboard`
3. Open `Shortcuts`
4. Search for `KESKOS Launcher`
5. Remove or replace the `Meta+K` binding

Stop the HUD for the current session:

```bash
pkill -f 'conky.*keskos.conf'
```
