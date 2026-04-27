# Changelog

## 2026-04-26

### Convert KeskOS to an ISO project

`main` is no longer the old script-based desktop installer. It is now an Archiso project that boots to KDE Plasma and installs through Calamares.

### Added

- `build.sh`
- `profiledef.sh`
- `packages.x86_64`
- `pacman.conf`
- `airootfs/`
- `calamares/`
- `browser-home/`
- live-session helper scripts under `airootfs/usr/local/bin/`
- Calamares branding under `calamares/branding/keskos/`

### Changed

- switched the project layout to an Archiso-style tree
- added a local AUR-backed package repo flow for `calamares` and `kdotool-bin`
- made the live ISO boot into an autologin KDE Plasma desktop
- added a proper `Install KeskOS` desktop shortcut and launcher entry
- moved launcher, HUD, wallpaper, Konsole, SDDM, lock screen, and splash assets into a system-wide live/install flow
- changed launcher/browser/Quickshell paths away from the old `~/.local` installer layout and into `/usr/local/bin` and `/usr/local/share/keskos`
- added a Calamares post-install hook that removes live-only pieces and applies installed-user defaults
- rewrote the README for the ISO workflow
- added GitHub Actions release automation so version tags can publish a ready-to-download ISO
- taught `build.sh` a CI/container mode so the release pipeline can run as root inside an Arch build container
- aligned the ISO profile to the supported `bios.syslinux` + `uefi.grub` boot path and added the missing host/package requirements for release builds

### Preserved

- the old script-based installer was moved safely to the `legacy-script-installer` branch
- that branch was committed with:
  - `Preserve legacy script-based installer`

### Notes

- `build.sh` now handles repo paths with spaces by generating a URI-safe local pacman repo URL
- `main` intentionally no longer ships the old `install.sh` workflow
- use `git checkout legacy-script-installer` if you want the original script installer back
