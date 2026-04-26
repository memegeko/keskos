# Changelog

## 2026-04-26

This update turns the old single-action `rofi` prompt into the actual launcher flow the project was aiming for, and it makes the KDE install steps match that behavior more closely.

### What changed

- rebuilt the launcher around a Python provider backend while keeping the existing `rofi` surface
- fixed the main-page live query flow so apps, files, settings, calculator results, units, and web shortcuts appear while typing
- added an empty-result placeholder row so partial queries like `2+` do not close the launcher
- added the rest of the intended Meta-based shortcuts instead of only shipping `Meta+K`
- added a dedicated `KeskOS` Konsole profile and terminal color scheme
- made fresh terminal windows run a custom `Kesk OS` fastfetch preset automatically through a local shell wrapper
- changed the KDE setup path so panels are removed by default after backing up the current panel layout
- added a `kdotool`-backed Wayland window provider for the launcher
- kept the old `wmctrl` path for X11 sessions
- added launcher-side debug logging around Wayland window queries and activation
- added a best-effort installer step for `kdotool-bin` from the AUR
- added an optional system-branding step so apps that read `/etc/os-release` can report `Kesk OS`
- added an optional SDDM login screen theme that matches the `keskos` desktop style
- added a matching Plasma lock screen theme that installs through a local Look-and-Feel package
- added a matching KDE splash/loading screen with the `keskos` logo and bundled spinner
- tuned the SDDM and lock-screen layouts so they better match the rest of the `keskos` orange-on-black palette
- rebuilt the Quickshell HUD and wallpaper geometry so the desktop now matches the six-panel reference layout much more closely
- regenerated the shipped wallpaper PNGs from the new 4K SVG master and made wallpaper refreshes clear stale installed variants first
- refreshed the README and keybind docs so they match the real installed behavior

### Added

- `KEYBINDS.md`
- `configs/fastfetch/config.jsonc`
- `configs/fastfetch/logo.txt`
- `configs/konsole/KeskOS.colorscheme`
- `configs/konsole/KeskOS.profile`
- `configs/sddm/keskos/Main.qml`
- `configs/sddm/keskos/metadata.desktop`
- `configs/sddm/keskos/theme.conf`
- `configs/look-and-feel/com.keskos.desktop/metadata.json`
- `configs/look-and-feel/com.keskos.desktop/contents/lockscreen/LockScreen.qml`
- `configs/look-and-feel/com.keskos.desktop/contents/splash/Splash.qml`
- `scripts/setup-branding.sh`
- `scripts/setup-lockscreen.sh`
- `scripts/setup-sddm.sh`
- `scripts/setup-terminal.sh`
- `scripts/setup-window-tools.sh`

### Notes

- `Meta`, `Meta+K`, `Meta+T`, `Meta+Enter`, `Meta+N`, `Meta+W`, `Meta+Shift+K`, `Meta+Shift+Tab`, `Meta+Shift+S`, and `Meta+P` are now installer-owned `keskos` shortcuts
- Plasma panel state is backed up to `~/.config/plasma-org.kde.plasma.desktop-appletsrc.keskos.bak` before panel removal
- if `kdotool-bin` cannot be installed automatically, `Active Windows` still falls back cleanly instead of breaking the rest of the launcher
- the Wayland helper path is logged in `~/.cache/keskos/launcher-debug.log` when `KESKOS_LAUNCHER_DEBUG=1`
- LibreWolf theming now applies to every discovered profile under both the legacy `~/.librewolf` root and the newer XDG-style `~/.config/librewolf/librewolf` root
- optional system branding only changes the user-facing distro name fields; it keeps the Arch compatibility identifiers intact
- the optional login screen theme installs into `/usr/share/sddm/themes/keskos` and tracks the previously active theme in `~/.cache/keskos/sddm-previous-theme`
- the matching lock screen installs per-user in `~/.local/share/plasma/look-and-feel/com.keskos.desktop` and tracks the previous Look-and-Feel package in `~/.cache/keskos/previous-lookandfeel`
- the same local Look-and-Feel package now also owns the KDE splash screen and tracks the previous splash theme in `~/.cache/keskos/previous-ksplash-theme`
- the installer now has a shared Bash UI layer with a banner, grouped phases, selection summary, numbered progress steps, and a stronger completion screen
- `KESKOS_UI_STYLE=plain` and `NO_COLOR=1` now give a simpler fallback output without changing the install logic
- fixed the shared installer UI initialization so the guided installer no longer stops partway through under `set -u`
- Quickshell now uses tighter text styling, exact-ish reference-aligned panel anchors, segmented memory/network meters, and richer live helper data

## 2026-04-25

This update replaces the Eww-based HUD with Quickshell and makes the HUD optional during install.

It also adds an optional LibreWolf browser step so the browser can match the same Kesk OS black/orange surface without turning it into a required part of the install.

### What changed

- removed Eww as the widget system
- added Quickshell as the new Wayland HUD backend
- changed the installer so it asks whether HUD widgets should be installed
- split the install into two paths: full HUD mode or minimal mode
- rewrote the Quickshell layout in QML to match the wallpaper frame
- added Quickshell startup logging and resolution scaling

### Added

- `scripts/setup-quickshell.sh`
- `scripts/start-quickshell.sh`
- `scripts/setup-librewolf.sh`
- `configs/quickshell/main.qml`
- `configs/quickshell/widgets/system_status.qml`
- `configs/quickshell/widgets/core_modules.qml`
- `configs/quickshell/widgets/network.qml`
- `configs/quickshell/widgets/system_log.qml`
- `configs/quickshell/widgets/system_profile.qml`
- `configs/quickshell/widgets/memory.qml`
- `kesk-librewolf/chrome/userChrome.css`
- `kesk-librewolf/chrome/userContent.css`
- `kesk-librewolf/homepage/index.html`
- `kesk-librewolf/homepage/style.css`
- `kesk-librewolf/homepage/script.js`
- `kesk-librewolf/policies/policies.json`

### Browser layer

- added a second optional install prompt for the themed LibreWolf browser
- defaults to `No` when the user presses `Enter`
- installs LibreWolf with `paru`, `yay`, or `pacman` in that order when available
- bootstraps `yay-bin` automatically when no AUR helper is present and LibreWolf needs the AUR path
- drops an offline Kesk OS homepage into `/usr/share/kesk/browser-home/`
- installs LibreWolf policies without touching privacy-focused defaults like ad blocking
- detects an existing LibreWolf profile, backs up CSS and `user.js`, and then adds the Kesk OS theme layer
- keeps the rest of the installer running even if LibreWolf cannot be installed automatically
- the launcher browser entry now opens LibreWolf on the local Kesk homepage instead of falling back straight to Google
- changed LibreWolf profile seeding so it tries `CreateProfile` first and uses a bounded headless fallback to avoid hanging the installer
- rebuilt the LibreWolf homepage to match the larger CRT gateway mockup and replaced fake protection counters with live ad/tracker probe checks

### Removed

- the old Eww HUD flow
- the old Eww config files
- the old Eww startup helper path

### Kept on purpose

- `Meta+K` still opens the launcher
- wallpaper, rofi, and the KDE color scheme still work even when widgets are skipped
