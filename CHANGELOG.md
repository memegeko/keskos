# Changelog

## 2026-04-24

This update is the big cleanup pass that moves `keskos` away from the older Conky/X11-ish setup and into a Wayland-first Plasma setup.

### What changed

- replaced the old Conky HUD with an Eww HUD
- removed the bundled picom config and old Conky helpers
- updated the installer to build upstream `eww` with Wayland support
- switched autostart over to the new Eww startup flow
- updated the wallpaper assets so the right-middle panel now reads `SYSTEM PROFILE`
- rewrote the README so it matches the project as it actually exists now

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

### Removed

- `configs/conky/`
- `configs/picom/picom.conf`
- `scripts/setup-conky.sh`
- `scripts/setup-scanlines.sh`
- `scripts/select-resolution-profile.sh`

### Kept on purpose

- the launcher still opens on `Meta+K`
- Plasma panels are still hidden with auto-hide instead of being deleted
- the overall look stays black, orange, and minimal
