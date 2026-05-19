from __future__ import annotations

from typing import Any

from .common import connected, limited, result_payload


PROXY_MODE_TO_VALUE = {"none": "0", "manual": "1", "automatic": "2"}
PROXY_VALUE_TO_MODE = {value: key for key, value in PROXY_MODE_TO_VALUE.items()}


def is_available(_backend) -> bool:
    return True


def _kioslaverc(backend):
    return backend.settings_file("kioslaverc")


def read_current(backend) -> dict[str, Any]:
    path = _kioslaverc(backend)
    mode_value = backend.kread(path, ("Proxy Settings",), "ProxyType", "0")
    status = connected("KDE proxy preferences can be written directly to kioslaverc.", advanced_module="proxy")
    if not (backend.tools.get("kwriteconfig6") or backend.tools.get("kreadconfig6")):
        status = limited(
            "Proxy preferences can still be stored through a plain INI fallback.",
            details=["Open the KDE proxy module if a specific app ignores the saved KDE proxy settings."],
            missing_tools=["kwriteconfig6", "kreadconfig6"],
            advanced_module="proxy",
        )
    return {
        "status": status,
        "mode": PROXY_VALUE_TO_MODE.get(mode_value, "none"),
        "http_proxy": backend.kread(path, ("Proxy Settings",), "httpProxy", ""),
        "https_proxy": backend.kread(path, ("Proxy Settings",), "httpsProxy", ""),
        "socks_proxy": backend.kread(path, ("Proxy Settings",), "socksProxy", ""),
        "no_proxy": backend.kread(path, ("Proxy Settings",), "NoProxyFor", ""),
        "pac_url": backend.kread(path, ("Proxy Settings",), "Proxy Config Script", ""),
    }


def apply_changes(backend, values: dict[str, Any]) -> dict[str, Any]:
    path = _kioslaverc(backend)
    mode = str(values.get("mode", "none"))
    backend.kwrite(path, ("Proxy Settings",), "ProxyType", PROXY_MODE_TO_VALUE.get(mode, "0"))
    backend.kwrite(path, ("Proxy Settings",), "httpProxy", str(values.get("http_proxy", "")).strip())
    backend.kwrite(path, ("Proxy Settings",), "httpsProxy", str(values.get("https_proxy", "")).strip())
    backend.kwrite(path, ("Proxy Settings",), "socksProxy", str(values.get("socks_proxy", "")).strip())
    backend.kwrite(path, ("Proxy Settings",), "NoProxyFor", str(values.get("no_proxy", "")).strip())
    backend.kwrite(path, ("Proxy Settings",), "Proxy Config Script", str(values.get("pac_url", "")).strip())
    return result_payload(
        True,
        "Proxy settings updated.",
        details=["Stored KDE proxy preferences in kioslaverc."],
        requires=["Some applications only reload proxy settings when restarted."],
    )


def open_advanced_settings(backend):
    return backend.open_kcm("proxy")
