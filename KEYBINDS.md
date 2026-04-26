# Keybinds

This file lists the shortcuts that `keskos` installs by default.

## Launcher

- `Meta` -> opens the `KESKOS Launcher`
- `Meta+K` -> opens the `KESKOS Launcher`
- `Meta+Shift+K` -> opens the `Apps` page
- `Meta+Shift+Tab` -> opens the `Active Windows` page
- `Meta+Shift+S` -> opens the `Settings` page
- `Meta+P` -> opens the `Power` page

## Direct Actions

- `Meta+T` -> opens a terminal
- `Meta+Enter` -> opens a terminal
- `Meta+N` -> opens files
- `Meta+W` -> opens the browser

## Notes

- `Active Windows` stays inside the launcher on Wayland when `kdotool` is installed.
- On X11, `Active Windows` uses `wmctrl`.
- `keskos` clears a few default Plasma shortcuts so these Meta bindings can take over cleanly.

## If A Shortcut Does Not Apply Automatically

1. Open `System Settings`
2. Go to `Keyboard`
3. Open `Shortcuts`
4. Search for `KESKOS`
5. Rebind the matching `KESKOS` entry to the shortcut you want

If the `Meta` key by itself still opens Plasma's default launcher, rerun:

```bash
bash scripts/setup-shortcuts.sh "$PWD"
```
