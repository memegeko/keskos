from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from .browser_setup import BrowserOption

STARTPAGE_URL = "file:///usr/share/keskos/startpage/index.html"
THEME_ROOT = Path("/usr/share/keskos/first-run/browser-theme")


@dataclass(slots=True)
class ThemeResult:
    status: str
    headline: str
    details: list[str]


def _copy_firefox_theme_assets(chrome_dir: Path) -> None:
    chrome_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(THEME_ROOT / "firefox-userChrome.css", chrome_dir / "userChrome.css")
    shutil.copy2(THEME_ROOT / "firefox-userContent.css", chrome_dir / "userContent.css")


def _write_firefox_userjs(profile_dir: Path) -> None:
    userjs = profile_dir / "user.js"
    prefs = [
        'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);',
        f'user_pref("browser.startup.homepage", "{STARTPAGE_URL}");',
        'user_pref("browser.startup.page", 1);',
        'user_pref("browser.newtabpage.enabled", false);',
        'user_pref("browser.aboutConfig.showWarning", false);',
        'user_pref("browser.shell.checkDefaultBrowser", false);',
    ]
    userjs.write_text("\n".join(prefs) + "\n", encoding="utf-8")


def _find_firefox_profiles(config_root: Path) -> list[Path]:
    profiles: list[Path] = []
    profiles_ini = config_root / "profiles.ini"
    if profiles_ini.exists():
        current_path = ""
        is_relative = True
        for line in profiles_ini.read_text(encoding="utf-8", errors="ignore").splitlines():
            if line.startswith("Path="):
                current_path = line.split("=", 1)[1].strip()
            elif line.startswith("IsRelative="):
                is_relative = line.split("=", 1)[1].strip() != "0"
            elif line.startswith("[") and current_path:
                profile_path = config_root / current_path if is_relative else Path(current_path)
                if profile_path.is_dir():
                    profiles.append(profile_path)
                current_path = ""

        if current_path:
            profile_path = config_root / current_path if is_relative else Path(current_path)
            if profile_path.is_dir():
                profiles.append(profile_path)

    if profiles:
        return profiles

    return [path for path in config_root.glob("*.default*") if path.is_dir()]


def _apply_firefox_family(config_root: Path) -> ThemeResult:
    if not config_root.exists():
        return ThemeResult(
            status="partial",
            headline="THEME PARTIALLY APPLIED",
            details=["Browser profile directory was not found yet. Launch the browser once to finish profile theming."],
        )

    profiles = _find_firefox_profiles(config_root)
    if not profiles:
        return ThemeResult(
            status="partial",
            headline="THEME PARTIALLY APPLIED",
            details=["Browser profile was not created yet. The local startpage path is ready, but profile styling will apply after first launch."],
        )

    for profile in profiles:
        _copy_firefox_theme_assets(profile / "chrome")
        _write_firefox_userjs(profile)

    return ThemeResult(
        status="applied",
        headline="THEME APPLIED",
        details=[f"Applied userChrome, userContent, and homepage settings to {len(profiles)} Firefox-family profile(s)."],
    )


def _set_json_path(data: dict, path: list[str], value) -> None:
    current = data
    for key in path[:-1]:
        current = current.setdefault(key, {})
    current[path[-1]] = value


def _apply_brave(config_root: Path) -> ThemeResult:
    profile_dir = config_root / "Default"
    preferences_path = profile_dir / "Preferences"
    if not preferences_path.exists():
        return ThemeResult(
            status="partial",
            headline="THEME PARTIALLY APPLIED",
            details=["Brave profile data was not found yet. Homepage theming will apply after the browser creates its first profile."],
        )

    data = json.loads(preferences_path.read_text(encoding="utf-8"))
    _set_json_path(data, ["browser", "show_home_button"], True)
    _set_json_path(data, ["homepage"], STARTPAGE_URL)
    _set_json_path(data, ["homepage_is_newtabpage"], False)
    _set_json_path(data, ["session", "restore_on_startup"], 4)
    _set_json_path(data, ["session", "startup_urls"], [STARTPAGE_URL])
    preferences_path.write_text(json.dumps(data, indent=2), encoding="utf-8")

    return ThemeResult(
        status="partial",
        headline="THEME PARTIALLY APPLIED",
        details=["Brave homepage and startup URLs were updated. Full browser chrome theming is limited on Chromium-based browsers."],
    )


def apply_browser_theme(option: BrowserOption) -> ThemeResult:
    if option.family == "firefox" and option.key == "librewolf":
        return _apply_firefox_family(Path.home() / ".librewolf")

    if option.family == "firefox" and option.key == "zen":
        return _apply_firefox_family(Path.home() / ".zen")

    if option.family == "chromium":
        return _apply_brave(Path.home() / ".config" / "BraveSoftware" / "Brave-Browser")

    return ThemeResult(
        status="partial",
        headline="THEME PARTIALLY APPLIED",
        details=["No browser-specific theme handler is available for this selection."],
    )
