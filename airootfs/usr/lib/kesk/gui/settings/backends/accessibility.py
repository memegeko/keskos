from __future__ import annotations

from typing import Any

from .common import BackendStatus, connected, limited, result_payload


def is_available(_backend) -> bool:
    return True


def _status(backend) -> BackendStatus:
    if backend.tools.get("kwriteconfig6") or backend.tools.get("kreadconfig6"):
        return limited(
            "Large text, reduced animations, and cursor size are wired directly. Other accessibility controls still use KDE handoff.",
            details=[
                "Sticky keys, slow keys, bounce keys, high contrast, and screen-reader toggles stay limited until their KDE keys are validated.",
            ],
            advanced_module="kcm_access",
        )
    return limited(
        "KDE config tools are missing. INI fallback can still store a few accessibility preferences.",
        details=["Use the advanced KDE accessibility module for complete accessibility controls."],
        missing_tools=["kwriteconfig6", "kreadconfig6"],
        advanced_module="kcm_access",
    )


def read_current(backend) -> dict[str, Any]:
    dpi = backend.parse_int(backend.kread(backend.kdeglobals, ("General",), "forceFontDPI", "96"), 96)
    animation_factor = backend.kread(backend.kdeglobals, ("KDE",), "AnimationDurationFactor", "1.0") or "1.0"
    cursor_size = backend.parse_int(backend.kread(backend.kcminputrc, ("Mouse",), "cursorSize", "24"), 24)
    return {
        "status": _status(backend),
        "large_text": dpi >= 120,
        "high_contrast": "contrast" in backend.kread(backend.kdeglobals, ("General",), "ColorScheme", "").lower(),
        "reduce_animations": float(animation_factor) < 1.0,
        "sticky_keys": False,
        "slow_keys": False,
        "bounce_keys": False,
        "screen_reader": False,
        "cursor_size": max(16, cursor_size),
        "supports_large_text": True,
        "supports_high_contrast": False,
        "supports_reduce_animations": True,
        "supports_sticky_keys": False,
        "supports_slow_keys": False,
        "supports_bounce_keys": False,
        "supports_screen_reader": False,
        "supports_cursor_size": True,
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    backend.kwrite(backend.kdeglobals, ("General",), "forceFontDPI", "144" if bool(values.get("large_text")) else "96")
    backend.kwrite(
        backend.kdeglobals,
        ("KDE",),
        "AnimationDurationFactor",
        "0.50" if bool(values.get("reduce_animations")) else "1.00",
    )
    backend.kwrite(backend.kcminputrc, ("Mouse",), "cursorSize", str(int(values.get("cursor_size", 24))))

    warnings: list[str] = []
    if values.get("high_contrast"):
        warnings.append("High contrast is not connected directly yet. Use the advanced KDE accessibility module.")
    if values.get("sticky_keys") or values.get("slow_keys") or values.get("bounce_keys"):
        warnings.append("Sticky keys, slow keys, and bounce keys still use KDE's advanced accessibility module.")
    if values.get("screen_reader"):
        warnings.append("Screen-reader toggling is not connected directly yet.")

    return result_payload(
        True,
        "Accessibility settings updated.",
        details=[
            "Large-text DPI preference was updated.",
            "Animation reduction preference was updated.",
            "Cursor size preference was updated.",
        ],
        warnings=warnings,
        requires=["Open advanced KDE accessibility settings for the remaining assistive controls."],
    )


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_access")
