from __future__ import annotations

from typing import Any

from .common import connected, limited, missing, result_payload


def is_available(backend) -> bool:
    return bool(backend.tools.get("kscreen-doctor")) or bool(backend.tools.get("qdbus6"))


def _status(backend):
    if backend.tools.get("kscreen-doctor"):
        details = ["Resolution, scale, refresh rate, and orientation remain guarded and use KDE's advanced display module for live layout changes."]
        if not backend.tools.get("brightnessctl"):
            details.append("Brightness control is unavailable because brightnessctl is not installed.")
        return limited("Display state is readable through KScreen.", details=details, advanced_module="kcm_kscreen")
    if backend.tools.get("qdbus6"):
        return limited("Only limited display integration is available without kscreen-doctor.", missing_tools=["kscreen-doctor"], advanced_module="kcm_kscreen")
    return missing("No direct display backend is available.", missing_tools=["kscreen-doctor", "qdbus6"], advanced_module="kcm_kscreen")


def _brightness(backend) -> int | None:
    tool = backend.tools.get("brightnessctl")
    if not tool:
        return None
    result = backend._run([tool, "-m"], capture=True, timeout=10)
    if result is None or result.returncode != 0:
        return None
    parts = result.stdout.strip().split(",")
    if len(parts) >= 4 and parts[3].endswith("%"):
        try:
            return int(parts[3].removesuffix("%"))
        except ValueError:
            return None
    return None


def read_current(backend) -> dict[str, Any]:
    data = backend.parse_display_info()
    brightness = _brightness(backend)
    return {
        "status": _status(backend),
        "monitor_list": data.get("monitor_list", []),
        "output_summary": data.get("output_summary", "Display detection unavailable"),
        "session": data.get("session", "unknown"),
        "plasma_version": data.get("plasma_version", "unavailable"),
        "resolution": str(backend.custom_value("display_resolution", "Automatic")),
        "refresh_rate": int(backend.custom_value("display_refresh_rate", 60)),
        "scale_percent": int(backend.custom_value("display_scale_percent", 100)),
        "orientation": str(backend.custom_value("display_orientation", "Normal")),
        "brightness": brightness if brightness is not None else int(backend.custom_value("display_brightness", 100)),
        "night_color": backend.as_bool(backend.custom_value("display_night_color"), False),
        "supports_live_layout": False,
        "supports_brightness": brightness is not None,
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    details = ["Stored resolution, scale, refresh rate, and orientation preferences for the KDE display backend."]
    warnings: list[str] = []
    backend.kwrite(backend.kwinrc, ("NightColor",), "Active", backend.bool_text(bool(values.get("night_color", False))))
    tool = backend.tools.get("brightnessctl")
    if tool and values.get("brightness") is not None:
        result = backend._run([tool, "set", f"{int(values.get('brightness', 100))}%"], capture=True, timeout=10)
        if result is not None and result.returncode == 0:
            details.append("Updated backlight brightness through brightnessctl.")
        else:
            warnings.append("Brightness could not be changed.")
    elif values.get("brightness") is not None:
        warnings.append("brightnessctl is not installed, so brightness stayed unchanged.")
    return result_payload(
        True,
        "Display preferences updated.",
        details=details,
        warnings=warnings,
        requires=["Use KDE's advanced display settings for live monitor layout, scale, refresh-rate, and orientation changes."],
    )


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_kscreen")
