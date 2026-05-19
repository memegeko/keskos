from __future__ import annotations

from pathlib import Path
from typing import Any

from .common import connected, limited, missing, result_payload


def is_available(backend) -> bool:
    return bool(backend.tools.get("nmcli"))


def _connections(backend) -> list[dict[str, Any]]:
    tool = backend.tools.get("nmcli")
    if not tool:
        return []
    result = backend._run([tool, "-t", "-f", "NAME,TYPE,AUTOCONNECT,ACTIVE", "connection", "show"], capture=True, timeout=20)
    if result is None or result.returncode != 0:
        return []
    rows: list[dict[str, Any]] = []
    for line in result.stdout.splitlines():
        parts = line.split(":")
        if len(parts) < 4:
            continue
        name, kind, autoconnect, active = parts[0], parts[1], parts[2], parts[3]
        if kind not in {"vpn", "wireguard"} and "vpn" not in kind.lower():
            continue
        rows.append(
            {
                "name": name,
                "type": kind,
                "autoconnect": autoconnect.lower() == "yes",
                "active": active.lower() == "yes",
            }
        )
    return rows


def _status(backend):
    if not backend.tools.get("nmcli"):
        return missing("NetworkManager CLI tools are not installed.", missing_tools=["nmcli"], advanced_module="kcm_networkmanagement")
    return connected("VPN connections are managed through NetworkManager.", advanced_module="kcm_networkmanagement")


def read_current(backend) -> dict[str, Any]:
    return {
        "status": _status(backend),
        "connections": _connections(backend),
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    tool = backend.tools.get("nmcli")
    if not tool:
        return result_payload(False, "nmcli is not available.")

    details: list[str] = []
    warnings: list[str] = []
    connect_name = str(values.get("connect", "")).strip()
    disconnect_name = str(values.get("disconnect", "")).strip()
    autoconnect_map = values.get("autoconnect", {}) or {}
    if connect_name:
        result = backend._run([tool, "connection", "up", connect_name], capture=True, timeout=60)
        if result is not None and result.returncode == 0:
            details.append(f"Connected VPN: {connect_name}")
        else:
            warnings.append(f"Could not connect VPN: {connect_name}")
    if disconnect_name:
        result = backend._run([tool, "connection", "down", disconnect_name], capture=True, timeout=30)
        if result is not None and result.returncode == 0:
            details.append(f"Disconnected VPN: {disconnect_name}")
        else:
            warnings.append(f"Could not disconnect VPN: {disconnect_name}")
    for name, enabled in autoconnect_map.items():
        result = backend._run([tool, "connection", "modify", str(name), "connection.autoconnect", "yes" if enabled else "no"], capture=True, timeout=20)
        if result is not None and result.returncode == 0:
            details.append(f"VPN autoconnect {'enabled' if enabled else 'disabled'} for {name}")
        else:
            warnings.append(f"Could not update VPN autoconnect for {name}")
    summary = "VPN settings updated." if details or not warnings else "VPN changes could not be applied."
    return result_payload(not warnings, summary, details=details, warnings=warnings)


def import_config(backend, file_path: str) -> dict[str, Any]:
    tool = backend.tools.get("nmcli")
    config_path = Path(file_path).expanduser()
    if not tool:
        return result_payload(False, "nmcli is not available.")
    if not config_path.is_file():
        return result_payload(False, "The selected VPN configuration file was not found.")
    result = backend._run([tool, "connection", "import", "type", "openvpn", "file", str(config_path)], capture=True, timeout=90)
    success = result is not None and result.returncode == 0
    return result_payload(success, "VPN configuration imported." if success else "VPN import failed.")


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_networkmanagement")
