# KeskOS

<p align="center">
  <img src="assets/kesk_os_logo_text.png" alt="KeskOS logo" width="460">
</p>

<p align="center">
  <strong>Legacy systems. Modern workflows.</strong><br>
  An Arch-based KDE Plasma operating system with a dark industrial console style, a custom command launcher, and a fully themed live installer.
</p>

## Current Release

The current ISO release asset is:

- `keskos-2026.05.01-x86_64.iso.zst`
- Download size: about `1.9 GB`
- Extracted ISO size: about `2.1 GB`
- SHA-256:

```text
4b88553a0b39fc9567018b872881ac2bd093321787ec4429baba5859a8754b04
```

Download it from:

- [GitHub Releases](https://github.com/memegeko/keskos/releases)

### Using the Download

The release is published as a compressed `.iso.zst` file.

On Linux:

```bash
unzstd keskos-2026.05.01-x86_64.iso.zst
```

On Windows:

- extract it with `7-Zip`, `PeaZip`, or another archive tool with `.zst` support
- this gives you `keskos-2026.05.01-x86_64.iso`
- flash that `.iso` with `Rufus`, `balenaEtcher`, or `Ventoy`

## About KeskOS

`KeskOS` is a full live operating system built on Arch Linux. It boots straight into a usable KDE Plasma desktop, carries its own visual identity from boot to login to installer to desktop, and installs through a custom-themed Calamares workflow.

It is meant to feel like a complete product instead of a loose rice script:

- a real live ISO you can boot and test before installing
- a dark industrial orange-on-black desktop style
- a custom `KESK` command layer for launching apps, files, settings, web, windows, and power actions
- a themed terminal, browser home page, login stack, lock screen, splash screen, and installer
- a custom window decoration theme built for the rest of the OS look
- a desktop that stays visually consistent across the live session and installed system

## Main Features

### Live ISO

Booting the ISO gives you a real live desktop session with:

- KDE Plasma
- autologin into the live environment
- working launcher, browser, terminal, and file manager
- `Install KeskOS` desktop shortcut and menu entry
- preloaded branding and theme assets

### Installer

KeskOS installs through Calamares with a custom visual style and standard guided flow:

- Welcome
- Location
- Keyboard
- Partitions
- Users
- Summary
- Install
- Finish

### Desktop Experience

The installed system carries over the visual identity:

- custom orange console look
- `KESK` launcher shortcuts
- custom Konsole profile
- custom browser home page
- prefilled username on the first login screen after install
- custom login / lock / splash stack

## Screenshots

### Desktop and Apps

<p align="center">
  <img src="docs/screenshots/kesklaucherstartpage.png" alt="Kesk launcher start page" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskssearch.png" alt="Kesk launcher search results" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskmath.png" alt="Kesk calculator result" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskgoogle.png" alt="Kesk web search shortcut" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskbrowserstartpage.png" alt="Kesk browser start page" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskos_terminal.png" alt="KeskOS terminal and fastfetch" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/lockscreen.png" alt="KeskOS lock screen" width="780">
</p>

### Installer Flow

<p align="center">
  <img src="docs/screenshots/keskos_installstep_welcome.png" alt="KeskOS installer welcome screen" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskos_installstep_location.png" alt="KeskOS installer location screen" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskos_installstep_keyboard.png" alt="KeskOS installer keyboard screen" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskos_installstep_partitions.png" alt="KeskOS installer partition screen" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskos_installstep_users.png" alt="KeskOS installer users screen" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskos_installstep_summary.png" alt="KeskOS installer summary screen" width="780">
</p>

<p align="center">
  <img src="docs/screenshots/keskos_installstep_finish.png" alt="KeskOS installer finish screen" width="780">
</p>

## Installing KeskOS

1. Download the latest release asset from [Releases](https://github.com/memegeko/keskos/releases).
2. Extract the ISO:

```bash
unzstd keskos-2026.05.01-x86_64.iso.zst
```

3. Write the extracted `.iso` to a USB drive with your preferred flashing tool.
4. Boot the machine from that USB drive.
5. Test the live desktop if you want.
6. Open `Install KeskOS`.
7. Follow the Calamares installer.

Recommended VM settings for testing:

- `4 GB` RAM or more
- `4` vCPUs if available
- `32 GB` virtual disk or more
- UEFI firmware if you want to test the EFI path

## Included Components

KeskOS currently ships with these major pieces:

- Arch Linux base
- KDE Plasma desktop
- Calamares installer
- `rofi`-based `KESK` launcher
- Konsole
- Dolphin
- Firefox / browser integration for the live environment
- custom SDDM, lock screen, and splash
- custom wallpaper, HUD, and branding assets

## Release Notes for 2026.05.01

This ISO line includes:

- a real live desktop instead of the old script-only setup path
- a themed Calamares installer
- a seam-free custom window decoration path
- launcher, browser, files, and terminal wired into the live session
- post-install user defaults and first-login polish
- branded login, lock screen, splash, and browser home

## Source and Legacy Branch

The repo still keeps the old script installer work safely preserved.

Branches:

- `main`
  - the current Archiso + Calamares ISO project
- `legacy-script-installer`
  - the original script-based installer work

Switch branches with:

```bash
git checkout legacy-script-installer
```

and:

```bash
git checkout main
```
