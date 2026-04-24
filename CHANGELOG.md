# Changelog

All notable changes to `keskos` are documented in this file.

## 2026-04-24

### Changed

- replaced the Conky HUD with an Eww-based HUD built for KDE Plasma Wayland
- updated the installer to build upstream `eww` from source with `--no-default-features --features=wayland`
- switched the HUD startup flow to `keskos-start-eww` and `keskos-select-resolution`
- updated the wallpaper pipeline to stay KDE/Wayland-focused and prefer resolution-matched wallpaper assets
- refreshed the wallpaper layout so the right-middle panel is labeled `SYSTEM PROFILE`
- rewrote the README for the Eww/Wayland workflow, resolution handling, recovery steps, and autostart behavior

### Added

- `configs/eww/eww.yuck`
- `configs/eww/eww.scss`
- `configs/eww/widgets/system_status.yuck`
- `configs/eww/widgets/core_modules.yuck`
- `configs/eww/widgets/network.yuck`
- `configs/eww/widgets/system_log.yuck`
- `configs/eww/widgets/system_profile.yuck`
- `configs/eww/widgets/memory.yuck`
- `scripts/setup-eww.sh`
- `scripts/start-eww.sh`
- `scripts/select-resolution.sh`
- regenerated wallpaper PNG assets for `1920x1080`, `2560x1440`, and `4096x2160`

### Removed

- removed all bundled Conky configs and install scripts
- removed the old picom config from the repo
- removed the old resolution-profile helper used by the Conky HUD

### Notes

- the launcher stays on `Meta+K`
- Plasma panels are still hidden via auto-hide only; they are never deleted
- the HUD is opened as a non-focusable layer-shell surface so it behaves like desktop chrome instead of a normal app window
