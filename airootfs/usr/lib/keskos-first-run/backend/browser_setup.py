from __future__ import annotations

import configparser
import logging
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

from . import pacman_backend


@dataclass(frozen=True, slots=True)
class BrowserOption:
    key: str
    label: str
    description: str
    note: str
    package_candidates: tuple[str, ...]
    desktop_ids: tuple[str, ...]
    family: str


BROWSERS: tuple[BrowserOption, ...] = (
    BrowserOption(
        key="librewolf",
        label="LibreWolf",
        description="Privacy-focused Firefox-based browser.",
        note="Best fit for hardened browsing and low-friction theming.",
        package_candidates=("librewolf",),
        desktop_ids=("librewolf.desktop",),
        family="firefox",
    ),
    BrowserOption(
        key="zen",
        label="Zen Browser",
        description="Modern Firefox-based browser with a clean workflow.",
        note="Stylish workflow browser with Firefox foundations.",
        package_candidates=("zen-browser",),
        desktop_ids=("zen-browser.desktop", "zen.desktop"),
        family="firefox",
    ),
    BrowserOption(
        key="brave",
        label="Brave",
        description="Chromium-based browser with built-in ad/tracker blocking.",
        note="Chromium engine with strong defaults and broad web compatibility.",
        package_candidates=("brave-browser", "brave-bin", "brave-browser-bin"),
        desktop_ids=("brave-browser.desktop", "brave.desktop"),
        family="chromium",
    ),
)


def browser_map() -> dict[str, BrowserOption]:
    return {browser.key: browser for browser in BROWSERS}


def get_browser_option(key: str) -> BrowserOption | None:
    return browser_map().get(key)


def resolve_browser_package(option: BrowserOption) -> str | None:
    return pacman_backend.resolve_first_available(option.package_candidates)


def browser_status(option: BrowserOption) -> tuple[str, bool]:
    package_name = resolve_browser_package(option)
    if package_name is None:
        return "Unavailable in current repositories", False
    if pacman_backend.is_installed(package_name):
        return f"Installed via {package_name}", True
    return f"Ready to install via {package_name}", True


def find_desktop_id(option: BrowserOption) -> str:
    search_roots = (
        Path("/usr/share/applications"),
        Path.home() / ".local/share/applications",
    )
    for desktop_id in option.desktop_ids:
        for root in search_roots:
            if (root / desktop_id).exists():
                return desktop_id
    return option.desktop_ids[0]


def _run_optional(command: list[str], logger: logging.Logger) -> None:
    try:
        result = subprocess.run(command, check=False, capture_output=True, text=True, timeout=15.0)
    except (OSError, subprocess.SubprocessError) as error:
        logger.warning("command failed: %s", error)
        return

    if result.returncode != 0:
        stderr = result.stderr.strip()
        if stderr:
            logger.warning("%s", stderr)


def set_default_browser(option: BrowserOption, logger: logging.Logger) -> tuple[bool, list[str]]:
    desktop_id = find_desktop_id(option)
    details = [f"default desktop entry: {desktop_id}"]

    if shutil.which("xdg-settings"):
        _run_optional(["xdg-settings", "set", "default-web-browser", desktop_id], logger)
        details.append("xdg-settings updated")

    if shutil.which("xdg-mime"):
        for mime in (
            "x-scheme-handler/http",
            "x-scheme-handler/https",
            "text/html",
            "application/xhtml+xml",
        ):
            _run_optional(["xdg-mime", "default", desktop_id, mime], logger)
        details.append("xdg-mime defaults updated")

    mimeapps_path = Path.home() / ".config" / "mimeapps.list"
    parser = configparser.ConfigParser(interpolation=None)
    if mimeapps_path.exists():
        parser.read(mimeapps_path, encoding="utf-8")
    if "Default Applications" not in parser:
        parser["Default Applications"] = {}
    defaults = parser["Default Applications"]
    defaults["x-scheme-handler/http"] = desktop_id
    defaults["x-scheme-handler/https"] = desktop_id
    defaults["text/html"] = desktop_id
    defaults["application/xhtml+xml"] = desktop_id
    mimeapps_path.parent.mkdir(parents=True, exist_ok=True)
    with mimeapps_path.open("w", encoding="utf-8") as handle:
        parser.write(handle)
    details.append("mimeapps.list updated")
    return True, details
