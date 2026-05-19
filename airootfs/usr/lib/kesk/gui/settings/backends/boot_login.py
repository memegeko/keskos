from __future__ import annotations

import configparser
from pathlib import Path
from typing import Any

from . import privileged
from .common import BackendStatus, connected, limited, requires_admin, result_payload


def is_available(_backend) -> bool:
    return True


def _sddm_theme(backend) -> str:
    config_paths = [Path("/etc/sddm.conf")]
    conf_dir = Path("/etc/sddm.conf.d")
    if conf_dir.is_dir():
        config_paths.extend(sorted(conf_dir.glob("*.conf")))
    for config_path in config_paths:
        parser = configparser.ConfigParser(interpolation=None)
        parser.optionxform = str
        try:
            parser.read(config_path, encoding="utf-8")
        except (OSError, configparser.Error):
            continue
        value = parser.get("Theme", "Current", fallback="")
        if value:
            return value
    return "unavailable"


def _sddm_background(theme_name: str) -> str:
    if not theme_name or theme_name == "unavailable":
        return ""
    theme_conf = Path("/usr/share/sddm/themes") / theme_name / "theme.conf"
    if not theme_conf.is_file():
        return ""
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    try:
        parser.read(theme_conf, encoding="utf-8")
    except (OSError, configparser.Error):
        return ""
    return parser.get("General", "background", fallback="")


def _plymouth_theme() -> str:
    config_path = Path("/etc/plymouth/plymouthd.conf")
    if not config_path.is_file():
        return "unavailable"
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    try:
        parser.read(config_path, encoding="utf-8")
    except (OSError, configparser.Error):
        return "unavailable"
    return parser.get("Daemon", "Theme", fallback="unavailable")


def _boot_conf() -> Path:
    return Path("/etc/keskos/boot.conf")


def _quiet_boot_state() -> bool:
    grub_default = Path("/etc/default/grub")
    if grub_default.is_file():
        try:
            return "quiet" in grub_default.read_text(encoding="utf-8", errors="replace")
        except OSError:
            return True
    return True


def _min_duration(backend) -> int:
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    path = _boot_conf()
    if path.is_file():
        try:
            parser.read(path, encoding="utf-8")
            return parser.getint("Boot", "MinSplashDuration", fallback=int(backend.custom_value("boot_splash_min_duration", 2)))
        except (OSError, ValueError, configparser.Error):
            pass
    return int(backend.custom_value("boot_splash_min_duration", 2))


def _status(backend) -> BackendStatus:
    privileged_state = privileged.read_current(backend)
    if privileged_state["status"].code == "missing":
        return limited(
            "User-level boot preferences can be stored, but system theme changes need the Kesk Settings helper.",
            details=["Install the helper and polkit policy to apply SDDM, Plymouth, and quiet-boot changes from the GUI."],
            advanced_module="kcm_sddm",
        )
    return requires_admin(
        "Boot and login theme changes are available through pkexec.",
        details=["SDDM, Plymouth, quiet boot, and initramfs changes require administrator approval."],
        advanced_module="kcm_sddm",
    )


def read_current(backend) -> dict[str, Any]:
    sddm_theme = _sddm_theme(backend)
    return {
        "status": _status(backend),
        "sddm_theme": sddm_theme,
        "sddm_background": _sddm_background(sddm_theme),
        "plymouth_theme": _plymouth_theme(),
        "boot_splash_min_duration": _min_duration(backend),
        "quiet_boot": _quiet_boot_state(),
        "show_boot_logs": bool(backend.custom_value("boot_show_logs", False)),
        "show_user_list": bool(backend.custom_value("show_user_list", True)),
        "terminal_boot_text": bool(backend.custom_value("boot_terminal_text", False)),
        "login_background": str(backend.custom_value("login_background", "")),
        "reboot_required": Path("/var/run/reboot-required").exists(),
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    details: list[str] = []
    warnings: list[str] = []
    requires: list[str] = []

    current = read_current(backend)
    if privileged.is_available(backend):
        requested_sddm = str(values.get("sddm_theme", "")).strip()
        requested_plymouth = str(values.get("plymouth_theme", "")).strip()
        requested_background = str(values.get("login_background", "")).strip()
        if requested_sddm and requested_sddm != current["sddm_theme"]:
            result = privileged.run_action(backend, "set-sddm-theme", requested_sddm, timeout=120)
            details.extend(result["details"])
            warnings.extend(result["warnings"])
            if result["success"]:
                details.append(f"Applied SDDM theme: {requested_sddm}")
                requires.append("Log out to verify the updated login theme.")
        if requested_background and requested_background != current.get("login_background", ""):
            result = privileged.run_action(backend, "set-sddm-background", requested_sddm or current["sddm_theme"], requested_background, timeout=120)
            warnings.extend(result["warnings"])
            if result["success"]:
                details.append("Updated the SDDM login background.")
                requires.append("Log out to verify the updated login background.")
        if requested_plymouth and requested_plymouth != current["plymouth_theme"]:
            result = privileged.run_action(backend, "set-plymouth-theme", requested_plymouth, timeout=600)
            warnings.extend(result["warnings"])
            if result["success"]:
                details.append(f"Applied Plymouth theme: {requested_plymouth}")
                requires.extend(["Initramfs may have been rebuilt.", "Reboot to verify the updated boot splash."])
        if bool(values.get("quiet_boot", True)) != bool(current["quiet_boot"]):
            result = privileged.run_action(backend, "set-quiet-boot", "on" if values.get("quiet_boot") else "off", timeout=180)
            warnings.extend(result["warnings"])
            if result["success"]:
                details.append(f"Quiet boot set to {'enabled' if values.get('quiet_boot') else 'disabled'}.")
                requires.append("Reboot to verify the updated boot options.")
        if int(values.get("boot_splash_min_duration", 2)) != int(current["boot_splash_min_duration"]):
            result = privileged.run_action(backend, "set-boot-splash-duration", str(int(values.get("boot_splash_min_duration", 2))), timeout=60)
            warnings.extend(result["warnings"])
            if result["success"]:
                details.append("Updated the boot splash minimum duration.")
                requires.append("Reboot to verify the updated splash timing.")
    else:
        warnings.append("The privileged boot/login helper is unavailable, so only user-level boot preferences were stored.")

    backend.set_custom_values(
        {
            "boot_splash_min_duration": int(values.get("boot_splash_min_duration", 2)),
            "boot_show_logs": bool(values.get("show_boot_logs", False)),
            "boot_quiet_boot": bool(values.get("quiet_boot", True)),
            "show_user_list": bool(values.get("show_user_list", True)),
            "boot_terminal_text": bool(values.get("terminal_boot_text", False)),
            "login_background": str(values.get("login_background", "")).strip(),
        }
    )
    details.append("Stored user-visible boot and login preferences.")
    return result_payload(True, "Boot and login settings updated.", details=details, warnings=warnings, requires=requires)


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_sddm")
