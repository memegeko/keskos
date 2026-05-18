# Kesk Upgrade

This updater currently ships as part of the `beta-development` branch.

`kesk upgrade` is the first official `kesk` system tool for KeskOS.

It opens a terminal-based upgrade manager with a dark machine-console feel and checks four update sources:

- pacman official repositories
- `yay` / AUR when `yay` is installed
- Flatpak when `flatpak` is installed
- firmware updates when `fwupdmgr` is installed

## Running It

From a terminal:

```bash
kesk upgrade
```

Router commands that are also available:

```bash
kesk help
kesk --help
kesk version
```

## Start Menu Launcher

KeskOS ships a KDE launcher entry at:

- `/usr/share/applications/kesk-upgrade.desktop`

It opens the updater in Konsole with:

```bash
konsole --hold --workdir ~ -e /usr/bin/kesk upgrade
```

That keeps the terminal visible after exit instead of closing immediately.

## What The Updater Does

When opened, the updater:

1. Detects supported update tools.
2. Checks update counts without performing upgrades.
3. Shows missing tools as unavailable instead of failing.
4. Lets you pick which source to upgrade.
5. Asks for confirmation before any package or firmware change.
6. Streams live command output while upgrades run.
7. Shows a final status and reboot recommendation.

## Supported Update Sources

### Official Repositories

- Preferred check command: `checkupdates`
- Fallback check command: `pacman -Qu`
- Upgrade command: `sudo pacman -Syu`

If `/var/lib/pacman/db.lck` exists, official package checks and pacman-based upgrades are blocked until the lock clears.

### AUR

- Check command: `yay -Qua`
- Upgrade command: `yay -Syu`

If `yay` is missing, the updater shows:

```text
AUR support unavailable: yay not installed
```

### Flatpak

- Check command: `flatpak remote-ls --updates`
- Upgrade command: `flatpak update`

If `flatpak` is missing, the updater shows:

```text
Flatpak support unavailable: flatpak not installed
```

### Firmware

- Check command: `fwupdmgr get-updates`
- Upgrade command: `sudo fwupdmgr update`

If `fwupdmgr` is missing, the updater shows:

```text
Firmware support unavailable: fwupd not installed
```

## Missing Tools

Optional sources are never fatal.

- No `yay`: AUR is disabled.
- No `flatpak`: Flatpak is disabled.
- No `fwupdmgr`: firmware updates are disabled.
- No `checkupdates`: pacman checks fall back to `pacman -Qu`.

## Logs

Every interactive run writes a timestamped log to:

```text
~/.local/state/kesk/logs/
```

Log file format:

```text
upgrade-YYYYMMDD-HHMMSS.log
```

Each log includes:

- start time
- detected tools
- update counts
- selected actions
- commands executed
- exit codes
- final status

Passwords and secrets are not logged.

## Pacman Lock Debugging

If you see a pacman lock warning:

```text
[ !! ] pacman database lock detected: /var/lib/pacman/db.lck
```

check for another package transaction first:

```bash
ps -ef | grep -E 'pacman|yay'
```

Do not delete the lock file automatically.
Only remove it manually after you are sure no package manager process is still active.

## Reboot Recommended

The updater shows:

```text
[ !! ] reboot recommended
```

when one of these conditions is detected:

- a kernel package was part of the upgrade set
- `systemd` was updated
- `mesa` or `nvidia` drivers were updated
- firmware was updated
- `/var/run/reboot-required` exists on the system

Otherwise it shows:

```text
[ OK ] reboot not required
```
