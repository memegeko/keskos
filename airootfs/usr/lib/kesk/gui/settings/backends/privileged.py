from __future__ import annotations

from pathlib import Path
from typing import Any

from .common import connected, missing, requires_admin, result_payload


INSTALLED_POLICY_PATH = Path("/usr/share/polkit-1/actions/org.keskos.settings.policy")


def helper_path(backend) -> Path:
    staged = backend.paths.usr_root / "lib" / "kesk" / "kesk-settings-helper"
    if staged.is_file():
        return staged
    return Path("/usr/lib/kesk/kesk-settings-helper")


def policy_path(backend) -> Path:
    staged = backend.paths.usr_root / "share" / "polkit-1" / "actions" / "org.keskos.settings.policy"
    if staged.is_file():
        return staged
    return INSTALLED_POLICY_PATH


def is_available(backend) -> bool:
    return bool(backend.tools.get("pkexec")) and helper_path(backend).is_file()


def read_current(backend) -> dict[str, Any]:
    helper = helper_path(backend)
    if not helper.is_file():
        return {
            "status": missing("The privileged settings helper is not installed.", missing_tools=[str(helper)]),
            "helper": str(helper),
            "policy_present": policy_path(backend).is_file(),
        }
    if not backend.tools.get("pkexec"):
        return {
            "status": missing("pkexec is not installed.", missing_tools=["pkexec"]),
            "helper": str(helper),
            "policy_present": policy_path(backend).is_file(),
        }
    return {
        "status": requires_admin(
            "Privileged boot and login actions are available through pkexec.",
            details=["SDDM, Plymouth, quiet-boot, and initramfs changes are isolated behind the Kesk Settings helper."],
        ),
        "helper": str(helper),
        "policy_present": policy_path(backend).is_file(),
    }


def run_action(backend, action: str, *args: str, timeout: int = 240) -> dict[str, Any]:
    helper = helper_path(backend)
    if not backend.tools.get("pkexec"):
        return result_payload(False, "pkexec is not installed.")
    if not helper.is_file():
        return result_payload(False, "The privileged settings helper is not installed.")
    result = backend._run([backend.tools["pkexec"], str(helper), action, *args], capture=True, timeout=timeout)
    success = result is not None and result.returncode == 0
    summary = f"Privileged action `{action}` completed." if success else f"Privileged action `{action}` failed."
    warnings = [] if success else [f"`pkexec {helper} {action}` did not complete successfully."]
    return result_payload(success, summary, warnings=warnings)


def open_advanced_settings(backend):
    return backend.open_kcm("kcm_sddm")
