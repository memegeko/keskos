from __future__ import annotations

import re
from typing import Any

from .common import connected, limited, missing, result_payload


def is_available(backend) -> bool:
    return bool(backend.tools.get("wpctl") or backend.tools.get("pactl"))


def _status(backend):
    if backend.tools.get("wpctl") or backend.tools.get("pactl"):
        details = []
        if backend.tools.get("pactl") and not backend.tools.get("wpctl"):
            details.append("Using PulseAudio compatibility mode through pactl.")
            return limited("Audio control is available through pactl.", details=details, advanced_module="kcm_pulseaudio")
        return connected("PipeWire audio control is available.", advanced_module="kcm_pulseaudio")
    return missing("Neither wpctl nor pactl is installed.", missing_tools=["wpctl", "pactl"], advanced_module="kcm_pulseaudio")


def _parse_pactl_short(backend, kind: str) -> list[dict[str, str]]:
    tool = backend.tools.get("pactl")
    if not tool:
        return []
    result = backend._run([tool, "list", "short", kind], capture=True, timeout=15)
    if result is None or result.returncode != 0:
        return []
    rows: list[dict[str, str]] = []
    for line in result.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        rows.append({"id": parts[0].strip(), "name": parts[1].strip()})
    return rows


def _parse_wpctl_volume(backend, target: str) -> tuple[int, bool]:
    tool = backend.tools.get("wpctl")
    if tool:
        result = backend._run([tool, "get-volume", target], capture=True, timeout=10)
        if result is not None and result.returncode == 0:
            text = result.stdout.strip()
            match = re.search(r"([0-9]*\.[0-9]+|[0-9]+)", text)
            volume = 50
            if match:
                volume = max(0, min(int(float(match.group(1)) * 100), 150))
            return volume, "[MUTED]" in text

    tool = backend.tools.get("pactl")
    if not tool:
        return 50, False
    info_target = "sinks" if "SINK" in target else "sources"
    result = backend._run([tool, "list", info_target], capture=True, timeout=15)
    if result is None or result.returncode != 0:
        return 50, False
    for line in result.stdout.splitlines():
        if "Volume:" in line and "%" in line:
            match = re.search(r"(\d+)%", line)
            if match:
                return int(match.group(1)), False
    return 50, False


def _default_names(backend) -> tuple[str, str]:
    default_sink = "unavailable"
    default_source = "unavailable"
    tool = backend.tools.get("pactl")
    if tool:
        result = backend._run([tool, "info"], capture=True, timeout=10)
        if result is not None and result.returncode == 0:
            for line in result.stdout.splitlines():
                if line.startswith("Default Sink:"):
                    default_sink = line.split(":", 1)[1].strip()
                elif line.startswith("Default Source:"):
                    default_source = line.split(":", 1)[1].strip()
    return default_sink, default_source


def _streams(backend) -> list[str]:
    tool = backend.tools.get("pactl")
    if not tool:
        return []
    result = backend._run([tool, "list", "short", "sink-inputs"], capture=True, timeout=15)
    if result is None or result.returncode != 0:
        return []
    rows = []
    for line in result.stdout.splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            rows.append(" ".join(part for part in parts[:3] if part).strip())
    return rows


def read_current(backend) -> dict[str, Any]:
    default_sink, default_source = _default_names(backend)
    output_volume, output_muted = _parse_wpctl_volume(backend, "@DEFAULT_AUDIO_SINK@")
    input_volume, input_muted = _parse_wpctl_volume(backend, "@DEFAULT_AUDIO_SOURCE@")
    return {
        "status": _status(backend),
        "default_sink": default_sink,
        "default_source": default_source,
        "output_devices": _parse_pactl_short(backend, "sinks"),
        "input_devices": _parse_pactl_short(backend, "sources"),
        "active_streams": _streams(backend),
        "output_volume": output_volume,
        "output_muted": output_muted,
        "input_volume": input_volume,
        "input_muted": input_muted,
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    details: list[str] = []
    warnings: list[str] = []

    selected_output = str(values.get("output_device", "")).strip()
    selected_input = str(values.get("input_device", "")).strip()
    pactl = backend.tools.get("pactl")
    wpctl = backend.tools.get("wpctl")

    if selected_output:
        if pactl:
            result = backend._run([pactl, "set-default-sink", selected_output], capture=True, timeout=15)
            if result is not None and result.returncode == 0:
                details.append(f"Default output device set to {selected_output}.")
            else:
                warnings.append(f"Could not switch the default output device to {selected_output}.")
        elif wpctl:
            warnings.append("Switching the default output device requires pactl in this build.")
    if selected_input:
        if pactl:
            result = backend._run([pactl, "set-default-source", selected_input], capture=True, timeout=15)
            if result is not None and result.returncode == 0:
                details.append(f"Default input device set to {selected_input}.")
            else:
                warnings.append(f"Could not switch the default input device to {selected_input}.")
        elif wpctl:
            warnings.append("Switching the default input device requires pactl in this build.")

    if wpctl:
        backend._run([wpctl, "set-volume", "@DEFAULT_AUDIO_SINK@", f"{int(values.get('output_volume', 50))}%"], capture=True, timeout=10)
        backend._run([wpctl, "set-mute", "@DEFAULT_AUDIO_SINK@", "1" if values.get("output_muted") else "0"], capture=True, timeout=10)
        backend._run([wpctl, "set-volume", "@DEFAULT_AUDIO_SOURCE@", f"{int(values.get('input_volume', 50))}%"], capture=True, timeout=10)
        backend._run([wpctl, "set-mute", "@DEFAULT_AUDIO_SOURCE@", "1" if values.get("input_muted") else "0"], capture=True, timeout=10)
        details.append("Updated default sink and source volume through wpctl.")
    elif pactl:
        backend._run([pactl, "set-sink-volume", "@DEFAULT_SINK@", f"{int(values.get('output_volume', 50))}%"], capture=True, timeout=10)
        backend._run([pactl, "set-sink-mute", "@DEFAULT_SINK@", "1" if values.get("output_muted") else "0"], capture=True, timeout=10)
        backend._run([pactl, "set-source-volume", "@DEFAULT_SOURCE@", f"{int(values.get('input_volume', 50))}%"], capture=True, timeout=10)
        backend._run([pactl, "set-source-mute", "@DEFAULT_SOURCE@", "1" if values.get("input_muted") else "0"], capture=True, timeout=10)
        details.append("Updated default sink and source volume through pactl.")
    else:
        warnings.append("No audio control backend is installed.")

    return result_payload(True, "Audio settings updated.", details=details, warnings=warnings)


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_pulseaudio")
