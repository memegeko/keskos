# Changelog

## 2026-05-01

### Release focus and ISO polish

KeskOS now reads and behaves much more like a real operating system release rather than a repo for an old rice script workflow.

### Added

- official release-targeted ISO artifact:
  - `keskos-2026.05.01-x86_64.iso`
- seam-free custom QML KWin decoration theme
- improved live Calamares debug stream and installer logging
- more complete release screenshot set for desktop and installer flow

### Changed

- rewrote the README around the released ISO instead of the developer build tree
- expanded the README to present KeskOS as a real OS with desktop, installer, branding, and workflow features
- added a proper screenshot gallery for launcher, browser, terminal, lock screen, and installer steps
- tuned the custom titlebar branding and window decoration polish
- improved the Calamares install screen layout so it stays dark and readable during live install progress

### Fixed

- removed the visible seams/gaps from the custom window border by moving to a QML-based decoration path
- fixed titlebar icon placement and sizing
- fixed the Calamares install view white background problem
- fixed overlapping live debug text in the installer slideshow
- fixed live-session launcher subpage failures so blank pages fall back more safely
- fixed multiple ISO/live-install issues in the Calamares and mkinitcpio pipeline

### Notes

- the README is now intended to support the GitHub Releases page first
- the old script installer remains preserved on `legacy-script-installer`

## 2026-04-27

### Remove broken release automation

The GitHub Actions ISO release pipeline was removed from `main`. KeskOS releases are now published manually after a local `./build.sh` and test pass.

### Changed

- removed the broken GitHub Actions ISO release workflow
- removed the CI/container-only build path from `build.sh`
- rewrote the README to describe manual release publishing instead of tag-triggered automation

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
- aligned the ISO profile to the supported `bios.syslinux` + `uefi.grub` boot path and added the missing host/package requirements for release builds
- removed the invalid `ttf-vt323` package reference so the ISO package set resolves cleanly on Arch

### Preserved

- the old script-based installer was moved safely to the `legacy-script-installer` branch
- that branch was committed with:
  - `Preserve legacy script-based installer`

### Notes

- `build.sh` now handles repo paths with spaces by generating a URI-safe local pacman repo URL
- `main` intentionally no longer ships the old `install.sh` workflow
- use `git checkout legacy-script-installer` if you want the original script installer back
